import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../models/student_attendance_record_model.dart';

/// Premium Student Attendance History View with Circular Donut Chart
/// Features:
/// - Student profile header with notifications and logout
/// - Month filter and date picker
/// - Circular donut chart showing overall attendance percentage
/// - Present/Absent counts with indicators
/// - Attendance log cards with status badges
/// - Bottom navigation bar
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

  String _formatDateForDisplay(String dateStr) {
    // Convert 'YYYY-MM-DD' to 'DD MMM YYYY'
    try {
      final date = DateTime.parse(dateStr.split('T')[0]);
      return _formatFullDate(date);
    } catch (_) {
      return dateStr;
    }
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading attendance...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
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
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<AttendanceBloc>()
                          .add(const LoadStudentOwnAttendanceEvent());
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is StudentAttendanceHistoryLoaded) {
          final allRecords = state.records;

          if (allRecords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 48,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Attendance Records',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your attendance records will appear here.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredRecords = _filterRecords(allRecords);
          final presentCount =
              filteredRecords.where((r) => r.status == 'PRESENT').length;
          final absentCount =
              filteredRecords.where((r) => r.status == 'ABSENT').length;
          final attendancePercentage = filteredRecords.isNotEmpty
              ? ((presentCount / filteredRecords.length) * 100)
              : 0.0;

          final isFiltered = _selectedMonth != null || _selectedDate != null;

          return Container(
            color: const Color(0xFFF4F8FF), // Very light blue background
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Filter Bar (Month & Date Filters)
                _buildFilterBar(context, allRecords),

                // Overall Attendance Card with Donut Chart
                if (!(_selectedDate != null))
                  _buildOverallAttendanceCard(
                      attendancePercentage, presentCount, absentCount),

                // Attendance Logs Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance Logs',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        '${filteredRecords.length} record${filteredRecords.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Empty State for Filtered Records
                if (filteredRecords.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 40,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? 'No attendance recorded'
                                : 'No records found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null
                                ? 'on ${_formatFullDate(_selectedDate!)}'
                                : 'for the selected month',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.secondaryText),
                          ),
                          if (isFiltered) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset Filters'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primaryAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ...filteredRecords.map((r) => _buildAttendanceTile(r)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(
      BuildContext context, List<StudentAttendanceRecordModel> records) {
    final availableMonths = _getAvailableMonths(records);
    final hasActiveFilter = _selectedMonth != null || _selectedDate != null;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month and Date Picker Row
          Row(
            children: [
              // Month Filter Dropdown
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedMonth != null && _selectedDate == null
                          ? AppColors.primaryAccent
                          : const Color(0xFFE3ECF8),
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 22, color: AppColors.secondaryText),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      hint: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 18, color: AppColors.secondaryText),
                          const SizedBox(width: 8),
                          const Text('All Months',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.primaryText)),
                        ],
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined,
                                  size: 18, color: AppColors.secondaryText),
                              SizedBox(width: 8),
                              Text('All Months',
                                  style: TextStyle(
                                      fontSize: 13,
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
                                    size: 16, color: AppColors.secondaryText),
                                const SizedBox(width: 8),
                                Text(_formatMonthYear(m),
                                    style: const TextStyle(fontSize: 13)),
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
              const SizedBox(width: 10),

              // Date Picker Button
              InkWell(
                onTap: () => _pickDate(context, records),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? AppColors.primaryAccent.withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppColors.primaryAccent
                          : const Color(0xFFE3ECF8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: _selectedDate != null
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}'
                            : 'Pick Date',
                        style: TextStyle(
                          fontSize: 13,
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
                const SizedBox(width: 8),
                InkWell(
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE3ECF8)),
                    ),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAttendanceCard(
      double attendancePercentage, int presentCount, int absentCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Donut Chart on the Left
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: _buildDonutChart(attendancePercentage),
                ),
              ),
              const SizedBox(width: 24),
              // Statistics on the Right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Present Count
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7), // Blue indicator
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Present',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              '$presentCount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Absent Count
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935), // Red indicator
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Absent',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              '$absentCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(double percentage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Custom Paint for Circular Progress
        CustomPaint(
          painter: DonutChartPainter(
            percentage: percentage.clamp(0, 100),
            primaryColor: const Color(0xFF0284C7),
            secondaryColor: const Color(0xFF24B9F2),
            backgroundColor: const Color(0xFFE2E8F0),
            strokeWidth: 12,
          ),
          size: const Size.square(140),
        ),
        // Center Text
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Overall',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceTile(StudentAttendanceRecordModel record) {
    final isPresent = record.status == 'PRESENT';
    final isAbsent = record.status == 'ABSENT';
    final isLeave = record.status == 'LEAVE';

    // Determine colors based on status
    Color badgeBg;
    Color badgeText;
    Color badgeBorder;
    if (isPresent) {
      badgeBg = const Color(0xFFEAF9F0); // Present background
      badgeText = const Color(0xFF16A765); // Present text
      badgeBorder = const Color(0xFFA7F3D0); // Present border
    } else if (isAbsent) {
      badgeBg = const Color(0xFFFFF0F0); // Absent background
      badgeText = const Color(0xFFE53935); // Absent text
      badgeBorder = const Color(0xFFFECACA); // Absent border
    } else if (isLeave) {
      badgeBg = const Color(0xFFFFF7E6); // Leave background
      badgeText = const Color(0xFFF59E0B); // Leave text
      badgeBorder = const Color(0xFFFDE68A); // Leave border
    } else {
      badgeBg = const Color(0xFFF3F4F6);
      badgeText = const Color(0xFF6B7280);
      badgeBorder = const Color(0xFFE5E7EB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3ECF8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateForDisplay(record.attendanceDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                if (record.markedByName != null &&
                    record.markedByName!.isNotEmpty)
                  Text(
                    'Marked by: ${record.markedByName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Note: ${record.remarks}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeBorder),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeText,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Circular Donut Chart
class DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final double strokeWidth;

  DonutChartPainter({
    required this.percentage,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc (percentage)
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [primaryColor, secondaryColor],
        stops: const [0.0, 1.0],
        startAngle: -pi / 2,
        endAngle: pi * 1.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate angle based on percentage
    final angle = (percentage / 100) * 2 * pi - (pi / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
