---
name: flutter-dev-patterns
description: >
  Flutter development skill that replicates Everton's architectural style and coding patterns.
  Use this skill whenever generating Flutter code, creating new features, modules, screens,
  widgets, controllers, models, repositories, bindings, routes, or any other Flutter-related code.
  This skill ensures all generated code follows the established MVVM architecture, module
  organization, naming conventions, component composition patterns, and error handling style
  observed in the codebase. Apply this skill for: new screens/pages, new feature modules,
  widget creation, state management, navigation, dependency injection, API integration,
  error handling, and any Flutter code generation task.
---

# Flutter Development Patterns

This skill encodes Everton's personal Flutter architectural style. All generated code must follow these patterns regardless of the specific libraries/frameworks chosen.

## Core Architecture: MVVM + Repository + Module-per-Feature

Every feature is a self-contained module with this structure:

```
modules/[feature_name]/
  page.dart          # View - UI only, no business logic
  controller.dart    # ViewModel - state + business logic
  binding.dart       # DI registration for this feature
  repository.dart    # Abstract data contract (when needed)
  core/
    model/           # Feature-specific data models
    network/         # HTTP client, endpoints (if feature has own API)
    provider/        # Concrete repository implementation
    widget/          # Feature-specific reusable widgets
```

Global/shared code lives in `core/` at the app level:
- `core/global_widgets/` - cross-module reusable widgets
- `core/services/` - singleton app-wide services
- `core/routes/` - all route definitions + pages
- `core/theme/` - centralized ThemeData
- `core/utils/` - constants (colors, sizes, etc.)

## Data Flow (always top-down, unidirectional)

```
View (page.dart)
  calls controller methods / reads reactive state
    Controller (controller.dart)
      calls injected repository abstraction
        Repository interface (repository.dart)
          implemented by Provider (core/provider/)
            uses HTTP client with interceptors
              returns response models with status/detail fields
```

## Key Principles

1. **Views never touch data layer** - only call controller methods and read controller state
2. **Controllers never know about HTTP/DB** - they use injected repository interfaces
3. **Providers are the only HTTP-aware code** - they catch exceptions and return status-wrapped models
4. **Bindings wire everything together** - one per route, registers controller + repository
5. **Models always carry `status` and `detail`** - for consistent error propagation

## Reference Files

Load these references based on what you are implementing:

| Task | Reference |
|------|-----------|
| Creating a new module/feature | [architecture.md](references/architecture.md) |
| Building widgets and UI | [widgets.md](references/widgets.md) |
| File and class naming | [naming.md](references/naming.md) |
| State management (any library) | [state-patterns.md](references/state-patterns.md) |
| Error handling and async flows | [error-handling.md](references/error-handling.md) |
| Routes and navigation | [navigation.md](references/navigation.md) |
| Dependency injection | [dependency-injection.md](references/dependency-injection.md) |

## Quick Implementation Checklist

When creating a new feature module:
- [ ] `page.dart` extends the framework's view base (e.g., GetView, ConsumerWidget, etc.)
- [ ] `controller.dart` extends the framework's controller/notifier base
- [ ] `binding.dart` registers controller and repository (abstract bound to concrete)
- [ ] `repository.dart` defines abstract interface
- [ ] `core/provider/` contains concrete implementation with try/catch
- [ ] Response models have `bool? status` and `String? detail` fields
- [ ] Controller uses `loading` state to show/hide progress indicators
- [ ] All user feedback goes through SnackBar (not dialogs for errors)
- [ ] Routes use named constants from a central Routes class
- [ ] Auth-protected routes have middleware guards
