import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_dialog.dart';

/// SAMAGRA mobile login screen.
///
/// Visual layer mirrors the web admin login page
/// (web-admin/src/app/(auth)/login/AdminLogin.tsx + AdminLogin.css, prefix `aln-`),
/// adapted to phone widths using the web's own <=560px breakpoint values.
/// Authentication behaviour (validation, LoginSubmittedEvent, AuthBloc states,
/// forgot-password dialog, router-driven navigation) is unchanged.

// ─── Design tokens (copied from AdminLogin.css `.aln-root`) ────────────────────
class _Aln {
  _Aln._();

  static const Color bgPage = Color(0xFFF4F6FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1B2F5C);
  static const Color primaryLight = Color(0xFF3F5179);
  static const Color deep = Color(0xFF142449);
  static const Color navy = Color(0xFF0F1D3A);
  static const Color muted = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF8FAFF);
  static const Color placeholder = Color(0xFFB0BEC5);
  static const Color fieldIcon = Color(0xFF94A3B8);
  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBd = Color(0xFFFECACA);
  static const Color infoBg = Color(0xFFF1F4F9);
  static const Color infoBd = Color(0xFFC6CFDF);
  static const Color infoTx = Color(0xFF142449);

  static const double rLg = 18;
  static const double rMd = 12;
  static const double rSm = 8;

  // --c-bg-left: linear-gradient(150deg, #fff7ec 0%, #f3f5f9 55%, #eef1f6 100%)
  static const LinearGradient bgLeft = LinearGradient(
    begin: Alignment(-0.5, -0.87),
    end: Alignment(0.5, 0.87),
    colors: [Color(0xFFFFF7EC), Color(0xFFF3F5F9), Color(0xFFEEF1F6)],
    stops: [0.0, 0.55, 1.0],
  );

  // --c-primary-g: linear-gradient(135deg, #3f5179 0%, #1b2f5c 100%)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  // --shadow-card
  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x170F172A), blurRadius: 24, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 6, offset: Offset(0, 1)),
  ];

  // --shadow-stat
  static const List<BoxShadow> shadowStat = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

// ─── Branding (same as web DEFAULT_SCHOOL_BRANDING) ───────────────────────────
class _Branding {
  final String name;
  final String tagline;
  final String abbr;
  final String heroTitle;
  final String heroSubtitle;
  final String badge;
  final String cardTitle;
  final String cardSubtitle;
  const _Branding({
    required this.name,
    required this.tagline,
    required this.abbr,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.badge,
    required this.cardTitle,
    required this.cardSubtitle,
  });

  static const school = _Branding(
    name: 'School Name',
    tagline: 'Learn • Grow • Lead',
    abbr: 'SN',
    heroTitle: 'School Name',
    heroSubtitle:
        'Integrated School ERP platform empowering management, faculty, and academic excellence.',
    badge: 'SAMAGRA',
    cardTitle: 'Welcome back!',
    cardSubtitle: 'Sign in to access your school dashboard.',
  );

  static const superAdmin = _Branding(
    name: 'SAMAGRA Platform HQ',
    tagline: 'Multi-Tenant Institutional SaaS Administration',
    abbr: 'HQ',
    heroTitle: 'SAMAGRA Platform HQ',
    heroSubtitle:
        'Centralized institutional management, multi-school tenant governance, and global licensing.',
    badge: 'PLATFORM HQ',
    cardTitle: 'Platform HQ Login',
    cardSubtitle: 'Sign in to SAMAGRA SaaS Management HQ.',
  );
}

class _Feature {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  const _Feature(this.icon, this.color, this.bg, this.title, this.desc);
}

const List<_Feature> _featureCards = [
  _Feature(Icons.people_outline, Color(0xFF1B2F5C), Color(0xFFE3E8F1),
      'Unified Access', 'One login for all roles.'),
  _Feature(Icons.verified_user_outlined, Color(0xFF16A34A), Color(0xFFDCFCE7),
      'Secure & Reliable', 'Your data is always safe.'),
  _Feature(Icons.trending_up, Color(0xFFD4480A), Color(0xFFFFE6D5),
      'Smart Insights', 'AI-powered decisions.'),
  _Feature(Icons.notifications_none, Color(0xFFD97706), Color(0xFFFEF3C7),
      'Real-time Updates', 'Stay informed, always.'),
];

class _Stat {
  final IconData icon;
  final Color color;
  final Color bg;
  final String value;
  final String label;
  const _Stat(this.icon, this.color, this.bg, this.value, this.label);
}

const List<_Stat> _stats = [
  _Stat(Icons.account_balance_outlined, Color(0xFF1B2F5C), Color(0xFFE3E8F1),
      '500+', 'Schools'),
  _Stat(Icons.people_outline, Color(0xFF16A34A), Color(0xFFDCFCE7), '50K+',
      'Users'),
  _Stat(Icons.menu_book_outlined, Color(0xFFD97706), Color(0xFFFEF3C7), '1M+',
      'Students'),
  _Stat(Icons.bar_chart, Color(0xFFD4480A), Color(0xFFFFE6D5), '99.9%',
      'Uptime'),
];

class _BgIcon {
  final IconData icon;
  final double top; // fraction
  final double left; // fraction
  final double size;
  final double opacity;
  const _BgIcon(this.icon, this.top, this.left, this.size, this.opacity);
}

const List<_BgIcon> _bgIcons = [
  _BgIcon(Icons.school_outlined, 0.08, 0.06, 26, 0.12),
  _BgIcon(Icons.menu_book_outlined, 0.20, 0.76, 20, 0.10),
  _BgIcon(Icons.bar_chart, 0.48, 0.66, 22, 0.09),
  _BgIcon(Icons.account_balance_outlined, 0.68, 0.04, 24, 0.11),
  _BgIcon(Icons.school_outlined, 0.78, 0.52, 18, 0.08),
  _BgIcon(Icons.menu_book_outlined, 0.36, 0.03, 18, 0.09),
];

/// Quick-test presets (same as web: one preset per portal).
const MapEntry<String, String> _schoolAdminPreset =
    MapEntry('School Admin', 'admin@apex.edu');
const MapEntry<String, String> _superAdminPreset =
    MapEntry('Super Admin', 'superadmin');
const String _quickTestPassword = 'Password@123';

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
  bool _superAdminMode = false;
  String? _info;

  _Branding get _branding =>
      _superAdminMode ? _Branding.superAdmin : _Branding.school;

  /// Web: "Go to Super Admin Portal" / "Go to School Admin Portal" link.
  /// On mobile this only switches the screen's branding + quick-test preset.
  void _togglePortal() {
    setState(() {
      _superAdminMode = !_superAdminMode;
      _info = null;
      _identifierController.clear();
      _passwordController.clear();
    });
  }

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
    if (_info != null) setState(() => _info = null);
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
    setState(() => _info = null);
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
      setState(() {
        _info =
            'Password updated for $updatedIdentifier! Click Sign in to proceed.';
      });
    }
  }

  void _fillPreset(String id) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = _quickTestPassword;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Web uses the platform system font stack (-apple-system / Roboto),
    // so the login screen uses the platform default typography.
    final base = Theme.of(context);
    final typo = Typography.material2021(platform: base.platform);
    final textTheme = typo.englishLike
        .merge(typo.black)
        .apply(bodyColor: _Aln.navy, displayColor: _Aln.navy);

    return Theme(
      data: base.copyWith(
        textTheme: textTheme,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _Aln.primary,
          selectionHandleColor: _Aln.primary,
        ),
      ),
      child: Scaffold(
        backgroundColor: _Aln.bgPage,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _Header(branding: _branding),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroPanel(),
                    const _StatsPanel(),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gradient panel: hero → login card → feature cards → illustration + quote.
  // (Web stacks hero/features above the card; on phones the card is moved up
  // directly under the hero so the Sign in button stays within reach.)
  Widget _buildHeroPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: _Aln.bgLeft,
        border: Border(bottom: BorderSide(color: _Aln.divider)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _BackgroundIcons()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(branding: _branding),
                    const SizedBox(height: 18),
                    _buildLoginCard(),
                    const SizedBox(height: 18),
                    const _FeatureGrid(),
                    const SizedBox(height: 18),
                    const _BottomRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _Aln.white,
          borderRadius: BorderRadius.circular(_Aln.rLg),
          border: Border.all(color: _Aln.divider),
          boxShadow: _Aln.shadowCard,
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final errorMessage = state is AuthFailure ? state.errorMessage : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CardHeader(branding: _branding),
                const SizedBox(height: 22),
                if (errorMessage != null) ...[
                  _Notice.error(errorMessage),
                  const SizedBox(height: 12),
                ],
                if (_info != null) ...[
                  _Notice.info(_info!),
                  const SizedBox(height: 12),
                ],
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Login ID
                        const _FieldLabel('Login ID'),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('identifierField'),
                          controller: _identifierController,
                          focusNode: _identifierFocus,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                          style: _inputTextStyle,
                          decoration: _inputDecoration(
                            hint: 'Enter your login ID',
                            prefixIcon: Icons.person_outline,
                            focused: _identifierFocus.hasFocus,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Identifier is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password — label row with Forgot Password on the right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _FieldLabel('Password'),
                            _TextLink(
                              key: const Key('forgotPasswordButton'),
                              label: 'Forgot Password?',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              onTap: isLoading ? null : _showForgotPasswordDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('passwordField'),
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          style: _inputTextStyle,
                          decoration: _inputDecoration(
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            focused: _passwordFocus.hasFocus,
                            suffix: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              splashRadius: 18,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 16,
                                color: _Aln.fieldIcon,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _SubmitButton(
                          key: const Key('signInButton'),
                          loading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),

                // Portal switcher (web: `.aln-back-home`)
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_outlined, size: 15, color: _Aln.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _TextLink(
                        key: const Key('portalSwitchLink'),
                        label: _superAdminMode
                            ? 'Go to School Admin Portal (/login)'
                            : 'Go to Super Admin Portal (/super-admin/login)',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        onTap: isLoading ? null : _togglePortal,
                      ),
                    ),
                  ],
                ),

                // Quick test preset (web: `.aln-presets`)
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: _Aln.divider),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Quick test:',
                      style: TextStyle(fontSize: 12, color: _Aln.muted),
                    ),
                    _TextLink(
                      label: (_superAdminMode ? _superAdminPreset : _schoolAdminPreset).key,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Aln.deep,
                      onTap: isLoading
                          ? null
                          : () => _fillPreset((_superAdminMode ? _superAdminPreset : _schoolAdminPreset).value),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const TextStyle _inputTextStyle =
      TextStyle(fontSize: 14, color: _Aln.navy);

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required bool focused,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Aln.rMd),
          borderSide: BorderSide(color: c, width: 1.5),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _Aln.placeholder,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      filled: true,
      fillColor: focused ? _Aln.white : _Aln.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      prefixIcon: Icon(prefixIcon, size: 16, color: _Aln.fieldIcon),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
      suffixIcon: suffix,
      suffixIconConstraints: suffix == null
          ? null
          : const BoxConstraints(minWidth: 44, minHeight: 48),
      errorStyle: const TextStyle(fontSize: 12, color: _Aln.red),
      enabledBorder: border(_Aln.divider),
      disabledBorder: border(_Aln.divider),
      focusedBorder: border(_Aln.primary),
      errorBorder: border(_Aln.redBd),
      focusedErrorBorder: border(_Aln.red),
      border: border(_Aln.divider),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Pieces
// ═════════════════════════════════════════════════════════════════════════════

/// `.aln-header` — school avatar + name on the left, SAMAGRA badge on the right.
class _Header extends StatelessWidget {
  final _Branding branding;
  const _Header({required this.branding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Aln.white,
        border: Border(bottom: BorderSide(color: _Aln.divider)),
        boxShadow: [
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_Aln.primary, _Aln.deep],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x471B2F5C),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  branding.abbr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      branding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Aln.navy,
                        letterSpacing: -0.13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branding.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _Aln.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _Aln.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Aln.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/samagra_mark.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                branding.badge,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _Aln.navy,
                  letterSpacing: 1.12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.aln-bg-icons` — faint decorative icons scattered over the gradient panel.
class _BackgroundIcons extends StatelessWidget {
  const _BackgroundIcons();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            for (final i in _bgIcons)
              Positioned(
                top: c.maxHeight * i.top,
                left: c.maxWidth * i.left,
                child: Icon(
                  i.icon,
                  size: i.size,
                  color: _Aln.primaryLight.withValues(alpha: i.opacity),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.aln-hero`
class _Hero extends StatelessWidget {
  final _Branding branding;
  const _Hero({required this.branding});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          branding.heroTitle,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.55,
            color: _Aln.navy,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          branding.heroSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.65,
            color: _Aln.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// `.aln-card-header`
class _CardHeader extends StatelessWidget {
  final _Branding branding;
  const _CardHeader({required this.branding});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8F1),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x291D4ED8), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.verified_user_outlined,
              size: 22, color: _Aln.deep),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branding.cardTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _Aln.navy,
                  letterSpacing: -0.27,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                branding.cardSubtitle,
                style: const TextStyle(fontSize: 13, color: _Aln.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.aln-alert` / `.aln-info`
class _Notice extends StatelessWidget {
  final String message;
  final bool isError;

  const _Notice.error(this.message) : isError = true;
  const _Notice.info(this.message) : isError = false;

  @override
  Widget build(BuildContext context) {
    final fg = isError ? _Aln.red : _Aln.infoTx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? _Aln.redBg : _Aln.infoBg,
        borderRadius: BorderRadius.circular(_Aln.rSm),
        border: Border.all(color: isError ? _Aln.redBd : _Aln.infoBd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isError) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline, size: 15, color: fg),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.45, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.aln-label`
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _Aln.navy,
        letterSpacing: 0.13,
      ),
    );
  }
}

/// `.aln-link`
class _TextLink extends StatelessWidget {
  final String label;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final VoidCallback? onTap;

  const _TextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
    this.color = _Aln.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: onTap == null ? color.withValues(alpha: 0.5) : color,
          ),
        ),
      ),
    );
  }
}

/// `.aln-submit-btn` — gradient navy button with spinner while signing in.
class _SubmitButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _SubmitButton({super.key, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_Aln.rMd);
    return Opacity(
      opacity: loading ? 0.70 : 1,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: _Aln.primaryGradient,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
                color: Color(0x521B2F5C), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Color(0x59FFFFFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    loading ? 'Signing in…' : 'Sign in',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.155,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.aln-features` — 2×2 on phones (web <=560px breakpoint).
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    Widget row(_Feature a, _Feature b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _FeatureCard(a)),
              const SizedBox(width: 10),
              Expanded(child: _FeatureCard(b)),
            ],
          ),
        );

    return Column(
      children: [
        row(_featureCards[0], _featureCards[1]),
        const SizedBox(height: 10),
        row(_featureCards[2], _featureCards[3]),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature f;
  const _FeatureCard(this.f);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(_Aln.rMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: _Aln.shadowSoft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: f.bg, shape: BoxShape.circle),
            child: Icon(f.icon, size: 22, color: f.color),
          ),
          const SizedBox(height: 8),
          Text(
            f.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _Aln.navy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            f.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _Aln.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// `.aln-bottom-row` — school illustration + Nelson Mandela quote.
class _BottomRow extends StatelessWidget {
  const _BottomRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 100, child: _FloatingIllustration()),
        SizedBox(width: 20),
        Expanded(child: _QuoteCard()),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(_Aln.rMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x120F172A), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, 4),
            child: const Text(
              '"',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1,
                color: _Aln.primaryLight,
                fontFamily: 'Georgia',
                fontFamilyFallback: ['serif'],
              ),
            ),
          ),
          const Text(
            'Education is the most powerful weapon which you can use to change the world.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Aln.navy,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '— Nelson Mandela',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _Aln.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.aln-school-svg` with the `aln-float` animation (4s ease-in-out, -7px).
class _FloatingIllustration extends StatefulWidget {
  const _FloatingIllustration();

  @override
  State<_FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<_FloatingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -7 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
      child: const AspectRatio(
        aspectRatio: 200 / 160,
        child: CustomPaint(painter: _SchoolPainter()),
      ),
    );
  }
}

/// Paints the same school-building SVG used on the web (viewBox 0 0 200 160).
class _SchoolPainter extends CustomPainter {
  const _SchoolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s, s);

    final p = Paint()..isAntiAlias = true;

    void rect(double x, double y, double w, double h, double r, Color c) {
      p
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = c;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
          p);
    }

    void circle(double cx, double cy, double r, Color c) {
      p
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = c;
      canvas.drawCircle(Offset(cx, cy), r, p);
    }

    void poly(List<Offset> pts, Color c) {
      p
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = c;
      canvas.drawPath(Path()..addPolygon(pts, true), p);
    }

    void line(double x1, double y1, double x2, double y2, Color c, double w,
        {bool round = false}) {
      final lp = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..color = c
        ..strokeWidth = w
        ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), lp);
    }

    const navy = Color(0xFF142449);
    const window = Color(0xFFC6CFDF);
    const wing = Color(0xFF60A5FA);
    const leaf = Color(0xFF22C55E);
    const leafDark = Color(0xFF16A34A);
    const trunk = Color(0xFF854D0E);

    // Ground
    rect(0, 128, 200, 32, 4, const Color(0xFFD1E9C8));

    // Main wall with gradient (#3f5179 → #1b2f5c)
    const wallRect = Rect.fromLTWH(30, 60, 100, 70);
    final wallPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3F5179), Color(0xFF1B2F5C)],
      ).createShader(wallRect);
    canvas.drawRRect(
        RRect.fromRectAndRadius(wallRect, const Radius.circular(4)), wallPaint);

    // Roof
    poly(const [Offset(25, 60), Offset(130, 60), Offset(77, 28)], navy);

    // Flag pole + flag
    line(77, 28, 77, 10, const Color(0xFF374151), 2);
    poly(const [Offset(77, 10), Offset(97, 16), Offset(77, 22)],
        const Color(0xFFEF4444));

    // Clock
    circle(77, 52, 10, Colors.white);
    final clockRing = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = navy;
    canvas.drawCircle(const Offset(77, 52), 10, clockRing);
    line(77, 52, 77, 45, navy, 1.5, round: true);
    line(77, 52, 82, 52, navy, 1.5, round: true);

    // Door
    rect(65, 98, 22, 32, 3, navy);
    circle(83, 115, 1.5, Colors.white);

    // Windows
    rect(38, 74, 18, 14, 2, window);
    rect(62, 74, 18, 14, 2, window);
    rect(86, 74, 18, 14, 2, window);
    rect(110, 74, 14, 14, 2, window);

    // Side wings
    rect(8, 88, 24, 42, 3, wing);
    rect(12, 96, 10, 10, 1, window);
    rect(128, 88, 24, 42, 3, wing);
    rect(138, 96, 10, 10, 1, window);

    // Trees
    circle(170, 120, 14, leaf);
    rect(168, 128, 4, 12, 0, trunk);
    circle(185, 122, 10, leafDark);
    rect(183, 128, 3, 10, 0, trunk);
    circle(20, 122, 12, leaf);
    rect(18, 128, 4, 10, 0, trunk);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.aln-stats` — 2×2 platform statistics on a white panel.
class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    Widget row(_Stat a, _Stat b) => Row(
          children: [
            Expanded(child: _StatTile(a)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(b)),
          ],
        );

    return Container(
      color: _Aln.white,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 26),
          child: Column(
            children: [
              row(_stats[0], _stats[1]),
              const SizedBox(height: 10),
              row(_stats[2], _stats[3]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _Stat s;
  const _StatTile(this.s);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Aln.white,
        borderRadius: BorderRadius.circular(_Aln.rMd),
        border: Border.all(color: _Aln.divider),
        boxShadow: _Aln.shadowStat,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
            child: Icon(s.icon, size: 18, color: s.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.value,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _Aln.navy,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(fontSize: 11, color: _Aln.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.aln-footer`
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: _Aln.white,
        border: Border(top: BorderSide(color: _Aln.divider)),
      ),
      child: const Text(
        '© 2026 SAMAGRA. All rights reserved.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: _Aln.muted),
      ),
    );
  }
}
