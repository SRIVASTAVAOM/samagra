import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays the active school name in dashboard hero cards, or a subtle loading
/// placeholder when the school name has not yet resolved.
class SchoolHeaderBadge extends StatelessWidget {
  final String? schoolName;

  const SchoolHeaderBadge({super.key, this.schoolName});

  @override
  Widget build(BuildContext context) {
    final trimmed = schoolName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return Text(
        trimmed.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.indigo200,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 11,
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
