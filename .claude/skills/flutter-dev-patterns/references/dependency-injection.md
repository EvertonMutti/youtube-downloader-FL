# Dependency Injection Patterns

## Core Principle: Constructor Injection + Binding-based Registration

Dependencies flow through constructors. Bindings register them before the page loads. The DI container resolves them at runtime.

## Three Levels of DI

### 1. Global Singletons (app startup)

Services that must live for the entire app lifecycle. Registered in the root `MyApp` widget before routes load:

```dart
// In MyApp widget
initialBinding: BindingsBuilder(() {
  Get.put(AuthService());     // Available app-wide immediately
  Get.put(SplashService());
}),
```

Access globally via static getter pattern:
```dart
// In AuthService
static AuthService get to => Get.find();

// Usage anywhere
AuthService.to.loggedIn(token);
AuthService.to.logout();
bool isLoggedIn = AuthService.to.getUser.isLoggedIn!;
```

### 2. Route-scoped Dependencies (Bindings)

Dependencies tied to a specific route. Registered when route loads, disposed when user leaves:

```dart
// Every route has exactly one binding class
GetPage(
  name: Routes.signIn,
  page: () => const SignInPage(),
  binding: SignInBinding(),    // <-- One binding per route
)

// The binding class
class SignInBinding implements Bindings {
  @override
  void dependencies() {
    // Register abstract -> concrete (enables mocking in tests)
    Get.lazyPut<SignInRepository>(
      () => SignInProvider(),
      fenix: true,   // Keep alive even if temporarily unreferenced
    );

    // Controller gets repository via Get.find()
    Get.lazyPut<SignInController>(
      () => SignInController(signInRepository: Get.find()),
      fenix: true,
    );
  }
}
```

**Order matters**: Register dependencies before the things that depend on them (Repository before Controller).

### 3. Multiple Bindings for a Route

When a route needs multiple bindings (e.g., root page that initializes many services):

```dart
GetPage(
  name: Routes.initial,
  bindings: [RootBinding(), AnotherBinding()],  // Multiple bindings
)
```

## Registration Strategies

| Method | When to Use | Behavior |
|--------|-------------|----------|
| `Get.put(instance)` | Global singletons, services | Immediate, persistent |
| `Get.lazyPut(() => Factory, fenix: true)` | Route-scoped controllers/repos | Lazy, kept alive |
| `Get.lazyPut(() => Factory)` | Route-scoped, dispose on leave | Lazy, disposed on navigation |
| `Get.find<T>()` | Accessing registered dependency | Throws if not registered |

## Constructor Injection Pattern

Controllers receive dependencies through constructor parameters with `required` keyword:

```dart
class SignInController extends GetxController {
  // Dependency declared as final field
  final SignInRepository signInRepository;

  // Required in constructor - enforces injection
  SignInController({required this.signInRepository});

  Future<void> login() async {
    // Uses injected repository, never instantiates directly
    final response = await signInRepository.getUser(body);
  }
}
```

```dart
class HomeController extends GetxController {
  final HomeRepository repository;

  HomeController({required this.repository});
}
```

**Never** instantiate repositories directly in controllers:
```dart
// WRONG
class HomeController extends GetxController {
  final repo = HomeProvider();  // Coupled to concrete, untestable
}

// CORRECT
class HomeController extends GetxController {
  final HomeRepository repo;
  HomeController({required this.repo});
}
```

## Repository Abstraction (Interface Segregation)

Every feature that has a data layer defines an abstract repository:

```dart
// repository.dart - Abstract contract
abstract class SignInRepository {
  Future<LoginModel> getUser(Map<String, dynamic> body);
  Future<HospitalList> getHospital();
  Future<SignupResponseModel> registerUser(SignupModel body);
}

// core/provider/sign_in.dart - Concrete implementation
class SignInProvider implements SignInRepository {
  final _http = HttpAuthClient().init;

  @override
  Future<LoginModel> getUser(Map<String, dynamic> body) async {
    // ... HTTP implementation
  }
}
```

The binding registers `SignInProvider` as `SignInRepository`:
```dart
Get.lazyPut<SignInRepository>(() => SignInProvider(), fenix: true);
```

This means:
- Controllers depend on the abstract type
- Tests can inject mock implementations
- Swapping HTTP client or data source doesn't touch controllers

## Service Access Pattern

App-wide services (auth, storage) use a static `to` getter for convenient access:

```dart
class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<AuthUserModel> _user = AuthUserModel().obs;

  AuthUserModel get getUser => _user.value;

  void loggedIn(String token) {
    // decode token, update user state, persist token
  }

  void logout() {
    _user.value = AuthUserModel(isLoggedIn: false);
    Get.offAllNamed(Routes.signIn);
  }
}
```

Usage across the app:
```dart
// In any controller or middleware
AuthService.to.loggedIn(token);
AuthService.to.logout();
bool loggedIn = AuthService.to.getUser.isLoggedIn!;
```

## HTTP Client DI

HTTP clients are not injected through the container — they are instantiated directly in providers, since each provider may need a different client configuration (auth headers, base URL):

```dart
class HomeProvider implements HomeRepository {
  // Direct instantiation - HTTP client is not "business logic"
  final _http = HttpClientHome().init;

  @override
  Future<CountBed> getCountBeds() async {
    final response = await _http.get(HomeEndpoints.countBeds);
    // ...
  }
}
```

Different modules can use different HTTP client configurations:
- `HttpAuthClient` - for authentication endpoints (no auth token)
- `HttpClientHome` - for home module endpoints (with auth interceptor)
- `HttpClientGlobal` - for shared endpoints
