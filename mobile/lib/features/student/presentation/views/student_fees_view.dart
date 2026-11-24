import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/student_features_bloc.dart';
import '../../bloc/student_features_event.dart';
import '../../bloc/student_features_state.dart';
import '../../models/student_features_model.dart';

class StudentFeesView extends StatefulWidget {
  const StudentFeesView({super.key});

  @override
  State<StudentFeesView> createState() => _StudentFeesViewState();
}

class _StudentFeesViewState extends State<StudentFeesView> {
  int _activeSubTab = 0; // 0: Dues & Structure, 1: Receipts

  @override
  void initState() {
    super.initState();
    context.read<StudentFeaturesBloc>().add(const LoadStudentFeesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Column(
        children: [
          // Sub-Tab Switcher
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSubTabButton('Fee Structure & Dues', 0),
                const SizedBox(width: 8),
                _buildSubTabButton('Fee Receipts', 1),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: AppColors.secondaryText),
                  tooltip: 'Refresh',
                  onPressed: () {
                    if (_activeSubTab == 0) {
                      context
                          .read<StudentFeaturesBloc>()
                          .add(const LoadStudentFeesEvent());
                    } else {
                      context
                          .read<StudentFeaturesBloc>()
                          .add(const LoadStudentReceiptsEvent());
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeSubTab == 0
                ? _buildDuesTab()
                : _buildReceiptsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String title, int index) {
    final isSelected = _activeSubTab == index;
    return InkWell(
      onTap: () {
        setState(() => _activeSubTab = index);
        if (index == 0) {
          context.read<StudentFeaturesBloc>().add(const LoadStudentFeesEvent());
        } else {
          context
              .read<StudentFeaturesBloc>()
              .add(const LoadStudentReceiptsEvent());
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryText : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.surface : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildDuesTab() {
    return BlocBuilder<StudentFeaturesBloc, StudentFeaturesState>(
      builder: (context, state) {
        if (state is StudentFeaturesLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state is StudentFeaturesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<StudentFeaturesBloc>()
                          .add(const LoadStudentFeesEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is StudentFeesLoaded) {
          final overview = state.overview;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryItem('Total Dues', '₹${overview.totalDues.toStringAsFixed(0)}', AppColors.primaryText),
                        Container(width: 1, height: 36, color: AppColors.border),
                        _buildSummaryItem('Total Paid', '₹${overview.totalPaid.toStringAsFixed(0)}', AppColors.success),
                        Container(width: 1, height: 36, color: AppColors.border),
                        _buildSummaryItem('Outstanding', '₹${overview.totalOutstanding.toStringAsFixed(0)}', AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: AppColors.secondaryText),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Online payment gateway is currently deferred. Fee payments can be made directly at the school accounts counter.',
                              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fee Installments & Heads',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              if (overview.fees.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No fee installments scheduled',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                )
              else
                ...overview.fees.map((fee) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFeeCard(fee),
                    )),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(FeeItemModel fee) {
    Color statusColor;
    switch (fee.status.toUpperCase()) {
      case 'PAID':
        statusColor = AppColors.success;
        break;
      case 'PARTIAL':
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${fee.dueDate}  •  Paid: ₹${fee.amountPaid.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${fee.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fee.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state is StudentReceiptsLoaded) {
          final receipts = state.receipts;
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.secondaryText),
                  SizedBox(height: 12),
                  Text(
                    'No payment receipts recorded yet',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = receipts[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showReceiptBreakdownSheet(context, r),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.receipt_outlined, size: 22, color: AppColors.primaryText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.receiptNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.paymentDate}  •  ${r.paymentMode}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                ),
                                if (r.feeTitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    r.feeTitle!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${r.amountPaid.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                onPressed: () => _showReceiptBreakdownSheet(context, r),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: const Text('View', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showReceiptBreakdownSheet(BuildContext context, FeeReceiptModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Fee Receipt Breakdown',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),

                // Total Paid Highlight Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Amount Paid',
                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${r.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PAID  •  ${r.paymentDate}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Itemized Breakdown Rows
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Receipt Number with Copy Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Receipt No', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.receiptNumber,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: r.receiptNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Receipt #${r.receiptNumber} copied to clipboard'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.primaryText,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.copy, size: 14, color: AppColors.primaryAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildBreakdownRow('Payment Date', r.paymentDate),
                      const Divider(height: 16, color: AppColors.border),
                      _buildBreakdownRow('Payment Mode', r.paymentMode),
                      const Divider(height: 16, color: AppColors.border),
                      _buildBreakdownRow('Fee Head', r.feeTitle ?? 'Composite Annual / Term Fee'),
                      if (r.transactionReference != null && r.transactionReference!.isNotEmpty) ...[
                        const Divider(height: 16, color: AppColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reference ID', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  r.transactionReference!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: r.transactionReference!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reference ID copied to clipboard'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.primaryText,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.copy, size: 14, color: AppColors.primaryAccent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      if (r.remarks != null && r.remarks!.isNotEmpty) ...[
                        const Divider(height: 16, color: AppColors.border),
                        _buildBreakdownRow('Remarks', r.remarks!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
