# Architecture Reference

## Module Structure Template

Every feature follows this exact structure:

```
modules/
  [feature]/
    page.dart
    controller.dart
    binding.dart
    repository.dart          # optional if feature has no data layer
    core/
      model/
        [entity]_model.dart
        [list_entity]_model.dart
      network/
        http_client.dart
        endpoints.dart
      provider/
        [feature].dart
      widget/
        [reusable_widget].dart
```

### When to create `core/` inside a module

Create `core/` when the feature has:
- Its own API endpoints (different base URL or auth strategy)
- Feature-specific models not shared with other modules
- Reusable widgets used only within that feature

For simple features that reuse global models/network, skip `core/` and put models directly under the feature folder.

## Layer Responsibilities

### View (`page.dart`)

- Extends the framework's view base class with a typed controller reference
- Contains ONLY widget tree construction
- Reads state from controller reactive properties
- Calls controller methods on user interactions
- Never contains if/else business logic — delegates to controller
- Never directly calls repositories or services

```dart
// CORRECT - View reads state and delegates actions
class BedsListPage extends GetView<BedsController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) return const ProgressIndicatorApp();
      return ListView.builder(
        itemCount: controller.beds.length,
        itemBuilder: (_, i) => BedCard(
          bed: controller.beds[i],
          onTap: () => controller.selectBed(controller.beds[i]),
        ),
      );
    });
  }
}

// WRONG - View containing business logic
class BedsListPage extends StatefulWidget {
  Future<void> _loadData() async {
    final result = await http.get('/beds'); // Never do this in View
  }
}
```

### Controller (`controller.dart`)

- Extends the framework's reactive controller base
- Owns all reactive/observable state for the feature
- Contains all business logic and coordination
- Calls repository methods through the injected abstraction
- Calls global services (auth, storage, navigation) directly
- Uses lifecycle hooks: `onInit()` for subscriptions/setup, `onReady()` for data fetching, `onClose()` for cleanup
- Uses `loading` flag to gate async operations
- Validates forms before making API calls
- Provides feedback via SnackBar for success and error states

```dart
class HomeController extends GetxController {
  final HomeRepository repository;

  HomeController({required this.repository});

  final RxBool loading = false.obs;
  final Rx<CountBed> countBed = CountBed().obs;
  final RxList<SectorModel> sectors = <SectorModel>[].obs;

  @override
  Future<void> onReady() async {
    loading.value = true;
    super.onReady();
    await _fetchData();
    loading.value = false;
  }

  Future<void> _fetchData() async {
    const maxRetries = 3;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await repository.getCountBeds();
        if (response.status!) {
          countBed.value = response;
          return;
        }
        throw Exception('Invalid response');
      } catch (_) {
        if (i == maxRetries - 1) {
          SnackBarApp.body('Ops', 'Could not load data.');
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }
}
```

### Repository (`repository.dart`)

- Always an abstract class (interface)
- Defines the contract between controller and data layer
- Uses domain method names, not HTTP verbs: `getCountBeds()` not `fetchCountBedsFromApi()`
- Returns domain models, never raw HTTP responses

```dart
abstract class HomeRepository {
  Future<CountBed> getCountBeds();
  Future<bool> updateBed(BedModel bed);
  Future<ListSectorModel> getSectors();
}
```

### Provider (`core/provider/[feature].dart`)

- Implements the repository abstract class
- The ONLY place that knows about HTTP, database, or external APIs
- Wraps all calls in try/catch
- Returns status-wrapped response models (never throws to controller)
- Handles HTTP error codes specifically (400, 404, 503, etc.)

```dart
class HomeProvider implements HomeRepository {
  final _http = HttpClientHome().init;

  @override
  Future<CountBed> getCountBeds() async {
    try {
      final response = await _http.get(HomeEndpoints.countBeds);
      return CountBed.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['detail'] ?? e.message;
        return CountBed(status: false, detail: msg);
      }
      return CountBed(status: false, detail: 'Unexpected error');
    }
  }
}
```

### Binding (`binding.dart`)

- Registers repository (abstract bound to concrete provider)
- Registers controller with injected repository
- Uses lazy registration: only instantiates when first accessed
- Use `fenix: true` to keep instances alive across navigation

```dart
class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRepository>(() => HomeProvider(), fenix: true);
    Get.lazyPut<HomeController>(
      () => HomeController(repository: Get.find()),
      fenix: true,
    );
  }
}
```

## Model Pattern

All response models must include status fields for consistent error handling:

```dart
class CountBed {
  final bool? status;
  final String? detail;
  final int? free;
  final int? occupied;
  final int? maintenance;

  CountBed({this.status, this.detail, this.free, this.occupied, this.maintenance});

  factory CountBed.fromJson(Map<String, dynamic> json) => CountBed(
    status: json['status'],
    detail: json['detail'],
    free: json['free'],
    occupied: json['occupied'],
    maintenance: json['maintenance'],
  );
}
```

Request models are plain Dart classes with `toJson()`:

```dart
class SignupModel {
  final String name;
  final String email;
  final String password;

  SignupModel({required this.name, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
  };
}
```

## Global Core vs Module Core

| Location | Contents |
|----------|----------|
| `app/core/global_widgets/` | Widgets used by 2+ modules |
| `app/core/services/` | Singleton app-wide services (auth, storage) |
| `app/core/routes/` | All routes + pages definitions |
| `app/core/theme/` | Global ThemeData |
| `app/core/utils/` | Global constants (colors, sizes) |
| `modules/[feat]/core/widget/` | Widgets used only within this feature |
| `modules/[feat]/core/model/` | Models for this feature only |
| `modules/[feat]/core/network/` | HTTP client for this feature (if different from global) |
| `modules/global/core/model/` | Shared models used across multiple modules |
