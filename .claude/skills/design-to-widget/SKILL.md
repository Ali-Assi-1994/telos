---
name: design-to-widget
description: Convert a UI design into a reusable Flutter widget. Use when implementing a component, card, badge, chip, or any self-contained UI element from a design.
---

# Design to Widget

## What This Skill Does
Translates a UI design into a clean, reusable Flutter widget. Focused on
the component level — not screens. Covers parameter design, theming,
sizing, and placement in the correct `widgets/` folder.

## Step 1 — Classify the Widget Before Writing

Answer these before writing any code:

1. Is this widget purely presentational (receives data via params)?
   → Use `StatelessWidget`
2. Does it need local UI state (expanded, hovered, focused)?
   → Use `StatefulWidget`
3. Does it need to read from Riverpod providers?
   → Use `ConsumerWidget`
4. Which feature does it belong to? Or is it truly shared across features?
   → Feature-specific: `features/<feature>/presentation/widgets/`
   → Shared: `common_widgets/`

## Step 2 — Design the Public API First

Before writing the widget body, define what parameters it accepts.
Prefer fewer, well-named parameters over a flat list of styling options.

```dart
// Good — data-driven, caller controls content
TaskCard({
  required Task task,
  required VoidCallback onComplete,
  VoidCallback? onTap,
})

// Bad — too many presentational params leaking implementation
TaskCard({
  required String title,
  required int points,
  required Color color,
  required bool showCheckbox,
  required double borderRadius,
})
```

## Widget Templates

### Presentational Widget (most common)
```dart
// features/<feature>/presentation/widgets/<widget_name>.dart
import 'package:flutter/material.dart';
import '../../domain/<model>.dart';

class <WidgetName> extends StatelessWidget {
  const <WidgetName>({
    super.key,
    required this.<primaryData>,
    this.onTap,
  });

  final <Type> <primaryData>;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _<WidgetName>Content(
          data: <primaryData>,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

class _<WidgetName>Content extends StatelessWidget {
  const _<WidgetName>Content({
    required this.data,
    required this.textTheme,
    required this.colorScheme,
  });

  final <Type> data;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(data.subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
        _<TrailingWidget>(data: data, colorScheme: colorScheme),
      ],
    );
  }
}
```

### Widget with Local State (toggle, expansion)
```dart
class <WidgetName> extends StatefulWidget {
  const <WidgetName>({super.key, required this.<data>});
  final <Type> <data>;

  @override
  State<<WidgetName>> createState() => _<WidgetName>State();
}

class _<WidgetName>State extends State<<WidgetName>> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedCrossFade(
        firstChild: _CollapsedView(data: widget.<data>),
        secondChild: _ExpandedView(data: widget.<data>),
        crossFadeState: _isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
```

### Provider-Connected Widget
```dart
class <WidgetName> extends ConsumerWidget {
  const <WidgetName>({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select() to limit rebuilds to only the field needed
    final value = ref.watch(
      someProvider.select((v) => v.valueOrNull?.relevantField),
    );

    return _<WidgetName>View(value: value);
  }
}
```

## Common Component Patterns

### Points Badge
```dart
class PointsBadge extends StatelessWidget {
  const PointsBadge({super.key, required this.points});
  final int points;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$points pts',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onTertiaryContainer,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

### Category Chip
```dart
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(category.name),
    selected: isSelected,
    onSelected: onTap != null ? (_) => onTap!() : null,
    avatar: Icon(
      category.flutterIcon,
      size: 16,
      color: category.flutterColor,
    ),
  );
}
```

### Completion Progress Bar
```dart
class DailyProgressBar extends StatelessWidget {
  const DailyProgressBar({super.key, required this.rate});
  final double rate; // 0.0 – 1.0

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Today',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '${(rate * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: rate,
          minHeight: 8,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ],
  );
}
```

## Rules
- Always define the public API (constructor parameters) before writing the body.
- Always use `Theme.of(context)` — never hardcode colors or text styles.
- Always use `const` constructors when widget has no dynamic data.
- Break widgets over 40 lines into named private sub-widgets.
- Prefer data parameters over styling parameters in the public API.
- Feature-specific widgets go in `features/<feature>/presentation/widgets/`.
- Widgets used across 2+ features go in `common_widgets/`.
- Never put provider reads in a `StatelessWidget` — use `ConsumerWidget`.
- Never put controller calls in a widget — accept callbacks instead.
