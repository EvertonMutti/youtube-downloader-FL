# State Management Patterns

These patterns are library-agnostic. The current implementation uses GetX, but the principles apply regardless of the state management library (Riverpod, Bloc, Provider, etc.).

## Core Principle: Reactive State in Controllers

State lives in the Controller (ViewModel), not in the View. The View reacts to state changes automatically.

## State Variable Categories

### 1. Loading State

Every async operation uses a loading flag to show/hide progress UI:

```dart
// Declaration (GetX)
final RxBool loading = false.obs;
// Equivalent in Riverpod: StateNotifier with bool field
// Equivalent in Bloc: LoadingState event/state

// Usage pattern - always wrap async ops
Future<void> fetchData() async {
  loading.value = true;
  try {
    // ... async work
  } finally {
    loading.value = false;  // always clear, even on error
  }
}
```

The View uses reactive wrappers to rebuild:
```dart
// GetX style
Obx(() {
  if (controller.loading.value) return const ProgressIndicatorApp();
  return ContentWidget();
})

// Riverpod style equivalent
if (ref.watch(controllerProvider).isLoading) return ProgressIndicatorApp();
```

### 2. Entity/Collection State

Mutable domain data that the UI displays:

```dart
// Single entity
final Rx<CountBed> countBed = CountBed().obs;

// List/collection
final RxList<SectorModel> sectors = <SectorModel>[].obs;
final RxList<BedModel> beds = <BedModel>[].obs;

// Counter
final RxInt notificationCount = 0.obs;
```

### 3. Form/Input State

Form field controllers + validation error messages:

```dart
// Text input controllers (not reactive - managed by Flutter)
final emailController = TextEditingController();
final passwordController = TextEditingController();

// Validation error messages (reactive - drives UI error display)
var emailError = ''.obs;
var passwordError = ''.obs;

// Multi-step form visibility
final RxBool isSignUpFormVisible = false.obs;

// Dropdown/selection state
final Rx<PositionEnum> selectedPosition = PositionEnum.NURSE.obs;
```

### 4. UI Interaction State

Non-domain state that tracks user interactions:

```dart
// Expandable widget
final RxBool isChartExpanded = false.obs;
double get chartSize => isChartExpanded.value ? 200 : 100;

// Selected item in a list
final Rx<BedModel?> selectedBed = Rx<BedModel?>(null);

// Tab index
final RxInt selectedTab = 0.obs;
```

## One-Time Initialization Pattern

Use AsyncMemoizer (or equivalent) to prevent repeated initialization:

```dart
// Current project uses async_cache package
final memo = AsyncMemoizer<void>();

@override
void onInit() {
  memo.runOnce(_initFunction);  // Runs only once, even if onInit fires multiple times
  super.onInit();
}
```

## Getter/Setter Abstraction

Expose reactive state through getters/setters to encapsulate `.value` access:

```dart
// Reactive field (private by convention - exposed via getter)
final RxBool loading = false.obs;

// Getter - View reads this
bool get getLoading => loading.value;

// Setter - Controller sets this
set setLoading(bool value) => loading.value = value;

// Controller usage (clean, no .value noise)
setLoading = true;
await _fetchData();
setLoading = false;

// View usage
if (controller.getLoading) return ProgressIndicatorApp();
```

## State Lifecycle Hooks

Map to Controller lifecycle methods:

| Lifecycle Point | Method | Use Case |
|----------------|--------|----------|
| After controller registered | `onInit()` | Start subscriptions, init memoizer |
| After first frame renders | `onReady()` | Fetch initial data, start async work |
| Controller disposed | `onClose()` | Cancel subscriptions, dispose resources |

```dart
@override
Future<void> onInit() async {
  // Setup: subscriptions, stream listeners
  super.onInit();
}

@override
Future<void> onReady() async {
  setLoading = true;
  super.onReady();
  await _fetchData();           // Fetch after UI is ready
  await fetchNotifications();
  setLoading = false;
}

@override
Future<void> onClose() async {
  emailController.dispose();    // Dispose text controllers
  passwordController.dispose();
  super.onClose();
}
```

## UI Reactivity Pattern

Views must be wrapped in reactive builders that rebuild when state changes:

```dart
// Full page reactive
Obx(() => Visibility(
  visible: controller.isSignUpFormVisible.value,
  child: SignUpForm(),
))

// Partial reactive (only part of tree rebuilds)
Column(
  children: [
    const StaticHeader(),         // Never rebuilds
    Obx(() => Text(               // Only this rebuilds
      '${controller.notificationCount.value} notifications',
    )),
    const StaticFooter(),         // Never rebuilds
  ],
)

// Conditional rendering
Obx(() {
  if (controller.loading.value) return const ProgressIndicatorApp();
  if (controller.beds.isEmpty) return const EmptyState();
  return BedsList(beds: controller.beds);
})
```

## State Update Patterns

### Direct value update
```dart
loading.value = true;
notificationCount.value++;
```

### Collection mutations (trigger reactive updates)
```dart
notifications.add(newNotification);  // RxList automatically notifies
beds.removeWhere((b) => b.id == targetId);
sectors.clear();
sectors.addAll(fetchedSectors);
```

### Replace entire entity
```dart
countBed.value = CountBed(free: 5, occupied: 3);
```

### Conditional update
```dart
void handlePieTouch(int? index) {
  if (index == null) return;
  selectedIndex.value = index;
}
```
