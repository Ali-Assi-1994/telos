import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telos/src/features/tasks/domain/category.dart';
import 'package:telos/src/features/tasks/presentation/task_create_controller.dart';
import 'package:telos/src/features/tasks/presentation/widgets/duration_picker.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_sheet_fields.dart';
import 'package:telos/src/features/tasks/presentation/widgets/task_time_format.dart';

/// Bottom sheet form for creating a new task on a given date.
class CreateTaskSheet extends ConsumerStatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.initialDate,
    required this.initialTime,
    required this.categories,
    required this.onCreate,
  });

  final DateTime initialDate;
  final TimeOfDay? initialTime;
  final List<Category> categories;
  final Future<void> Function({
    required String title,
    required String? description,
    required int points,
    required DateTime assignedDate,
    required TimeOfDay startTime,
    required List<int> categoryIds,
  }) onCreate;

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final Set<int> _selectedCategoryIds = <int>{};
  late DateTime _assignedDate;
  late TimeOfDay _startTime;
  int _points = 40;
  int _selectedDurationMinutes = 60;
  bool _isCustomDurationSelected = false;

  @override
  void initState() {
    super.initState();
    _assignedDate = widget.initialDate;
    _startTime = widget.initialTime ?? TimeOfDay.now();
    _applyRandomAiSuggestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = ref.watch(taskCreateControllerProvider).isLoading;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SheetHandle(),
                const SizedBox(height: 16),
                SheetHeader(
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                TaskTitleField(
                  controller: _titleController,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),
                MetaActionsRow(
                  startTimeLabel: formatTimeOfDay(_startTime),
                  onPickTime: isLoading ? null : _pickTime,
                ),
                const SizedBox(height: 14),
                const SectionTitle(
                  icon: Icons.hourglass_bottom_rounded,
                  title: 'Time needed',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: durationOptions.map((DurationOption option) {
                    final bool isSelected = option.isCustom
                        ? _isCustomDurationSelected
                        : !_isCustomDurationSelected &&
                            option.minutes == _selectedDurationMinutes;
                    return InfoTag(
                      icon: option.isCustom ? Icons.tune_rounded : null,
                      text: option.isCustom
                          ? _customDurationChipLabel()
                          : option.label,
                      highlighted: isSelected,
                      onPressed:
                          isLoading ? null : () => _onDurationSelected(option),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                SectionTitle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI suggestions',
                  iconColor: colorScheme.tertiary,
                ),
                const SizedBox(height: 10),
                AiSuggestionsRow(
                  selectedCategoryName: _selectedCategoryName(),
                  points: _points,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isLoading ? 'Saving...' : 'Save Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDurationSelected(DurationOption option) async {
    if (option.isCustom) {
      final CustomDurationResult? result =
          await showDialog<CustomDurationResult>(
        context: context,
        builder: (BuildContext context) => CustomDurationPickerDialog(
          initialDurationMinutes: _selectedDurationMinutes,
        ),
      );
      if (result == null) return;
      setState(() {
        _isCustomDurationSelected = true;
        _selectedDurationMinutes = result.totalMinutes;
      });
      return;
    }

    final int minutes = option.minutes ?? 60;
    setState(() {
      _selectedDurationMinutes = minutes;
      _isCustomDurationSelected = false;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) return;

    await widget.onCreate(
      title: _titleController.text.trim(),
      description:
          'Estimated duration: ${formatDurationLabel(_selectedDurationMinutes)}',
      points: _points,
      assignedDate: _assignedDate,
      startTime: _startTime,
      categoryIds: _selectedCategoryIds.toList(growable: false),
    );
  }

  void _applyRandomAiSuggestions() {
    if (widget.categories.isEmpty) return;
    final Random random = Random();
    final Category category =
        widget.categories[random.nextInt(widget.categories.length)];
    _points = 10 + random.nextInt(91);
    _selectedCategoryIds
      ..clear()
      ..add(category.id);
  }

  String _selectedCategoryName() {
    if (_selectedCategoryIds.isEmpty) return 'General';
    final int selectedId = _selectedCategoryIds.first;
    for (final Category category in widget.categories) {
      if (category.id == selectedId) return category.name;
    }
    return 'General';
  }

  String _customDurationChipLabel() {
    if (!_isCustomDurationSelected) return 'Custom';
    return formatDurationLabel(_selectedDurationMinutes);
  }
}
