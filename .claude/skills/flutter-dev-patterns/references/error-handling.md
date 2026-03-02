# Error Handling and Async Flow Patterns

## The Two-Layer Error Strategy

Errors are handled at two distinct layers with different responsibilities:

```
Provider layer: catch HTTP/network exceptions -> return status-wrapped model
Controller layer: check response.status -> show user feedback via SnackBar
```

Never let exceptions propagate from Provider to Controller as thrown exceptions (except for genuinely unexpected errors).

## Provider Error Handling

The Provider is the only place that touches the network. It must:
1. Wrap all calls in try/catch
2. Handle specific HTTP status codes explicitly
3. Return a status-wrapped model on both success and failure
4. Never rethrow to the controller (unless truly unrecoverable)

```dart
@override
Future<LoginModel> getUser(Map<String, dynamic> body) async {
  try {
    final response = await _http.post(Endpoints.login, data: body);
    return LoginModel.fromJson(response.data);
  } catch (e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      // Handle known business-level HTTP errors
      if ([400, 404, 503].contains(statusCode)) {
        final message = e.response?.data['detail'] ?? e.message;
        return LoginModel(status: false, detail: message);
      }
    }
    // Unexpected error - return generic failure
    return LoginModel(status: false, detail: 'Unexpected error occurred');
  }
}
```

## Controller Error Handling

Controllers check `response.status` and provide user feedback. Use `finally` to always clear loading state:

```dart
Future<void> login() async {
  loading.value = true;
  clearLoginErrorMessages();

  if (!await formValidator()) {
    loading.value = false;
    return;
  }

  try {
    final response = await signInRepository.getUser({
      'email': emailController.text,
      'password': passwordController.text,
    });

    if (response.status == true) {
      AuthService.to.loggedIn(response.token!);
      SnackBarApp.body('Sucesso', 'Login realizado com sucesso!');
      Get.offAllNamed(Routes.home);
    } else {
      SnackBarApp.body(
        'Ops!',
        response.detail ?? 'Nao foi possivel realizar o login.',
        icon: FontAwesomeIcons.xmark,
      );
    }
  } catch (e) {
    // Only unexpected errors reach here (programming errors)
    SnackBarApp.body('Ops!', 'Nao foi possivel realizar o login.',
      icon: FontAwesomeIcons.xmark);
    throw Exception(e.runtimeType);
  } finally {
    loading.value = false;  // ALWAYS clear loading
  }
}
```

## Retry Pattern

For critical data loading, implement retry with delay:

```dart
Future<void> _fetchData() async {
  setLoading = true;
  const int maxRetries = 3;
  int retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      final response = await repository.getCountBeds();

      if (response.status == true) {
        setCountBed = response;
        setLoading = false;
        return;
      }
      throw Exception('Invalid response from server');

    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        setLoading = false;
        SnackBarApp.body('Ops', 'Nao foi possivel carregar os leitos.');
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
```

## Form Validation Pattern

Validation methods clear previous errors, validate each field, set error messages reactively, and return bool:

```dart
Future<bool> formValidator() async {
  clearLoginErrorMessages();
  bool isValid = true;

  final email = emailController.text.trim();
  if (email.isEmpty) {
    emailError.value = 'Email is required';
    isValid = false;
  } else if (!email.contains('@')) {
    emailError.value = 'Invalid email format';
    isValid = false;
  }

  final password = passwordController.text;
  if (password.isEmpty) {
    passwordError.value = 'Password is required';
    isValid = false;
  } else if (password.length < 6) {
    passwordError.value = 'Password must be at least 6 characters';
    isValid = false;
  }

  return isValid;
}

void clearLoginErrorMessages() {
  emailError.value = '';
  passwordError.value = '';
}
```

The View displays validation errors via the reactive error fields:

```dart
Obx(() => TextFormField(
  controller: controller.emailController,
  decoration: InputDecoration(
    labelText: 'Email',
    errorText: controller.emailError.value.isNotEmpty
      ? controller.emailError.value
      : null,
  ),
))
```

## Async Initialization Pattern

For one-time async setup in controllers, use `onReady()` (fires after first frame):

```dart
@override
Future<void> onReady() async {
  setLoading = true;
  super.onReady();

  // Sequential: notifications first, then main data
  await fetchDataNotification();
  await _fetchData();

  setLoading = false;
}
```

## User Feedback Strategy

| Scenario | Feedback Method |
|----------|----------------|
| Success operation | `SnackBarApp.body('Sucesso', 'message')` |
| API/server error | `SnackBarApp.body('Ops!', response.detail ?? 'fallback', icon: xmark)` |
| Network failure | `SnackBarApp.body('Ops!', 'Nao foi possivel...', icon: xmark)` |
| Form validation error | Set reactive error field (shows inline in form) |
| Critical data failure | SnackBar after all retries exhausted |

Never use `showDialog` for errors - use SnackBar for all transient feedback. Reserve dialogs for user decisions (e.g., status selection, confirmation).

## HTTP Interceptors

Auth token injection happens in the HTTP client interceptor, not in individual providers:

```dart
// In http_client.dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await StorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      AuthService.to.logout();
    }
    handler.next(error);
  },
));
```
