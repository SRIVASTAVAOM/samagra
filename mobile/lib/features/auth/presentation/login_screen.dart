import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_dialog.dart';

/// SAMAGRA Mobile Login Screen - Premium Glassmorphism Design
///
/// Redesigned with:
/// - Premium Glassmorphism + Neumorphism
/// - Soft white and light blue gradient background
/// - Royal blue, cyan and navy blue accents
/// - Smooth rounded input fields with soft shadows
/// - Centered SAMAGRA logo
/// - Clean, professional SaaS mobile app appearance
///
/// Authentication behavior remains unchanged (LoginSubmittedEvent, AuthBloc states, etc.)

// ─── Design Tokens for Premium Glassmorphism Theme ────────────────────────────
class _DesignTokens {
  _DesignTokens._();

  // Background
  static const Color bgGradientStart = Color(0xFFE8F3FF);
  static const Color bgGradientEnd = Color(0xFFF0F5FF);
  static const Color white = Color(0xFFFFFFFF);
  
  // Primary Colors
  static const Color royalBlue = Color(0xFF1E40AF);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color navyBlue = Color(0xFF0F172A);
  static const Color lightBlue = Color(0xFFDEEFF8);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Input Colors
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE0E7FF);
  static const Color inputFocusBorder = Color(0xFF06B6D4);
  static const Color inputPlaceholder = Color(0xFFCBD5E1);
  static const Color inputIcon = Color(0xFF64748B);
  
  // Error/Success
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  
  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusXl = 32.0;
  
  // Shadows - Soft and subtle for glassmorphism
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  // Gradients
  static const LinearGradient loginButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
  );
  
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgGradientStart, bgGradientEnd],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    setState(() => _errorMessage = null);
    final authRepo = context.read<AuthBloc>().authRepository;
    final updatedIdentifier = await showDialog<String>(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        authRepository: authRepo,
        initialIdentifier: _identifierController.text.trim(),
      ),
    );

    if (updatedIdentifier != null && updatedIdentifier.isNotEmpty && mounted) {
      _identifierController.text = updatedIdentifier;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignTokens.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: _DesignTokens.bgGradient,
        ),
        child: Stack(
          children: [
            // Decorative gradient blobs in background
            const _BackgroundDecorations(),
            
            // Main scrollable content
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is AuthFailure) {
                        setState(() => _errorMessage = state.errorMessage);
                      }
                    },
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            _buildLogo(),
                            const SizedBox(height: 24),

                            // Tagline
                            Text(
                              'THE COMPLETE SCHOOL PLATFORM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: _DesignTokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Welcome Back Heading
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _DesignTokens.navyBlue,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Sign in to your school account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: _DesignTokens.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Error Message
                            if (_errorMessage != null) ...[
                              _buildErrorMessage(_errorMessage!),
                              const SizedBox(height: 16),
                            ],

                            // Login Form
                            Form(
                              key: _formKey,
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Username/Email Input
                                    _buildInputField(
                                      controller: _identifierController,
                                      focusNode: _identifierFocus,
                                      label: 'Username or Email',
                                      hint: 'Enter your login ID',
                                      icon: Icons.person_outline,
                                      keyboardType: TextInputType.emailAddress,
                                      enabled: !isLoading,
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Username or email is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Input
                                    _buildInputField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      enabled: !isLoading,
                                      onFieldSubmitted: (_) => _submit(),
                                      suffix: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        splashRadius: 20,
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 18,
                                          color: _DesignTokens.inputIcon,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Remember Me & Forgot Password
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: isLoading
                                                    ? null
                                                    : (value) {
                                                        setState(() {
                                                          _rememberMe = value ?? false;
                                                        });
                                                      },
                                                activeColor: _DesignTokens.royalBlue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Remember Me',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: _DesignTokens.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: isLoading
                                              ? null
                                              : _showForgotPasswordDialog,
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _DesignTokens.royalBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    // Login Button
                                    _buildLoginButton(isLoading, _submit),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Divider with text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: _DesignTokens.inputBorder,
                                    height: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: _DesignTokens.textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: _DesignTokens.inputBorder,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Footer tagline
                            Text(
                              'THE COMPLETE SCHOOL PLATFORM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: _DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _DesignTokens.white,
        boxShadow: _DesignTokens.shadowMedium,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/samagra_mark.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    Function(String)? onFieldSubmitted,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
            boxShadow: isFocused ? _DesignTokens.shadowMedium : _DesignTokens.shadowSoft,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            onFieldSubmitted: onFieldSubmitted,
            textInputAction: TextInputAction.next,
            autofillHints: obscureText
                ? const [AutofillHints.password]
                : const [AutofillHints.username],
            autocorrect: false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _DesignTokens.inputPlaceholder,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isFocused
                    ? _DesignTokens.inputFocusBorder
                    : _DesignTokens.inputIcon,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: _DesignTokens.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
                borderSide: BorderSide(
                  color: _DesignTokens.inputBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
                borderSide: BorderSide(
                  color: _DesignTokens.inputBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
                borderSide: BorderSide(
                  color: _DesignTokens.inputFocusBorder,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
                borderSide: BorderSide(
                  color: _DesignTokens.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_DesignTokens.radiusMd),
                borderSide: BorderSide(
                  color: _DesignTokens.error,
                  width: 2,
                ),
              ),
              errorStyle: TextStyle(
                fontSize: 12,
                color: _DesignTokens.error,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: _DesignTokens.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DesignTokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: _DesignTokens.royalBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: _DesignTokens.loginButtonGradient,
            borderRadius: BorderRadius.circular(_DesignTokens.radiusXl),
          ),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(_DesignTokens.radiusXl),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _DesignTokens.errorBg,
        borderRadius: BorderRadius.circular(_DesignTokens.radiusSm),
        border: Border.all(color: _DesignTokens.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline,
              size: 16,
              color: _DesignTokens.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: _DesignTokens.error,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BACKGROUND DECORATIONS
// ═════════════════════════════════════════════════════════════════════════════

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left blur blob
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _DesignTokens.cyan.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: _DesignTokens.cyan.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        // Bottom-right blur blob
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _DesignTokens.lightBlue.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: _DesignTokens.lightBlue.withValues(alpha: 0.2),
                  blurRadius: 80,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
