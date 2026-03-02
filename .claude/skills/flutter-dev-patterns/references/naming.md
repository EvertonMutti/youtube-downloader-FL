# Naming Conventions

## File Naming

Always use `snake_case` for files. Use role-based names for structural files:

| Role | File Name | Example |
|------|-----------|---------|
| View/Screen | `page.dart` | `sign_in/page.dart` |
| ViewModel | `controller.dart` | `sign_in/controller.dart` |
| DI Binding | `binding.dart` | `sign_in/binding.dart` |
| Data Contract | `repository.dart` | `sign_in/repository.dart` |
| Data Impl | `[feature].dart` in `core/provider/` | `core/provider/sign_in.dart` |
| HTTP Client | `http_client.dart` | `core/network/http_client.dart` |
| Endpoints | `endpoints.dart` | `core/network/endpoints.dart` |
| Model | `[entity]_model.dart` | `auth_user_model.dart`, `bed_model.dart` |
| Widget | descriptive name | `indicator.dart`, `pie_chart.dart`, `status_dialog.dart` |
| Service | `[name].dart` in `services/` | `services/auth.dart`, `services/storage.dart` |

## Class Naming

Use `PascalCase`. Always include the role suffix:

| Role | Suffix | Example |
|------|--------|---------|
| View | `Page` | `SignInPage`, `HomePage`, `BedsListPage` |
| Controller | `Controller` | `SignInController`, `HomeController` |
| Abstract Repo | `Repository` | `SignInRepository`, `HomeRepository` |
| Concrete Impl | `Provider` | `SignInProvider`, `HomeProvider` |
| Binding | `Binding` | `SignInBinding`, `HomeBinding` |
| Data Model | `Model` | `AuthUserModel`, `BedModel`, `LoginModel` |
| List Response | `List[Entity]Model` | `ListSectorModel` |
| Widget | descriptive | `Indicator`, `ExpandablePieChartWidget`, `StatusDialog` |
| Service | `Service` | `AuthService`, `SplashService` |
| Middleware | `Middleware` | `AuthMiddleware`, `NotAuthMiddleware` |
| Enum | `Enum` suffix | `PositionEnum`, `PermissionEnum` |

## Variable Naming

### Reactive/Observable State

Reactive variables use camelCase without suffix. Their type makes observability clear:

```dart
// Boolean flags
final RxBool loading = false.obs;
final RxBool isExpanded = false.obs;

// Single entity
final Rx<CountBed> countBed = CountBed().obs;

// Collections
final RxList<SectorModel> sectors = <SectorModel>[].obs;
final RxList<BedModel> beds = <BedModel>[].obs;

// Primitives
final RxInt notificationCount = 0.obs;
var emailError = ''.obs;

// Typed reactive
final Rx<PositionEnum> selectedPosition = PositionEnum.NURSE.obs;
```

### Getters and Setters for Reactive State

Use explicit getters/setters to abstract the `.value` access:

```dart
// Getter: 'get' prefix + PascalCase
bool get getLoading => loading.value;
CountBed get getCountBed => countBed.value;

// Setter: 'set' prefix + PascalCase
set setLoading(bool value) => loading.value = value;
set setCountBed(CountBed value) => countBed.value = value;

// Usage in controller:
setLoading = true;  // cleaner than loading.value = true
```

### Text/Form Controllers

Name them by their purpose + `Controller`:

```dart
final emailController = TextEditingController();
final passwordController = TextEditingController();
final nameController = TextEditingController();
final phoneController = TextEditingController();
```

### Error/Validation Messages

Use the field name + `Error`:

```dart
var emailError = ''.obs;
var passwordError = ''.obs;
var nameError = ''.obs;
```

## Method Naming

| Category | Pattern | Examples |
|----------|---------|---------|
| User actions | verb + noun | `login()`, `register()`, `logout()`, `selectBed()` |
| Toggle | `toggle` + noun | `toggleSignUpForm()`, `toggleChartExpand()` |
| Data loading | `_fetchData()`, `_initFunction()` | private async methods |
| Validation | `[form]Validator()` | `formValidator()`, `signUpFormValidator()` |
| Navigation actions | verb + destination | `goToHome()`, `goToProfile()` |
| Clear state | `clear` + field | `clearLoginErrorMessages()` |
| Handle events | `handle` + event | `handlePieTouch()`, `handleNotification()` |

Private methods (internal to controller) use `_` prefix:
```dart
Future<void> _fetchData() async { ... }
Future<void> _initFunction() async { ... }
void _convertPosition() { ... }
```

## Route Constants

Define all routes as constants in an abstract class:

```dart
abstract class Routes {
  Routes._();
  static const initial = '/';
  static const home = '/home';
  static const signIn = '/signin';
  static const profile = '/profile';
  static const notFound = '/404';
  // Feature-specific
  static const bedsList = '/beds-list';
  static const patientSelection = '/patient-selection';
  static const notification = '/notification';
  static const report = '/report';
}
```

## Enum Values

Use SCREAMING_SNAKE_CASE for enum values:

```dart
enum PositionEnum { NURSE, DOCTOR, ADMIN, RECEPTIONIST }
enum PermissionEnum { READ, WRITE, ADMIN }
enum BedStatus { FREE, OCCUPIED, MAINTENANCE, CLEANING }
```
