import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/student/bloc/student_features_bloc.dart';
import 'package:mobile/features/student/bloc/student_features_event.dart';
import 'package:mobile/features/student/bloc/student_features_state.dart';
import 'package:mobile/features/student/models/student_features_model.dart';
import 'package:mobile/features/student/repository/student_features_repository.dart';
import 'package:mobile/features/student/presentation/views/student_notices_view.dart';
import 'package:mobile/features/student/presentation/views/student_fees_view.dart';
import 'package:mobile/features/student/presentation/views/school_contact_view.dart';
import 'package:mobile/features/student/presentation/views/student_complaints_view.dart';
import 'package:mobile/features/student/presentation/views/student_feedback_view.dart';
import 'package:mobile/features/profiles/bloc/profile_bloc.dart';
import 'package:mobile/features/profiles/bloc/profile_state.dart';
import 'package:mobile/features/profiles/models/student_profile_model.dart';
import 'package:mobile/features/profiles/repository/profile_repository.dart';

class MockStudentFeaturesRepository implements StudentFeaturesRepository {
  List<NoticeModel> notices = [];
  FeeOverviewModel feeOverview = const FeeOverviewModel(
    totalDues: 25000,
    totalPaid: 15000,
    totalOutstanding: 10000,
    fees: [],
  );
  List<FeeReceiptModel> receipts = [];
  List<ComplaintModel> complaints = [];
  List<FeedbackModel> feedbackList = [];
  bool shouldThrow = false;

  final Set<String> dismissedIds = {};

  @override
  DioClient get dioClient => throw UnimplementedError();

  @override
  SecureStorageService? get storageService => null;

  @override
  Future<Set<String>> getLocalDismissedNoticeIds() async => Set<String>.from(dismissedIds);

  @override
  Future<List<NoticeModel>> getNotices() async {
    if (shouldThrow) throw Exception('Failed to load notices');
    return notices.where((n) => !dismissedIds.contains(n.id)).toList();
  }

  @override
  Future<List<NoticeModel>> getTeacherNotices() async {
    if (shouldThrow) throw Exception('Failed to load teacher notices');
    return notices.where((n) => !dismissedIds.contains(n.id)).toList();
  }

  @override
  Future<void> dismissNotice(String noticeId) async {
    dismissedIds.add(noticeId);
  }

  @override
  Future<void> clearAllNotices(List<String> noticeIds) async {
    dismissedIds.addAll(noticeIds);
  }

  @override
  Future<void> restoreDismissedNotices({List<String>? noticeIds}) async {
    if (noticeIds != null && noticeIds.isNotEmpty) {
      dismissedIds.removeAll(noticeIds);
    } else {
      dismissedIds.clear();
    }
  }

  @override
  Future<FeeOverviewModel> getFeesOverview() async {
    if (shouldThrow) throw Exception('Failed to load fees');
    return feeOverview;
  }

  @override
  Future<List<FeeReceiptModel>> getReceipts() async {
    if (shouldThrow) throw Exception('Failed to load receipts');
    return receipts;
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    if (shouldThrow) throw Exception('Failed to load complaints');
    return complaints;
  }

  @override
  Future<ComplaintModel> submitComplaint({
    required String title,
    required String category,
    required String description,
  }) async {
    if (shouldThrow) throw Exception('Failed to submit complaint');
    final c = ComplaintModel(
      id: 'cmp-1',
      title: title,
      category: category,
      description: description,
      status: 'PENDING',
      createdAt: '2026-10-14',
    );
    complaints.add(c);
    return c;
  }

  @override
  Future<List<FeedbackModel>> getFeedback() async {
    if (shouldThrow) throw Exception('Failed to load feedback');
    return feedbackList;
  }

  @override
  Future<FeedbackModel> submitFeedback({
    required String category,
    required int rating,
    required String feedbackText,
  }) async {
    if (shouldThrow) throw Exception('Failed to submit feedback');
    final fb = FeedbackModel(
      id: 'fb-1',
      category: category,
      rating: rating,
      feedbackText: feedbackText,
      createdAt: '2026-10-14',
    );
    feedbackList.add(fb);
    return fb;
  }
}

class MockProfileRepository implements ProfileRepository {
  @override
  DioClient get dioClient => throw UnimplementedError();

  @override
  Future<StudentProfileModel> getStudentProfile() async {
    return const StudentProfileModel(
      id: 'std-1',
      admissionNumber: 'ADM001',
      firstName: 'Student',
      lastName: 'One',
      gender: 'Male',
      dateOfBirth: '2010-05-15',
      admissionDate: '2022-04-01',
      schoolName: 'Apex International School',
      schoolPhone: '+91 9876543210',
      schoolEmail: 'info@apexschool.edu',
      schoolAddress: '123 Education Lane, Knowledge Park',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StudentFeaturesBloc Unit Tests', () {
    late MockStudentFeaturesRepository repo;
    late StudentFeaturesBloc bloc;

    setUp(() {
      repo = MockStudentFeaturesRepository();
      bloc = StudentFeaturesBloc(repository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is StudentFeaturesInitial', () {
      expect(bloc.state, isA<StudentFeaturesInitial>());
    });

    test('emits [StudentFeaturesLoading, StudentNoticesLoaded] on LoadStudentNoticesEvent', () async {
      repo.notices = [
        const NoticeModel(
          id: 'n-1',
          title: 'Annual Sports Day',
          content: 'Sports day will be on Friday.',
          targetRole: 'STUDENT',
          priority: 'URGENT',
          publishedAt: '2026-10-14',
        ),
      ];

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentFeaturesLoading>(),
          isA<StudentNoticesLoaded>().having((s) => s.notices.length, 'count', 1),
        ]),
      );

      bloc.add(const LoadStudentNoticesEvent());
    });

    test('DismissStudentNoticeEvent and RestoreStudentNoticesEvent persist notice dismissal', () async {
      repo.notices = [
        const NoticeModel(
          id: 'n-1',
          title: 'Annual Sports Day',
          content: 'Sports day will be on Friday.',
          targetRole: 'STUDENT',
          priority: 'URGENT',
          publishedAt: '2026-10-14',
        ),
        const NoticeModel(
          id: 'n-2',
          title: 'PTM Schedule',
          content: 'Saturday 9 AM.',
          targetRole: 'STUDENT',
          priority: 'INFO',
          publishedAt: '2026-10-15',
        ),
      ];

      bloc.add(const LoadStudentNoticesEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      expect((bloc.state as StudentNoticesLoaded).notices.length, 2);

      bloc.add(const DismissStudentNoticeEvent('n-1'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect((bloc.state as StudentNoticesLoaded).notices.map((e) => e.id), ['n-2']);

      // Reloading should stay dismissed
      bloc.add(const LoadStudentNoticesEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      expect((bloc.state as StudentNoticesLoaded).notices.map((e) => e.id), ['n-2']);

      // Restoring brings it back
      bloc.add(const RestoreStudentNoticesEvent(noticeIds: ['n-1']));
      await Future.delayed(const Duration(milliseconds: 20));
      expect((bloc.state as StudentNoticesLoaded).notices.length, 2);
    });

    test('emits [StudentFeaturesLoading, StudentFeesLoaded] on LoadStudentFeesEvent', () async {
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentFeaturesLoading>(),
          isA<StudentFeesLoaded>().having((s) => s.overview.totalDues, 'totalDues', 25000),
        ]),
      );

      bloc.add(const LoadStudentFeesEvent());
    });

    test('emits [StudentFeaturesLoading, StudentReceiptsLoaded] on LoadStudentReceiptsEvent', () async {
      repo.receipts = [
        const FeeReceiptModel(
          id: 'rcpt-1',
          receiptNumber: 'RCP-2026-001',
          amountPaid: 15000,
          paymentMode: 'UPI',
          paymentDate: '2026-10-10',
        ),
      ];

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<StudentFeaturesLoading>(),
          isA<StudentReceiptsLoaded>().having((s) => s.receipts.first.receiptNumber, 'receiptNumber', 'RCP-2026-001'),
        ]),
      );

      bloc.add(const LoadStudentReceiptsEvent());
    });
  });

  group('Student Views Widget Tests', () {
    late MockStudentFeaturesRepository repo;

    setUp(() {
      repo = MockStudentFeaturesRepository();
    });

    testWidgets('StudentNoticesView renders notices list correctly', (tester) async {
      repo.notices = [
        const NoticeModel(
          id: 'n-1',
          title: 'Winter Vacation Notice',
          content: 'School closed from Dec 25.',
          targetRole: 'STUDENT',
          priority: 'INFO',
          publishedAt: '2026-10-14',
        ),
      ];

      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentNoticesView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('School & Class Notices'), findsOneWidget);
      expect(find.text('Winter Vacation Notice'), findsOneWidget);
      expect(find.text('School closed from Dec 25.'), findsOneWidget);

      bloc.close();
    });

    testWidgets('StudentFeesView renders fee structure and dues summary', (tester) async {
      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentFeesView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fee Structure & Dues'), findsOneWidget);
      expect(find.text('Fee Receipts'), findsOneWidget);
      expect(find.text('₹25000'), findsOneWidget);
      expect(find.text('₹15000'), findsOneWidget);
      expect(find.text('₹10000'), findsOneWidget);

      bloc.close();
    });

    testWidgets('SchoolContactView renders institutional contact details', (tester) async {
      final profileRepo = MockProfileRepository();
      final profileBloc = ProfileBloc(repository: profileRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: SchoolContactView()),
          ),
        ),
      );

      profileBloc.emit(StudentProfileLoaded(
        await profileRepo.getStudentProfile(),
      ));
      await tester.pump();

      expect(find.text('Apex International School'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('info@apexschool.edu'), findsOneWidget);
      expect(find.text('123 Education Lane, Knowledge Park'), findsOneWidget);

      profileBloc.close();
    });

    testWidgets(
        'StudentComplaintsView retains cached complaints when unrelated StudentFeaturesState arrives',
        (tester) async {
      repo.complaints = [
        const ComplaintModel(
          id: 'cmp-1',
          title: 'Broken Bench in Class',
          category: 'FACILITY',
          description: 'Back row bench leg is loose.',
          status: 'IN_REVIEW',
          resolutionNotes: 'Carpenter assigned.',
          createdAt: '2026-10-15T10:30:00Z',
        ),
      ];

      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentComplaintsView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Broken Bench in Class'), findsOneWidget);
      expect(find.text('Admin Resolution: Carpenter assigned.'), findsOneWidget);

      // Unrelated state on shared StudentFeaturesBloc must NOT blank out Complaints UI
      bloc.emit(const StudentNoticesLoaded([]));
      await tester.pump();

      expect(find.text('Broken Bench in Class'), findsOneWidget);

      bloc.close();
    });

    testWidgets('StudentComplaintsView displays error and Retry button when initial load fails',
        (tester) async {
      repo.shouldThrow = true;
      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentComplaintsView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load complaints'), findsOneWidget);

      bloc.close();
    });

    testWidgets(
        'StudentFeedbackView retains cached feedback when unrelated StudentFeaturesState arrives',
        (tester) async {
      repo.feedbackList = [
        const FeedbackModel(
          id: 'fb-1',
          category: 'TEACHING',
          rating: 5,
          feedbackText: 'Very clear explanations in Physics class.',
          createdAt: '2026-10-16T09:15:00Z',
        ),
      ];

      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentFeedbackView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Very clear explanations in Physics class.'), findsOneWidget);

      // Unrelated state on shared StudentFeaturesBloc must NOT blank out Feedback UI
      bloc.emit(const StudentNoticesLoaded([]));
      await tester.pump();

      expect(find.text('Very clear explanations in Physics class.'), findsOneWidget);

      bloc.close();
    });

    testWidgets('StudentFeedbackView displays error and Retry button when initial load fails',
        (tester) async {
      repo.shouldThrow = true;
      final bloc = StudentFeaturesBloc(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<StudentFeaturesBloc>.value(
            value: bloc,
            child: const Scaffold(body: StudentFeedbackView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load feedback'), findsOneWidget);

      bloc.close();
    });

    testWidgets('SchoolContactView shows error and Retry button when ProfileError is active',
        (tester) async {
      final profileRepo = MockProfileRepository();
      final profileBloc = ProfileBloc(repository: profileRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: SchoolContactView()),
          ),
        ),
      );

      profileBloc.emit(const ProfileError('Unable to fetch school details'));
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Unable to fetch school details'), findsOneWidget);

      profileBloc.close();
    });

    testWidgets('SchoolContactView uses brandingConfig fallbacks and dynamic officeHours',
        (tester) async {
      final profileRepo = MockProfileRepository();
      final profileBloc = ProfileBloc(repository: profileRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: const Scaffold(body: SchoolContactView()),
          ),
        ),
      );

      profileBloc.emit(const StudentProfileLoaded(
        StudentProfileModel(
          id: 'std-2',
          admissionNumber: 'ADM002',
          firstName: 'Riya',
          lastName: 'Kapoor',
          gender: 'Female',
          dateOfBirth: '2011-02-10',
          admissionDate: '2024-04-01',
          schoolName: 'Sunrise Public School',
          brandingConfig: {
            'phone': '+91 9000011111',
            'email': 'help@sunrise.edu',
            'address': '88 Hill Road, Shimla',
            'officeHours': 'Mon-Fri 9:00 AM - 2:00 PM',
          },
        ),
      ));
      await tester.pump();

      expect(find.text('Sunrise Public School'), findsOneWidget);
      expect(find.text('+91 9000011111'), findsOneWidget);
      expect(find.text('help@sunrise.edu'), findsOneWidget);
      expect(find.text('88 Hill Road, Shimla'), findsOneWidget);
      expect(find.text('Mon-Fri 9:00 AM - 2:00 PM'), findsOneWidget);

      profileBloc.close();
    });
  });
}
