import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime end) onDateRangeSelected;

  const DateRangePicker({
    super.key,
    this.initialStart,
    this.initialEnd,
    required this.onDateRangeSelected,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _focusedDay;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _focusedDay = _startDate ?? DateTime.now();
  }

  void _selectRange(DateTime selectedDay) {
    if (_startDate == null) {
      setState(() {
        _startDate = selectedDay;
        _endDate = null;
      });
    } else if (_endDate == null) {
      if (selectedDay.isBefore(_startDate!)) {
        setState(() {
          _endDate = _startDate;
          _startDate = selectedDay;
        });
      } else {
        setState(() {
          _endDate = selectedDay;
        });
      }
      // Immediately call the callback when range is complete
      widget.onDateRangeSelected(_startDate!, _endDate!);
      Navigator.pop(context);
    } else {
      // Reset if clicking again
      setState(() {
        _startDate = selectedDay;
        _endDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Trip Dates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  if (_startDate != null && _endDate != null) {
                    return day.isAfter(_startDate!) &&
                            day.isBefore(_endDate!) ||
                        day.isAtSameMomentAs(_startDate!) ||
                        day.isAtSameMomentAs(_endDate!);
                  }
                  return day.isAtSameMomentAs(_startDate ?? DateTime(0));
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _selectRange(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[200]!,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: Colors.green[100]!,
                  rangeStartDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  withinRangeTextStyle: const TextStyle(color: Colors.black),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_startDate != null && _endDate != null)
                Text(
                  '${_startDate!.month}/${_startDate!.day} - ${_endDate!.month}/${_endDate!.day} (${_endDate!.difference(_startDate!).inDays + 1} days)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (_startDate != null)
                Text(
                  'Start: ${_startDate!.month}/${_startDate!.day} - Select end date',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                )
              else
                const Text(
                  'Select start date',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  if (_startDate != null && _endDate != null)
                    ElevatedButton(
                      onPressed: () {
                        widget.onDateRangeSelected(_startDate!, _endDate!);
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context).confirm),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
