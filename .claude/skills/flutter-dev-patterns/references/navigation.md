# Navigation and Routes

## Route Organization

Routes are split into two files:

### `core/routes/routes.dart` - Route Constants

```dart
abstract class Routes {
  Routes._();

  // App-level routes
  static const initial = '/';
  static const home = '/home';
  static const signIn = '/signin';
  static const profile = '/profile';
  static const notFound = '/404';

  // Feature routes (flat, not nested paths)
  static const notification = '/notification';
  static const bedsList = '/beds-list';
  static const patientSelection = '/patient-selection';
  static const report = '/report';
}
```

### `core/routes/pages/pages.dart` - Route Definitions

```dart
class Pages {
  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: Routes.initial,
      page: () => const RootView(),
      bindings: [RootBinding()],
      participatesInRootNavigator: true,
      preventDuplicates: true,
      title: 'Root',
      middlewares: [
        AuthMiddleware(),
        ForceNavigateToRouteMiddleware(from: '/', to: Routes.home),
      ],
    ),
    GetPage(
      name: Routes.signIn,
      page: () => const SignInPage(),
      binding: SignInBinding(),
      title: 'Login',
      middlewares: [NotAuthMiddleware()],
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      title: 'Home',
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.notFound,
      page: () => const NotFoundPage(),
      title: '404',
    ),

    // Module-level routes merged in
    ...HomePages.routes,
    ...ProfilePages.routes,
  ];
}
```

## Module-Level Routes

Each module defines its own routes in a separate class:

```dart
// modules/home/core/routes/home_pages.dart
class HomePages {
  static List<GetPage<dynamic>> routes = [
    GetPage(
      name: Routes.bedsList,
      page: () => const BedsListPage(),
      binding: BedsBinding(),
      title: 'Beds',
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.patientSelection,
      page: () => const PatientSelectionPage(),
      binding: PatientSelectionBinding(),
      title: 'Patient Selection',
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.report,
      page: () => const ReportPage(),
      binding: ReportBinding(),
      title: 'Reports',
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
  ];
}
```

## Navigation Patterns

### Standard push navigation
```dart
Get.toNamed(Routes.report);
```

### Replace current route (back button goes further back)
```dart
Get.offNamed(Routes.home);
```

### Clear entire stack and navigate (used after login/logout)
```dart
Get.offAllNamed(Routes.home);    // After login
Get.offAllNamed(Routes.signIn);  // After logout
```

### Navigation with page transition
```dart
// Defined in GetPage config, called the same way
GetPage(
  name: Routes.profile,
  transition: Transition.rightToLeft,
  ...
)
Get.toNamed(Routes.profile);
```

## Route Guards (Middleware)

Three standard middleware types in this codebase:

### AuthMiddleware - Requires authenticated user
```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AuthService.to.getUser.isLoggedIn!) {
      return const RouteSettings(name: Routes.signIn);
    }
    return null;  // null = allow navigation
  }
}
```

### NotAuthMiddleware - Requires unauthenticated user
```dart
class NotAuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (AuthService.to.getUser.isLoggedIn!) {
      return const RouteSettings(name: Routes.home);
    }
    return null;
  }
}
```

### ForceNavigateToRouteMiddleware - Redirect from one route to another
```dart
class ForceNavigateToRouteMiddleware extends GetMiddleware {
  final String from;
  final String to;

  ForceNavigateToRouteMiddleware({required this.from, required this.to});

  @override
  RouteSettings? redirect(String? route) {
    if (route == from) return RouteSettings(name: to);
    return const RouteSettings(name: Routes.notFound);
  }
}
```

## App Initialization

Routes and initial bindings configured at app startup:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Hospital Management',
      theme: themeData,
      initialRoute: Routes.initial,
      getPages: Pages.routes,
      unknownRoute: GetPage(
        name: Routes.notFound,
        page: () => const NotFoundPage(),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthService());    // Singleton services at startup
        Get.put(SplashService());
      }),
    );
  }
}
```

## Route Naming Rules

- Use kebab-case paths: `/beds-list`, `/patient-selection`
- Keep paths flat (not nested): `/beds-list` not `/home/beds-list`
- Routes constants use camelCase names: `bedsList`, `patientSelection`
- All feature routes have `middlewares: [AuthMiddleware()]` unless explicitly public
