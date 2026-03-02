# Widget Patterns

## Base Widget Choice

| Scenario | Widget Base | Why |
|----------|-------------|-----|
| Screen with controller access | `GetView<TController>` | Direct `controller` property access |
| Standalone reusable component | `StatelessWidget` | No state, just renders props |
| Complex widget needing local state | `StatefulWidget` | Animations, focus, etc. |
| Reactive wrapper inside build | `Obx(() => ...)` | Targeted rebuild on observable change |

## Page (Screen) Pattern

Pages always extend the framework's view base with controller type parameter:

```dart
class BedsListPage extends GetView<BedsController> {
  const BedsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitos')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: ProgressIndicatorApp());
        }
        return ListView.builder(
          itemCount: controller.beds.length,
          itemBuilder: (_, index) => BedCard(
            bed: controller.beds[index],
            onTap: () => controller.selectBed(controller.beds[index]),
          ),
        );
      }),
    );
  }
}
```

## Reusable Component Pattern

Stateless widgets receive all data via constructor. Use `required` for mandatory params, optional for defaults:

```dart
class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 15,
    this.textColor,
  });

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: textColor)),
      ],
    );
  }
}
```

## Animated Widget Pattern

Use `AnimatedContainer` for smooth transitions. Controller owns the size/state:

```dart
// Controller owns the expandable state
class HomeController extends GetxController {
  final RxBool isChartExpanded = false.obs;
  double get chartSize => isChartExpanded.value ? 200 : 100;

  void toggleChartExpand() => isChartExpanded.toggle();
}

// Widget uses GestureDetector + AnimatedContainer
class ExpandablePieChartWidget extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: controller.toggleChartExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: controller.chartSize,
        child: PieChart(...),
      ),
    ));
  }
}
```

## Dialog Pattern

Dialogs are functions or static methods in a widget file, not inline code:

```dart
// core/widget/status_dialog.dart
void showStatusDialog(
  BuildContext context,
  BedModel bed,
  BedsController controller,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Bed ${bed.code}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: BedStatus.values.map((status) => StatusOption(
          status: status,
          selected: bed.status == status,
          onTap: () {
            controller.updateBedStatus(bed, status);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    ),
  );
}

// Usage in page
onTap: () => showStatusDialog(context, bed, controller),
```

## Widget Composition Principles

### Prefer Composition Over Inheritance

```dart
// GOOD - compose small, focused widgets
class BedCard extends StatelessWidget {
  const BedCard({required this.bed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: BedStatusIndicator(status: bed.status),
        title: Text(bed.code),
        subtitle: Text(bed.sectorName),
        onTap: onTap,
      ),
    );
  }
}
```

### Use BoxConstraints for Max Width

Respect the app-wide max width constant for responsive layout:

```dart
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxPageWidth),
    child: Column(...),
  ),
)
```

### Loading State in Pages

Always check loading state first, then empty state, then content:

```dart
Obx(() {
  if (controller.loading.value) {
    return const Center(child: ProgressIndicatorApp());
  }
  if (controller.items.isEmpty) {
    return const Center(child: Text('No items found'));
  }
  return ListView.builder(
    itemCount: controller.items.length,
    itemBuilder: (_, i) => ItemCard(item: controller.items[i]),
  );
})
```

## Theming

Never hardcode colors or text styles. Use the theme:

```dart
// CORRECT
Text('Title', style: Theme.of(context).textTheme.headlineMedium)
Container(color: Theme.of(context).primaryColor)

// CORRECT - use centralized constants for custom values
Container(color: primaryColor)      // from core/utils/colors.dart
ConstrainedBox(constraints: BoxConstraints(maxWidth: maxPageWidth))  // from core/utils/size.dart

// WRONG
Text('Title', style: const TextStyle(fontSize: 24, color: Colors.blue))
Container(color: const Color(0xFF2196F3))
```

## Global Widget Reuse

Use global widgets from `core/global_widgets/` for cross-feature UI patterns:

```dart
// Loading indicator
const ProgressIndicatorApp()

// User feedback
SnackBarApp.body('Title', 'Message');
SnackBarApp.body('Error', 'Message', icon: FontAwesomeIcons.xmark);
```
