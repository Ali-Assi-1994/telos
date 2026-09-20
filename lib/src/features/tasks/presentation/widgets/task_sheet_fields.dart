import 'package:flutter/material.dart';

/// Small building-block widgets shared by [CreateTaskSheet]'s form layout.

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add task',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quickly place it on today\'s plan',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            maximumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class TaskTitleField extends StatelessWidget {
  const TaskTitleField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Task title',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.secondaryContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Write monthly report',
            hintStyle: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a title';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class MetaActionsRow extends StatelessWidget {
  const MetaActionsRow({
    super.key,
    required this.startTimeLabel,
    required this.onPickTime,
  });

  final String startTimeLabel;
  final VoidCallback? onPickTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: CompactActionChip(
            icon: Icons.schedule_rounded,
            text: startTimeLabel,
            onPressed: onPickTime,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: CompactActionChip(
            icon: Icons.repeat_rounded,
            text: 'No repeat',
          ),
        ),
      ],
    );
  }
}

class CompactActionChip extends StatelessWidget {
  const CompactActionChip({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Material(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: iconColor ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          title,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class InfoTag extends StatelessWidget {
  const InfoTag({
    super.key,
    required this.text,
    required this.highlighted,
    this.icon,
    this.onPressed,
  });

  final String text;
  final bool highlighted;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final Color backgroundColor = highlighted
        ? colorScheme.tertiaryContainer
        : colorScheme.secondaryContainer;
    final Color foregroundColor = highlighted
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSecondaryContainer;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: foregroundColor),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiSuggestionsRow extends StatelessWidget {
  const AiSuggestionsRow({
    super.key,
    required this.selectedCategoryName,
    required this.points,
  });

  final String selectedCategoryName;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        InfoTag(
          icon: Icons.work_outline_rounded,
          text: selectedCategoryName,
          highlighted: true,
        ),
        InfoTag(
          icon: Icons.bolt_rounded,
          text: '$points pts',
          highlighted: true,
        ),
      ],
    );
  }
}
