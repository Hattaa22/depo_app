import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Bottom sheet pemilih rentang tanggal — ringkas, tema biru app.
class ModernDateRangeSheet {
  ModernDateRangeSheet._();

  static const Color _primary = Color(0xFF1392EC);

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initial,
    String title = 'Pilih Periode',
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetBody(initial: initial, title: title),
    );
  }

  static ThemeData _pickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: _primary,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E293B),
      ),
      datePickerTheme: const DatePickerThemeData(
        headerBackgroundColor: _primary,
        headerForegroundColor: Colors.white,
        rangePickerHeaderBackgroundColor: _primary,
        rangePickerHeaderForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: Color(0x331392EC),
        todayForegroundColor: WidgetStatePropertyAll(_primary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _primary),
      ),
    );
  }

  static Future<DateTimeRange?> openCalendarRange(
    BuildContext context, {
    DateTimeRange? initial,
  }) {
    final now = DateTime.now();
    return showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => Theme(
        data: _pickerTheme(ctx),
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: DateRangePickerDialog(
            firstDate: DateTime(2020),
            lastDate: now,
            initialDateRange: initial ??
                DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: now,
                ),
            helpText: 'Rentang tanggal',
            cancelText: 'Batal',
            confirmText: 'OK',
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatefulWidget {
  final DateTimeRange? initial;
  final String title;

  const _SheetBody({this.initial, required this.title});

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  static const Color _primary = Color(0xFF1392EC);

  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initial?.start ?? DateTime(now.year, now.month, 1);
    _end = widget.initial?.end ?? now;
  }

  void _setRange(DateTimeRange range) {
    setState(() {
      _start = range.start;
      _end = range.end;
    });
  }

  Future<void> _bukaKalender() async {
    final range = await ModernDateRangeSheet.openCalendarRange(
      context,
      initial: DateTimeRange(start: _start, end: _end),
    );
    if (range != null) _setRange(range);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Hari ini', DateTimeRange(
                  start: DateTime(now.year, now.month, now.day),
                  end: DateTime(now.year, now.month, now.day),
                )),
                _chip('7 hari', DateTimeRange(
                  start: now.subtract(const Duration(days: 6)),
                  end: now,
                )),
                _chip('Bulan ini', DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: now,
                )),
                _chip('Bulan lalu', DateTimeRange(
                  start: DateTime(now.year, now.month - 1, 1),
                  end: DateTime(now.year, now.month, 0),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _bukaKalender,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${Formatters.date(_start)} – ${Formatters.date(_end)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8), size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      DateTimeRange(start: _start, end: _end),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, DateTimeRange range) {
    final selected = _isSameDay(_start, range.start) && _isSameDay(_end, range.end);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setRange(range),
      selectedColor: const Color(0xFFEFF6FF),
      checkmarkColor: _primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? _primary : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: selected ? _primary : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
