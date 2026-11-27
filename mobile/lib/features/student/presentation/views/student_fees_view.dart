import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/student_features_bloc.dart';
import '../../bloc/student_features_event.dart';
import '../../bloc/student_features_state.dart';
import '../../models/student_features_model.dart';

/// Premium Student Fees View with Premium Blue & White Theme
/// Features:
/// - Fee Structure & Dues tab
/// - Fee Receipts tab
/// - Three-column fee summary (Total Dues, Total Paid, Outstanding)
/// - Payment information card
/// - Fee installments & heads with status badges
/// - Refresh functionality
class StudentFeesView extends StatefulWidget {
  const StudentFeesView({super.key});

  @override
  State<StudentFeesView> createState() => _StudentFeesViewState();
}

class _StudentFeesViewState extends State<StudentFeesView> {
  int _activeSubTab = 0; // 0: Fee Structure & Dues, 1: Fee Receipts

  @override
  void initState() {
    super.initState();
    context.read<StudentFeaturesBloc>().add(const LoadStudentFeesEvent());
  }

  void _refreshCurrentTab() {
    if (_activeSubTab == 0) {
      context.read<StudentFeaturesBloc>().add(const LoadStudentFeesEvent());
    } else {
      context.read<StudentFeaturesBloc>().add(const LoadStudentReceiptsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FF), // Very light blue background
      child: Column(
        children: [
          // Fee Navigation Tabs
          _buildTabNavigationBar(),

          // Content Area
          Expanded(
            child: _activeSubTab == 0 ? _buildDuesTab() : _buildReceiptsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: const Color(0xFFE3ECF8))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Fee Structure & Dues Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeSubTab = 0);
                context.read<StudentFeaturesBloc>().add(const LoadStudentFeesEvent());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _activeSubTab == 0
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0284C7), Color(0xFF00B4D8)],
                        )
                      : null,
                  color: _activeSubTab == 0 ? null : AppColors.surface,
                  border: _activeSubTab == 0
                      ? null
                      : Border.all(color: const Color(0xFFE3ECF8), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: _activeSubTab == 0 ? Colors.white : AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fee Structure & Dues',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            _activeSubTab == 0 ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Fee Receipts Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeSubTab = 1);
                context
                    .read<StudentFeaturesBloc>()
                    .add(const LoadStudentReceiptsEvent());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _activeSubTab == 1
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0284C7), Color(0xFF00B4D8)],
                        )
                      : null,
                  color: _activeSubTab == 1 ? null : AppColors.surface,
                  border: _activeSubTab == 1
                      ? null
                      : Border.all(color: const Color(0xFFE3ECF8), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: _activeSubTab == 1 ? Colors.white : AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fee Receipts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            _activeSubTab == 1 ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Refresh Button
          InkWell(
            onTap: _refreshCurrentTab,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3ECF8), width: 1.5),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuesTab() {
    return BlocBuilder<StudentFeaturesBloc, StudentFeaturesState>(
      builder: (context, state) {
        if (state is StudentFeaturesLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading fee details...',
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

        if (state is StudentFeaturesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Fees',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<StudentFeaturesBloc>()
                          .add(const LoadStudentFeesEvent());
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

        if (state is StudentFeesLoaded) {
          final overview = state.overview;
          final installments = overview.fees; // Fixed: access fees from overview

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Fee Summary Card (3 columns)
              _buildFeeSummaryCard(overview),
              const SizedBox(height: 16),

              // Payment Information Card
              _buildPaymentInformationCard(),
              const SizedBox(height: 24),

              // Fee Installments & Heads Heading
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Fee Installments & Heads',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),

              // Installment Cards
              if (installments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No fee installments found',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...installments.map((inst) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInstallmentCard(inst),
                    )),

              const SizedBox(height: 20),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFeeSummaryCard(FeeOverviewModel overview) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          // Total Dues Column
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Dues',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatAmount(overview.totalDues)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wallet_outlined,
                    size: 24,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 100,
            color: const Color(0xFFE3ECF8),
          ),

          // Total Paid Column
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Paid',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatAmount(overview.totalPaid)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A765),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF9F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 24,
                    color: Color(0xFF16A765),
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 100,
            color: const Color(0xFFE3ECF8),
          ),

          // Outstanding Column
          Expanded(
            child: Column(
              children: [
                Text(
                  'Outstanding',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_formatAmount(overview.totalOutstanding)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    size: 24,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInformationCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online payment gateway is currently deferred.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fee payments can be made directly at the school accounts counter.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentCard(FeeItemModel installment) {
    final status = installment.status;
    final isPaid = status == 'PAID';
    final isOverdue = status == 'OVERDUE';

    // Determine colors based on status
    Color iconBg;
    Color iconColor;
    Color statusBgColor;
    Color statusTextColor;

    if (isPaid) {
      iconBg = const Color(0xFFEAF9F0);
      iconColor = const Color(0xFF16A765);
      statusBgColor = const Color(0xFFEAF9F0);
      statusTextColor = const Color(0xFF16A765);
    } else if (isOverdue) {
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFE53935);
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFE53935);
    } else {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFF59E0B);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),

          // Center Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.feeTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      installment.dueDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Paid: ₹${_formatAmount(installment.amountPaid)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Side: Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatAmount(installment.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsTab() {
    return BlocBuilder<StudentFeaturesBloc, StudentFeaturesState>(
      builder: (context, state) {
        if (state is StudentFeaturesLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading receipts...',
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

        if (state is StudentFeaturesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Receipts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<StudentFeaturesBloc>()
                          .add(const LoadStudentReceiptsEvent());
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

        if (state is StudentReceiptsLoaded) {
          final receipts = state.receipts;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (receipts.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No receipts found',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...receipts.map((receipt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReceiptCard(receipt),
                    )),
              const SizedBox(height: 20),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReceiptCard(FeeReceiptModel receipt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.receiptNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  receipt.paymentDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatAmount(receipt.amountPaid)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  // Download/view receipt action
                },
                child: Icon(
                  Icons.download_outlined,
                  size: 18,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    if (amount is String) {
      return amount;
    }
    if (amount is int) {
      return amount.toString();
    }
    if (amount is double) {
      return amount.toStringAsFixed(0);
    }
    return amount.toString();
  }
}

// Extension for StudentFeaturesBloc events
extension on StudentFeaturesBloc {
  // Events are defined in student_features_event.dart
  // LoadStudentFeesEvent, LoadStudentReceiptsEvent
}
