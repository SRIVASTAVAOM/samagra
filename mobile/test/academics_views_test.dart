import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/academics/bloc/academics_bloc.dart';
import 'package:mobile/features/academics/models/classmate_birthday_model.dart';
import 'package:mobile/features/academics/models/student_roster_item.dart';
import 'package:mobile/features/academics/models/subject_model.dart';
import 'package:mobile/features/academics/models/subject_teacher_item.dart';
import 'package:mobile/features/academics/models/teacher_allocation_model.dart';
import 'package:mobile/features/academics/presentation/student_roster_view.dart';
import 'package:mobile/features/academics/presentation/subject_teachers_view.dart';
import 'package:mobile/features/academics/presentation/subjects_catalog_view.dart';
import 'package:mobile/features/academics/repository/academics_repository.dart';
import 'package:mobile/features/student/presentation/views/student_birthdays_view.dart';

class _TestBirthdaysAcademicsRepo implements AcademicsRepository {
  List<ClassmateBirthdayModel> birthdays = [];

  @override
  DioClient get dioClient => throw UnimplementedError();

  @override
  Future<List<ClassmateBirthdayModel>> getClassmatesBirthdays() async => birthdays;

  @override
  Future<List<StudentRosterItem>> getClassRoster(String classId, String sectionId) async => [];

  @override
  Future<List<StudentRosterItem>> getMyTeacherRoster() async => [];

  @override
  Future<List<SubjectTeacherItem>> getSubjectTeachers() async => [];

  @override
  Future<List<SubjectModel>> getSubjects({String? classId}) async => [];

  @override
  Future<TeacherAllocationsResponse> getTeacherAllocations() async =>
      const TeacherAllocationsResponse(allocations: []);
}

void main() {
  group('Academics Views Widget Tests', () {
    testWidgets('StudentRosterView renders student list correctly',
        (tester) async {
      final students = [
        const StudentRosterItem(
          id: 's1',
          admissionNumber: 'ADM2026001',
          rollNumber: '101',
          firstName: 'Aarav',
          lastName: 'Sharma',
          gender: 'Male',
          bloodGroup: 'O+',
        ),
        const StudentRosterItem(
          id: 's2',
          admissionNumber: 'ADM2026002',
          rollNumber: '102',
          firstName: 'Riya',
          lastName: 'Patel',
          gender: 'Female',
          bloodGroup: 'B+',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentRosterView(students: students),
          ),
        ),
      );

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Riya Patel'), findsOneWidget);
      expect(find.text('Adm: ADM2026001 • Male'), findsOneWidget);
      expect(find.text('Roll 101'), findsOneWidget);
      expect(find.text('2 students enrolled'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('StudentRosterView renders edit action and triggers onEditStudent when canEdit is true',
        (tester) async {
      StudentRosterItem? editedStudent;
      final students = [
        const StudentRosterItem(
          id: 's1',
          admissionNumber: 'ADM2026001',
          rollNumber: '101',
          firstName: 'Aarav',
          lastName: 'Sharma',
          gender: 'Male',
          bloodGroup: 'O+',
          emergencyPhone: '+91 9876543210',
          medicalNotes: 'Asthmatic',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentRosterView(
              students: students,
              canEdit: true,
              onEditStudent: (student) {
                editedStudent = student;
              },
            ),
          ),
        ),
      );

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Emergency: +91 9876543210'), findsOneWidget);
      expect(find.text('Medical: Asthmatic'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(editedStudent, isNotNull);
      expect(editedStudent!.id, 's1');
      expect(editedStudent!.admissionNumber, 'ADM2026001');
    });

    testWidgets('StudentRosterView in isStudentClassmatesMode renders only Name, Roll No, and Birthday',
        (tester) async {
      final students = [
        const StudentRosterItem(
          id: 's1',
          admissionNumber: 'ADM2026001',
          rollNumber: '101',
          firstName: 'Aarav',
          lastName: 'Sharma',
          gender: 'Male',
          bloodGroup: 'O+',
          emergencyPhone: '+91 9876543210',
          medicalNotes: 'Asthmatic',
          dateOfBirth: '2009-08-15',
          birthdayFormatted: '15 Aug 2009',
        ),
        const StudentRosterItem(
          id: 's2',
          firstName: 'Riya',
          lastName: 'Patel',
          dateOfBirth: '2010-03-04',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentRosterView(
              students: students,
              canEdit: true,
              isStudentClassmatesMode: true,
            ),
          ),
        ),
      );

      expect(find.text('2 classmates'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Roll No: 101'), findsOneWidget);
      expect(find.text('Birthday: 15 Aug 2009'), findsOneWidget);

      expect(find.text('Riya Patel'), findsOneWidget);
      expect(find.text('Roll No: -'), findsOneWidget);
      expect(find.text('Birthday: 04 Mar 2010'), findsOneWidget);

      // Clutter and sensitive fields must stay hidden
      expect(find.textContaining('ADM2026001'), findsNothing);
      expect(find.textContaining('Male'), findsNothing);
      expect(find.textContaining('Blood:'), findsNothing);
      expect(find.textContaining('Emergency:'), findsNothing);
      expect(find.textContaining('Medical:'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('SubjectTeachersView renders class teacher, subject cards, qualification, and UserAvatar',
        (tester) async {
      final teachers = [
        const SubjectTeacherItem(
          subjectId: 'HOMEROOM',
          subjectName: 'Class Teacher (Homeroom)',
          subjectCode: 'HOMEROOM',
          teacherName: 'Sunita Sharma',
          qualification: 'M.Sc, B.Ed',
          teacherPhone: '+91 9811122233',
          isClassTeacher: true,
        ),
        const SubjectTeacherItem(
          subjectId: 'sub-1',
          subjectName: 'Mathematics',
          subjectCode: 'MATH10',
          teacherName: 'Vikram Mehta',
          teacherPhone: '+91 9876543210',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectTeachersView(teachers: teachers),
          ),
        ),
      );

      expect(find.text('Class Teacher (Homeroom)'), findsOneWidget);
      expect(find.text('CLASS TEACHER'), findsOneWidget);
      expect(find.text('Teacher: Sunita Sharma'), findsOneWidget);
      expect(find.text('M.Sc, B.Ed'), findsOneWidget);
      expect(find.text('SS'), findsOneWidget);

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('MATH10'), findsOneWidget);
      expect(find.text('Teacher: Vikram Mehta'), findsOneWidget);
      expect(find.text('Contact: +91 9876543210'), findsOneWidget);
      expect(find.text('VM'), findsOneWidget);
    });

    testWidgets('SubjectsCatalogView renders subject list', (tester) async {
      final subjects = [
        const SubjectModel(
          id: '1',
          code: 'SCI10',
          name: 'Science',
          type: 'CORE',
          creditHours: 4,
          isActive: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectsCatalogView(subjects: subjects),
          ),
        ),
      );

      expect(find.text('Science'), findsOneWidget);
      expect(find.text('SCI10'), findsOneWidget);
      expect(find.text('Type: CORE • Credit Hours: 4'), findsOneWidget);
    });

    testWidgets('StudentBirthdaysView renders today birthdays cleanly without Adm clutter',
        (tester) async {
      final repo = _TestBirthdaysAcademicsRepo()
        ..birthdays = [
          const ClassmateBirthdayModel(
            id: 'b1',
            admissionNumber: 'ADM2026002',
            rollNumber: '102',
            firstName: 'Riya',
            lastName: 'Patel',
            birthMonth: 11,
            birthDay: 27,
            birthdayFormatted: '27 Nov',
          ),
        ];

      final bloc = AcademicsBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AcademicsBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: StudentBirthdaysView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text("Today's Birthdays"), findsOneWidget);
      expect(find.text('Riya Patel'), findsOneWidget);
      expect(find.text('RP'), findsOneWidget);
      expect(find.text('Roll No: 102'), findsOneWidget);
      expect(find.text('27 Nov'), findsOneWidget);
      expect(find.textContaining('ADM2026002'), findsNothing);
    });

    testWidgets('StudentBirthdaysView renders empty state when no birthday today',
        (tester) async {
      final repo = _TestBirthdaysAcademicsRepo()..birthdays = [];
      final bloc = AcademicsBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AcademicsBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: StudentBirthdaysView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('No classmates have a birthday today'), findsOneWidget);
    });

    testWidgets('StudentRosterView displays class/section badge, subject tags, and clears search cleanly',
        (tester) async {
      final students = [
        const StudentRosterItem(
          id: 's1',
          admissionNumber: 'ADM2026001',
          rollNumber: '12',
          firstName: 'Aarav',
          lastName: 'Sharma',
          gender: 'Male',
          className: 'Grade 10',
          sectionName: 'Section A',
          subjects: [
            StudentSubjectTag(id: 'sub-1', name: 'Mathematics', code: 'MATH10'),
          ],
          subjectIds: ['sub-1'],
        ),
        const StudentRosterItem(
          id: 's2',
          admissionNumber: 'ADM2026002',
          rollNumber: '14',
          firstName: '',
          lastName: '',
          gender: 'Female',
          className: 'Grade 10',
          sectionName: 'Section B',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentRosterView(
              students: students,
              showClassSectionBadge: true,
              showSubjectTags: true,
            ),
          ),
        ),
      );

      expect(find.text('Grade 10 • Section A • Adm: ADM2026001 • Male'), findsOneWidget);
      expect(find.text('Mathematics (MATH10)'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Aarav');
      await tester.pump();
      expect(find.text('1 students enrolled'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('2 students enrolled'), findsOneWidget);
    });
  });
}
