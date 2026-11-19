import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../models/student_attendance_record_model.dart';

class StudentAttendanceHistoryView extends StatefulWidget {
  const StudentAttendanceHistoryView({super.key});

  @override
  State<StudentAttendanceHistoryView> createState() =>
      _StudentAttendanceHistoryViewState();
}

class _StudentAttendanceHistoryViewState
    extends State<StudentAttendanceHistoryView> {
  String? _selectedMonth; // 'YYYY-MM' e.g. '2026-11' or null for All
  DateTime? _selectedDate; // Specific date filter or null

  String _formatMonthYear(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length < 2) return yearMonth;
    final year = parts[0];
    final mInt = int.tryParse(parts[1]) ?? 1;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final mName = (mInt >= 1 && mInt <= 12) ? months[mInt - 1] : parts[1];
    return '$mName $year';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final monthName = months[date.month - 1];
    return '$day $monthName ${date.year}';
  }

  List<String> _getAvailableMonths(List<StudentAttendanceRecordModel> records) {
    final monthsSet = <String>{};
    final now = DateTime.now();
    final curMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    monthsSet.add(curMonth);

    for (final r in records) {
      final dateStr = r.attendanceDate.split('T')[0];
      if (dateStr.length >= 7) {
        monthsSet.add(dateStr.substring(0, 7));
      }
    }
    final list = monthsSet.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  List<StudentAttendanceRecordModel> _filterRecords(
      List<StudentAttendanceRecordModel> records) {
    return records.where((r) {
      final dateStr = r.attendanceDate.split('T')[0];
      if (_selectedDate != null) {
        final dStr =
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
        if (dateStr != dStr) return false;
      } else if (_selectedMonth != null) {
        if (!dateStr.startsWith(_selectedMonth!)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDate(
      BuildContext context, List<StudentAttendanceRecordModel> records) async {
    final now = DateTime.now();
    DateTime initial = _selectedDate ?? now;
    if (_selectedMonth != null && _selectedDate == null) {
      final parts = _selectedMonth!.split('-');
      if (parts.length == 2) {
        final y = int.tryParse(parts[0]) ?? now.year;
        final m = int.tryParse(parts[1]) ?? now.month;
        initial = DateTime(y, m, 1);
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAccent,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is AttendanceError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 36, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AttendanceBloc>()
                          .add(const LoadStudentOwnAttendanceEvent());
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is StudentAttendanceHistoryLoaded) {
          final allRecords = state.records;

          if (allRecords.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No attendance records found.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.secondaryText),
                ),
              ),
            );
          }

          final filteredRecords = _filterRecords(allRecords);
          final presentCount =
              filteredRecords.where((r) => r.status == 'PRESENT').length;
          final percentage = filteredRecords.isNotEmpty
              ? ((presentCount / filteredRecords.length) * 100)
                  .toStringAsFixed(1)
              : '0.0';

          final isFiltered = _selectedMonth != null || _selectedDate != null;

          String summaryTitle;
          if (_selectedDate != null) {
            summaryTitle = 'Attendance on ${_formatFullDate(_selectedDate!)}';
          } else if (_selectedMonth != null) {
            summaryTitle = 'Attendance for ${_formatMonthYear(_selectedMonth!)}';
          } else {
            summaryTitle = 'Overall Attendance';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Filter Bar (Month & Date Filters)
              _buildFilterBar(context, allRecords),

              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null
                                ? (filteredRecords.isNotEmpty
                                    ? filteredRecords.first.status
                                    : 'NO RECORD')
                                : '$percentage%',
                            style: TextStyle(
                              fontSize: _selectedDate != null ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate != null
                                  ? (filteredRecords.isNotEmpty &&
                                          filteredRecords.first.status ==
                                              'PRESENT'
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C))
                                  : AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? (filteredRecords.isNotEmpty
                                ? '1 Day Checked'
                                : '0 Days')
                            : '$presentCount / ${filteredRecords.length} Days Present',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attendance Logs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '${filteredRecords.length} record${filteredRecords.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (filteredRecords.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_outlined,
                          size: 36, color: AppColors.secondaryText),
                      const SizedBox(height: 8),
                      Text(
                        _selectedDate != null
                            ? 'No attendance recorded on ${_formatFullDate(_selectedDate!)}.'
                            : 'No attendance records found for ${_formatMonthYear(_selectedMonth!)}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset Filter & View All'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredRecords.map((r) => _buildAttendanceTile(r)),
            ],
          );
        }

        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _buildFilterBar(
      BuildContext context, List<StudentAttendanceRecordModel> records) {
    final availableMonths = _getAvailableMonths(records);
    final hasActiveFilter = _selectedMonth != null || _selectedDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Month Filter Dropdown
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _selectedMonth != null && _selectedDate == null
                          ? AppColors.primaryAccent
                          : AppColors.border,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      hint: const Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 16, color: AppColors.secondaryText),
                          SizedBox(width: 6),
                          Text('All Months',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primaryText)),
                        ],
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined,
                                  size: 16, color: AppColors.secondaryText),
                              SizedBox(width: 6),
                              Text('All Months',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryText)),
                            ],
                          ),
                        ),
                        ...availableMonths.map((m) {
                          return DropdownMenuItem<String?>(
                            value: m,
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppColors.secondaryText),
                                const SizedBox(width: 6),
                                Text(_formatMonthYear(m),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedMonth = val;
                          if (_selectedDate != null && val != null) {
                            final dMonth =
                                '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}';
                            if (dMonth != val) {
                              _selectedDate = null;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date Picker Button
              InkWell(
                onTap: () => _pickDate(context, records),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? AppColors.primaryAccent.withValues(alpha: 0.1)
                        : AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppColors.primaryAccent
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: _selectedDate != null
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}'
                            : 'Pick Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedDate != null
                              ? AppColors.primaryAccent
                              : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Clear Button (if active)
              if (hasActiveFilter) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 40,
                    width: 36,
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ],
          ),

          // Active filter indicator chip
          if (hasActiveFilter) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Active Filter: ',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.secondaryText),
                ),
                Text(
                  _selectedDate != null
                      ? 'Date: ${_formatFullDate(_selectedDate!)}'
                      : 'Month: ${_formatMonthYear(_selectedMonth!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear Filter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(StudentAttendanceRecordModel record) {
    final isPresent = record.status == 'PRESENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.attendanceDate.split('T')[0],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                if (record.markedByName != null)
                  Text(
                    'Marked by: ${record.markedByName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                if (record.remarks != null && record.remarks!.isNotEmpty)
                  Text(
                    'Note: ${record.remarks}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isPresent
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFCA5A5),
              ),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPresent
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
