import 'package:flutter/material.dart';

/// Swipeable, infinitely-paged week view used to pick the selected date.
class DateCarousel extends StatefulWidget {
  const DateCarousel({
    super.key,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<DateCarousel> createState() => _DateCarouselState();
}

class _DateCarouselState extends State<DateCarousel> {
  static const int _initialPage = 5000;
  late final PageController _pageController;
  late int _referencePage;
  late DateTime _referenceSelectedDate;

  @override
  void initState() {
    super.initState();
    _referencePage = _initialPage;
    _referenceSelectedDate = _dateOnly(widget.selectedDate);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant DateCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime oldDate = _dateOnly(oldWidget.selectedDate);
    final DateTime newDate = _dateOnly(widget.selectedDate);
    if (oldDate != newDate) {
      _referenceSelectedDate = newDate;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          final int weekDelta = page - _referencePage;
          if (weekDelta == 0) return;

          // Product expectation:
          // swipe left  => previous week
          // swipe right => next week
          final int direction = weekDelta > 0 ? -1 : 1;
          final DateTime nextSelectedDate = _dateOnly(
            _referenceSelectedDate.add(Duration(days: direction * 7)),
          );

          setState(() {
            _referencePage = page;
            _referenceSelectedDate = nextSelectedDate;
          });
          widget.onSelected(nextSelectedDate);
        },
        itemBuilder: (BuildContext context, int pageIndex) {
          final int weekOffset = pageIndex - _referencePage;
          final DateTime weekDate = _referenceSelectedDate.add(
            Duration(days: weekOffset * 7),
          );
          final DateTime monday = weekDate.subtract(
            Duration(days: weekDate.weekday - 1),
          );
          final List<DateTime> weekDates = List<DateTime>.generate(
            7,
            (int index) =>
                DateTime(monday.year, monday.month, monday.day + index),
          );

          return _WeekDateRow(
            dates: weekDates,
            selectedDate: widget.selectedDate,
            onSelected: widget.onSelected,
          );
        },
      ),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _WeekDateRow extends StatelessWidget {
  const _WeekDateRow({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double horizontalPadding = 16;
        const double chipGap = 8;
        final double availableWidth =
            constraints.maxWidth - (horizontalPadding * 2);
        final double chipWidth = (availableWidth - (chipGap * 6)) / 7;
        final double clampedChipWidth = chipWidth.clamp(40, 56);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: List<Widget>.generate(dates.length, (int index) {
              final DateTime date = dates[index];
              final bool isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return Padding(
                padding: EdgeInsets.only(
                  right: index == dates.length - 1 ? 0 : chipGap,
                ),
                child: SizedBox(
                  width: clampedChipWidth,
                  child: _DateChip(
                    date: date,
                    isActive: isSelected,
                    onPressed: () => onSelected(date),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isActive,
    required this.onPressed,
  });

  final DateTime date;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(52, 72),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        backgroundColor: isActive ? colorScheme.primary : colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            _weekdayLabel(date.weekday),
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}
