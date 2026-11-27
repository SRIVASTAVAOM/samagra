import 'package:flutter/material.dart';

class SamagraBackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const SamagraBackButton({super.key, this.onPressed});

  @override
  State<SamagraBackButton> createState() => _SamagraBackButtonState();
}

class _SamagraBackButtonState extends State<SamagraBackButton> {
  bool _isHandlingBack = false;

  Future<void> _handleBack() async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      if (widget.onPressed != null) {
        widget.onPressed!();
      } else {
        await Navigator.of(context).maybePop();
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() => _isHandlingBack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: 'Back',
        onPressed: _isHandlingBack ? null : _handleBack,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFEAF3FF),
          foregroundColor: const Color(0xFF1677F2),
          shape: const CircleBorder(),
          minimumSize: const Size(44, 44),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
    );
  }
}
