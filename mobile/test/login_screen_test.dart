import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const LoginScreen(),
      ),
    );
  }

  // The login screen has a continuously floating illustration (web parity),
  // so use pump() with a duration instead of pumpAndSettle().
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 500));

  group('LoginScreen Widget Tests', () {
    testWidgets('renders web-matched login UI elements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await settle(tester);

      // Header branding
      expect(find.text('SAMAGRA'), findsOneWidget);

      // Card header
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Login ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Form Fields
      expect(find.byKey(const Key('identifierField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);

      // Sign In CTA
      expect(find.byKey(const Key('signInButton')), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('triggers validation errors when fields are empty',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await settle(tester);

      // Tap Sign In directly
      await tester.tap(find.byKey(const Key('signInButton')));
      await settle(tester);

      // Check validation error messages
      expect(find.text('Identifier is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await settle(tester);

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await settle(tester);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
