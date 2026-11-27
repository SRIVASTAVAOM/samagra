import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/academics/models/classmate_birthday_model.dart';
import 'package:mobile/features/academics/models/student_roster_item.dart';
import 'package:mobile/features/academics/models/subject_model.dart';
import 'package:mobile/features/academics/models/subject_teacher_item.dart';
import 'package:mobile/features/academics/models/teacher_allocation_model.dart';
import 'package:mobile/features/academics/repositories/exams_repository.dart';
import 'package:mobile/features/academics/repository/academics_repository.dart';
import 'package:mobile/features/attendance/repository/attendance_repository.dart';
import 'package:mobile/features/auth/models/user_model.dart';
import 'package:mobile/features/curriculum/repository/curriculum_repository.dart';
import 'package:mobile/features/homework/models/homework_model.dart';
import 'package:mobile/features/homework/repository/homework_repository.dart';
import 'package:mobile/features/leaves/models/staff_leave_model.dart';
import 'package:mobile/features/leaves/repository/leaves_repository.dart';
import 'package:mobile/features/materials/repository/materials_repository.dart';
import 'package:mobile/features/profiles/models/staff_profile_model.dart';
import 'package:mobile/features/profiles/repository/profile_repository.dart';
import 'package:mobile/features/schedule/repository/schedule_repository.dart';
import 'package:mobile/features/student/models/student_features_model.dart';
import 'package:mobile/features/student/repository/student_features_repository.dart';
import 'package:mobile/features/teacher/presentation/teacher_shell.dart';

class _StubAcademicsRepo implements AcademicsRepository {
  bool throwAllocations = false;
  TeacherAllocationsResponse allocations = const TeacherAllocationsResponse(
    homeroom: HomeroomInfo(
      id: 'hr-1',
      classId: 'cls-10',
      className: 'Grade 10',
      sectionId: 'sec-a',
      sectionName: 'Section A',
      studentCount: 1,
    ),
    allocations: [
      TeacherAllocationItem(
        id: 'al-1',
        classId: 'cls-10',
        className: 'Grade 10',
        sectionId: 'sec-a',
        sectionName: 'Section A',
        subjectId: 'sub-math',
        subjectName: 'Mathematics',
        subjectCode: 'MATH10',
        studentCount: 1,
      ),
      TeacherAllocationItem(
        id: 'al-2',
        classId: 'cls-9',
        className: 'Grade 9',
        sectionId: 'sec-b',
        sectionName: 'Section B',
        subjectId: 'sub-sci',
        subjectName: 'Science',
        subjectCode: 'SCI09',
        studentCount: 1,
      ),
    ],
  );

  List<StudentRosterItem> homeroomStudents = const [
    StudentRosterItem(
      id: 'stu-hr-1',
      admissionNumber: 'ADM-001',
      rollNumber: '1',
      firstName: 'Aarav',
      lastName: 'Sharma',
      gender: 'Male',
      emergencyPhone: '+91 9876543210',
      classId: 'cls-10',
      sectionId: 'sec-a',
      className: 'Grade 10',
      sectionName: 'Section A',
    ),
  ];

  List<StudentRosterItem> taughtStudents = const [
    StudentRosterItem(
      id: 'stu-hr-1',
      admissionNumber: 'ADM-001',
      rollNumber: '1',
      firstName: 'Aarav',
      lastName: 'Sharma',
      gender: 'Male',
      classId: 'cls-10',
      sectionId: 'sec-a',
      className: 'Grade 10',
      sectionName: 'Section A',
      subjects: [StudentSubjectTag(id: 'sub-math', name: 'Mathematics', code: 'MATH10')],
      subjectIds: ['sub-math'],
    ),
    StudentRosterItem(
      id: 'stu-sci-2',
      admissionNumber: 'ADM-002',
      rollNumber: '4',
      firstName: 'Riya',
      lastName: 'Verma',
      gender: 'Female',
      classId: 'cls-9',
      sectionId: 'sec-b',
      className: 'Grade 9',
      sectionName: 'Section B',
      subjects: [StudentSubjectTag(id: 'sub-sci', name: 'Science', code: 'SCI09')],
      subjectIds: ['sub-sci'],
    ),
  ];

  @override
  DioClient get dioClient => DioClient(storageService: SecureStorageService());

  @override
  Future<TeacherAllocationsResponse> getTeacherAllocations() async {
    if (throwAllocations) throw Exception('Allocations unavailable');
    return allocations;
  }

  @override
  Future<List<StudentRosterItem>> getClassRoster(String classId, String sectionId) async =>
      homeroomStudents;

  @override
  Future<List<StudentRosterItem>> getMyTeacherRoster() async => taughtStudents;

  @override
  Future<List<ClassmateBirthdayModel>> getClassmatesBirthdays() async => [];

  @override
  Future<List<SubjectModel>> getSubjects({String? classId}) async => [];

  @override
  Future<List<SubjectTeacherItem>> getSubjectTeachers() async => [];
}

class _StubProfileRepo implements ProfileRepository {
  String? lastSubmittedEmergencyPhone;
  String? lastSubmittedRollNumber;

  @override
  DioClient get dioClient => DioClient(storageService: SecureStorageService());

  @override
  Future<StaffProfileModel> getStaffProfile() async => const StaffProfileModel(
        id: 'stf-1',
        employeeCode: 'EMP-1',
        firstName: 'Sunita',
        lastName: 'Sharma',
        gender: 'Female',
        dateOfBirth: '1985-04-10',
        joiningDate: '2016-06-01',
        allocations: [],
      );

  @override
  Future<void> updateStudentProfileByTeacher(
    String studentId, {
    String? rollNumber,
    String? bloodGroup,
    String? emergencyContactPhone,
    String? medicalNotes,
    String? documentUrl,
  }) async {
    lastSubmittedRollNumber = rollNumber;
    lastSubmittedEmergencyPhone = emergencyContactPhone;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubLeavesRepo implements LeavesRepository {
  @override
  DioClient get dioClient => DioClient(storageService: SecureStorageService());

  @override
  Future<List<StaffLeaveModel>> getStaffMyLeaves() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHomeworkRepo implements HomeworkRepository {
  @override
  Future<List<HomeworkModel>> getTeacherMyAssignedHomework() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubExamsRepo implements ExamsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAttendanceRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCurriculumRepo implements CurriculumRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubMaterialsRepo implements MaterialsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubScheduleRepo implements ScheduleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubStudentFeaturesRepo implements StudentFeaturesRepository {
  @override
  Future<List<NoticeModel>> getTeacherNotices() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const teacherUser = UserModel(
    id: 'usr-t1',
    schoolId: 'sch-1',
    identifier: 'teacher1',
    firstName: 'Sunita',
    lastName: 'Sharma',
    roles: ['TEACHER'],
    profileId: 'stf-1',
  );

  Widget buildShell({
    required _StubAcademicsRepo academicsRepo,
    required _StubProfileRepo profileRepo,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AcademicsRepository>.value(value: academicsRepo),
        RepositoryProvider<ProfileRepository>.value(value: profileRepo),
        RepositoryProvider<AttendanceRepository>.value(value: _StubAttendanceRepo()),
        RepositoryProvider<LeavesRepository>.value(value: _StubLeavesRepo()),
        RepositoryProvider<HomeworkRepository>.value(value: _StubHomeworkRepo()),
        RepositoryProvider<CurriculumRepository>.value(value: _StubCurriculumRepo()),
        RepositoryProvider<MaterialsRepository>.value(value: _StubMaterialsRepo()),
        RepositoryProvider<ExamsRepository>.value(value: _StubExamsRepo()),
        RepositoryProvider<ScheduleRepository>.value(value: _StubScheduleRepo()),
        RepositoryProvider<StudentFeaturesRepository>.value(value: _StubStudentFeaturesRepo()),
      ],
      child: const MaterialApp(
        home: TeacherShell(user: teacherUser),
      ),
    );
  }

  group('Teacher School Roster 3 Sub-Views Widget Tests', () {
    testWidgets('Supports Homeroom edit/clear, All Taught Students subject filtering & grouping, and Classes & Sections',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final academicsRepo = _StubAcademicsRepo();
      final profileRepo = _StubProfileRepo();

      await tester.pumpWidget(buildShell(academicsRepo: academicsRepo, profileRepo: profileRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to Classes -> Student Roster
      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();

      expect(find.text('Homeroom'), findsOneWidget);
      expect(find.text('All Taught Students'), findsOneWidget);
      expect(find.text('Classes & Sections'), findsOneWidget);

      // Sub-view 1: Homeroom shows Aarav Sharma with edit icon
      expect(find.text('Aarav Sharma'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Clear emergency phone and save changes
      await tester.enterText(
        find.widgetWithText(TextField, 'Emergency Contact Phone'),
        '',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(profileRepo.lastSubmittedEmergencyPhone, equals(''));

      // Sub-view 2: Switch to All Taught Students
      await tester.tap(find.text('All Taught Students'));
      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Riya Verma'), findsOneWidget);
      expect(find.text('All Subjects'), findsOneWidget);
      expect(find.text('Group by Subject'), findsOneWidget);

      // Filter by Science
      await tester.tap(find.widgetWithText(FilterChip, 'Science (SCI09)'));
      await tester.pumpAndSettle();
      expect(find.text('Riya Verma'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsNothing);

      // Toggle Group by Subject
      await tester.tap(find.widgetWithText(FilterChip, 'Group by Subject'));
      await tester.pumpAndSettle();
      expect(find.text('1 student'), findsOneWidget);

      // Sub-view 3: Switch to Classes & Sections
      await tester.tap(find.text('Classes & Sections'));
      await tester.pumpAndSettle();

      expect(find.text('Grade 10 • Section A'), findsOneWidget);
      expect(find.text('Grade 9 • Section B'), findsOneWidget);
      expect(find.text('Class Teacher'), findsOneWidget);
      expect(find.text('1 Student Enrolled'), findsNWidgets(2));
    });

    testWidgets('Shows Retry card when getTeacherAllocations fails instead of misleading unassigned message',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final academicsRepo = _StubAcademicsRepo()..throwAllocations = true;
      final profileRepo = _StubProfileRepo();

      await tester.pumpWidget(buildShell(academicsRepo: academicsRepo, profileRepo: profileRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();

      expect(find.text('Allocations unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Recover after retry succeeds
      academicsRepo.throwAllocations = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
    });
  });
}
