import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? backgroundGradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double? fontSize;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundGradient,
    this.border,
    this.boxShadow,
    this.fontSize,
  });

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? get _resolvedUrl {
    final trimmed = avatarUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final resolvedUrl = _resolvedUrl;

    final Widget initialsChild = Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: fontSize ?? (radius * 0.7),
          fontWeight: FontWeight.w700,
          color: foregroundColor ??
              (backgroundGradient != null ? Colors.white : AppColors.primaryText),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundGradient == null
            ? (backgroundColor ?? AppColors.scaffoldBackground)
            : null,
        gradient: backgroundGradient,
        shape: BoxShape.circle,
        border: border,
        boxShadow: boxShadow,
      ),
      child: resolvedUrl != null
          ? ClipOval(
              child: Image.network(
                resolvedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initialsChild,
              ),
            )
          : initialsChild,
    );
  }
}
