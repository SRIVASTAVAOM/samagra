import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../academics/bloc/academics_bloc.dart';
import '../../academics/bloc/academics_event.dart';
import '../../academics/bloc/academics_state.dart';
import '../../academics/models/student_roster_item.dart';
import '../../academics/presentation/student_roster_view.dart';
import '../../academics/repository/academics_repository.dart';
import '../../attendance/bloc/attendance_bloc.dart';
import '../../attendance/presentation/teacher_attendance_marking_view.dart';
import '../../attendance/presentation/teacher_own_attendance_view.dart';
import '../../attendance/repository/attendance_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/user_model.dart';
import '../../curriculum/bloc/curriculum_bloc.dart';
import '../../curriculum/presentation/curriculum_view.dart';
import '../../curriculum/repository/curriculum_repository.dart';
import '../../homework/bloc/homework_bloc.dart';
import '../../homework/presentation/teacher_homework_manage_view.dart';
import '../../homework/repository/homework_repository.dart';
import '../../leaves/bloc/leaves_bloc.dart';
import '../../leaves/bloc/leaves_event.dart';
import '../../leaves/presentation/teacher_leave_view.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../materials/bloc/materials_bloc.dart';
import '../../materials/presentation/academic_materials_view.dart';
import '../../materials/repository/materials_repository.dart';
import '../../profiles/bloc/profile_bloc.dart';
import '../../profiles/bloc/profile_event.dart';
import '../../profiles/presentation/teacher_profile_view.dart';
import '../../profiles/repository/profile_repository.dart';
import '../../academics/bloc/exams_bloc.dart';
import '../../academics/models/teacher_allocation_model.dart';
import '../../academics/repositories/exams_repository.dart';
import '../../academics/views/exams_list_view.dart';
import '../../student/presentation/views/student_birthdays_view.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../schedule/presentation/teacher_timetable_view.dart';
import '../../schedule/presentation/teacher_substitutions_view.dart';
import '../../schedule/presentation/teacher_online_classes_view.dart';
import '../../schedule/repository/schedule_repository.dart';
import 'views/teacher_dashboard_view.dart';

class TeacherShell extends StatefulWidget {
  final UserModel user;

  const TeacherShell({super.key, required this.user});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _selectedIndex = 0;
  int _attendanceSubTab = 0; // 0: Mark Class, 1: My Own Attendance
  int _classesSubTab = 0; // 0: Roster, 1: Homework, 2: Materials, 3: Syllabus, 4: Exams, 5: Update Student Details
  int _leavesInitialTab = 0; // 0: My Leaves, 1: Student Leave Requests
  int _rosterSegment = 0; // 0: Homeroom, 1: All Taught Students, 2: Classes & Sections
  String? _selectedClassSectionFilter; // e.g. '${classId}-${sectionId}' for All Taught view
  String? _selectedSubjectFilter; // subjectId for All Taught view
  bool _groupBySubject = false;

  TeacherAllocationsResponse? _allocations;
  String? _allocationsError;
  TeacherAllocationItem? _selectedAllocation;
  bool _isLoadingAllocations = true;
  AcademicsBloc? _academicsBloc;
  List<StudentRosterItem>? _homeroomRosterCache;
  List<StudentRosterItem>? _taughtRosterCache;
  String? _homeroomRosterError;
  String? _taughtRosterError;
  int? _activeRosterLoadSegment;

  void _navigateToTab(int tabIndex, {int? attendanceSubTab, int? classesSubTab, int? leavesSubTab}) {
    setState(() {
      _selectedIndex = tabIndex;
      if (attendanceSubTab != null) _attendanceSubTab = attendanceSubTab;
      if (classesSubTab != null) _classesSubTab = classesSubTab;
      if (leavesSubTab != null) _leavesInitialTab = leavesSubTab;
    });
  }

  @override
  void initState() {
    super.initState();
    _academicsBloc = AcademicsBloc(
      repository: context.read<AcademicsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllocations();
    });
  }

  @override
  void dispose() {
    _academicsBloc?.close();
    super.dispose();
  }

  Future<void> _loadAllocations({bool reloadRoster = true}) async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoadingAllocations = true;
        _allocationsError = null;
      });
      final repo = context.read<AcademicsRepository>();
      final res = await repo.getTeacherAllocations();
      if (mounted) {
        setState(() {
          _allocations = res;
          if (res.allocations.isNotEmpty) {
            _selectedAllocation ??= res.allocations.first;
          }
          if (_rosterSegment == 0 && (res.homeroom == null || res.homeroom!.classId.isEmpty)) {
            _rosterSegment = 1;
          }
          _isLoadingAllocations = false;
        });
        if (reloadRoster) {
          if (_rosterSegment == 0 && res.homeroom != null && res.homeroom!.classId.isNotEmpty) {
            _loadHomeroomRoster(force: true);
          } else {
            _loadTaughtRoster(force: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allocationsError = e.toString().replaceAll('Exception: ', '');
          _isLoadingAllocations = false;
        });
      }
    }
  }

  void _loadHomeroomRoster({bool force = false}) {
    final homeroom = _allocations?.homeroom;
    if (homeroom == null || homeroom.classId.isEmpty || homeroom.sectionId.isEmpty) return;
    if (!force && _homeroomRosterCache != null) return;
    setState(() {
      _activeRosterLoadSegment = 0;
      _homeroomRosterError = null;
    });
    _academicsBloc?.add(
      LoadClassRosterEvent(
        classId: homeroom.classId,
        sectionId: homeroom.sectionId,
      ),
    );
  }

  void _loadTaughtRoster({bool force = false}) {
    if (!force && _taughtRosterCache != null) return;
    setState(() {
      _activeRosterLoadSegment = 1;
      _taughtRosterError = null;
    });
    _academicsBloc?.add(LoadTeacherRosterEvent());
  }

  List<({String classId, String sectionId, String label})> get _distinctClassSections {
    final result = <({String classId, String sectionId, String label})>[];
    final seen = <String>{};
    final homeroom = _allocations?.homeroom;
    if (homeroom != null && homeroom.classId.isNotEmpty && homeroom.sectionId.isNotEmpty) {
      final hKey = '${homeroom.classId}-${homeroom.sectionId}';
      seen.add(hKey);
      result.add((
        classId: homeroom.classId,
        sectionId: homeroom.sectionId,
        label: '${homeroom.className} ${homeroom.sectionName}',
      ));
    }
    for (final a in (_allocations?.allocations ?? const <TeacherAllocationItem>[])) {
      final key = '${a.classId}-${a.sectionId}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add((classId: a.classId, sectionId: a.sectionId, label: '${a.className} ${a.sectionName}'));
      }
    }
    return result;
  }

  List<({String id, String name, String code})> get _distinctSubjects {
    final result = <({String id, String name, String code})>[];
    final seen = <String>{};
    for (final a in (_allocations?.allocations ?? const <TeacherAllocationItem>[])) {
      if (a.subjectId.isNotEmpty && !seen.contains(a.subjectId)) {
        seen.add(a.subjectId);
        result.add((id: a.subjectId, name: a.subjectName, code: a.subjectCode));
      }
    }
    for (final s in (_taughtRosterCache ?? const <StudentRosterItem>[])) {
      for (final sub in s.subjects) {
        if (sub.id.isNotEmpty && !seen.contains(sub.id)) {
          seen.add(sub.id);
          result.add((id: sub.id, name: sub.name, code: sub.code));
        }
      }
    }
    return result;
  }

  List<({
    String classId,
    String sectionId,
    String className,
    String sectionName,
    bool isHomeroom,
    int? studentCount,
    List<({String id, String name, String code})> subjects,
  })> get _classSectionSummaries {
    final map = <String, ({
      String classId,
      String sectionId,
      String className,
      String sectionName,
      bool isHomeroom,
      int? studentCount,
      List<({String id, String name, String code})> subjects,
    })>{};

    final homeroom = _allocations?.homeroom;
    if (homeroom != null && homeroom.classId.isNotEmpty && homeroom.sectionId.isNotEmpty) {
      final key = '${homeroom.classId}-${homeroom.sectionId}';
      map[key] = (
        classId: homeroom.classId,
        sectionId: homeroom.sectionId,
        className: homeroom.className,
        sectionName: homeroom.sectionName,
        isHomeroom: true,
        studentCount: homeroom.studentCount,
        subjects: [],
      );
    }

    for (final a in (_allocations?.allocations ?? const <TeacherAllocationItem>[])) {
      final key = '${a.classId}-${a.sectionId}';
      final existing = map[key];
      final subjectEntry = (id: a.subjectId, name: a.subjectName, code: a.subjectCode);
      if (existing == null) {
        map[key] = (
          classId: a.classId,
          sectionId: a.sectionId,
          className: a.className,
          sectionName: a.sectionName,
          isHomeroom: false,
          studentCount: a.studentCount,
          subjects: [subjectEntry],
        );
      } else {
        if (!existing.subjects.any((s) => s.id == a.subjectId)) {
          existing.subjects.add(subjectEntry);
        }
        if (existing.studentCount == null && a.studentCount != null) {
          map[key] = (
            classId: existing.classId,
            sectionId: existing.sectionId,
            className: existing.className,
            sectionName: existing.sectionName,
            isHomeroom: existing.isHomeroom,
            studentCount: a.studentCount,
            subjects: existing.subjects,
          );
        }
      }
    }

    return map.values.toList();
  }

  String? get _attendanceClassId {
    if (_allocations?.homeroom != null && _allocations!.homeroom!.classId.isNotEmpty) {
      return _allocations!.homeroom!.classId;
    }
    if (widget.user.classId != null && widget.user.classId!.isNotEmpty) {
      return widget.user.classId;
    }
    if (_allocations?.allocations.isNotEmpty == true) {
      return _allocations!.allocations.first.classId;
    }
    return null;
  }

  String? get _attendanceSectionId {
    if (_allocations?.homeroom != null && _allocations!.homeroom!.sectionId.isNotEmpty) {
      return _allocations!.homeroom!.sectionId;
    }
    if (widget.user.sectionId != null && widget.user.sectionId!.isNotEmpty) {
      return widget.user.sectionId;
    }
    if (_allocations?.allocations.isNotEmpty == true) {
      return _allocations!.allocations.first.sectionId;
    }
    return null;
  }

  String get _attendanceClassName {
    if (_allocations?.homeroom != null && _allocations!.homeroom!.className.isNotEmpty) {
      return _allocations!.homeroom!.className;
    }
    if (_allocations?.allocations.isNotEmpty == true) {
      return _allocations!.allocations.first.className;
    }
    return 'Assigned Class';
  }

  String get _attendanceSectionName {
    if (_allocations?.homeroom != null && _allocations!.homeroom!.sectionName.isNotEmpty) {
      return _allocations!.homeroom!.sectionName;
    }
    if (_allocations?.allocations.isNotEmpty == true) {
      return _allocations!.allocations.first.sectionName;
    }
    return 'Section';
  }

  String? get _activeClassId =>
      _selectedAllocation?.classId ?? widget.user.classId;

  String? get _activeSectionId =>
      _selectedAllocation?.sectionId ?? widget.user.sectionId;

  String? get _activeSubjectId =>
      _selectedAllocation?.subjectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: _academicsBloc!,
        ),
        BlocProvider(
          create: (ctx) => ProfileBloc(
            repository: ctx.read<ProfileRepository>(),
          )..add(LoadStaffProfileEvent()),
        ),
        BlocProvider(
          create: (ctx) => AttendanceBloc(
            repository: ctx.read<AttendanceRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => LeavesBloc(
            repository: ctx.read<LeavesRepository>(),
          )..add(const LoadStaffMyLeavesEvent()),
        ),
        BlocProvider(
          create: (ctx) => HomeworkBloc(
            ctx.read<HomeworkRepository>(),
          )..add(const LoadTeacherHomeworkEvent()),
        ),
        BlocProvider(
          create: (ctx) => CurriculumBloc(
            ctx.read<CurriculumRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => MaterialsBloc(
            ctx.read<MaterialsRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => ExamsBloc(
            repository: ctx.read<ExamsRepository>(),
          )..add(const LoadExamsEvent()),
        ),
        BlocProvider(
          create: (ctx) => ScheduleBloc(
            repository: ctx.read<ScheduleRepository>(),
          ),
        ),
      ],
      child: BlocListener<AcademicsBloc, AcademicsState>(
        listener: (context, state) {
          if (state is RosterLoaded) {
            setState(() {
              if (_activeRosterLoadSegment == 0) {
                _homeroomRosterCache = state.students;
                _homeroomRosterError = null;
              } else if (_activeRosterLoadSegment == 1) {
                _taughtRosterCache = state.students;
                _taughtRosterError = null;
              }
            });
          } else if (state is AcademicsError) {
            setState(() {
              if (_activeRosterLoadSegment == 0) {
                _homeroomRosterError = state.message;
              } else if (_activeRosterLoadSegment == 1) {
                _taughtRosterError = state.message;
              }
            });
          }
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10, right: 2),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              leadingWidth: 44,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.displayName),
                  Text(
                    _allocations?.homeroom != null
                        ? 'Teacher Portal • Class Teacher: ${_allocations!.homeroom!.className} ${_allocations!.homeroom!.sectionName}'
                        : 'Teacher Portal • Subject Teacher',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout,
                      size: 20, color: AppColors.secondaryText),
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequestedEvent());
                  },
                ),
              ],
            ),
            body: _buildCurrentTab(context),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.0)),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) =>
                    setState(() => _selectedIndex = idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_circle_outline),
                    selectedIcon: Icon(Icons.check_circle),
                    label: 'Attendance',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.class_outlined),
                    selectedIcon: Icon(Icons.class_),
                    label: 'Classes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.beach_access_outlined),
                    selectedIcon: Icon(Icons.beach_access),
                    label: 'Leaves',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return TeacherDashboardView(
          user: widget.user,
          allocations: _allocations,
          onNavigateToTab: _navigateToTab,
        );
      case 1:
        return _buildAttendanceTab(context);
      case 2:
        return _buildClassesTab(context);
      case 3:
        return TeacherLeaveView(
          key: ValueKey('teacher-leaves-$_leavesInitialTab'),
          initialTab: _leavesInitialTab,
        );
      case 4:
      default:
        return const TeacherProfileView();
    }
  }

  Widget _buildAttendanceTab(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildSubTabButton(
                title: 'Mark Class Attendance',
                isSelected: _attendanceSubTab == 0,
                onTap: () => setState(() => _attendanceSubTab = 0),
              ),
              const SizedBox(width: 8),
              _buildSubTabButton(
                title: 'My Own Attendance',
                isSelected: _attendanceSubTab == 1,
                onTap: () => setState(() => _attendanceSubTab = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: _attendanceSubTab == 0
              ? (_attendanceClassId != null && _attendanceSectionId != null
                  ? TeacherAttendanceMarkingView(
                      key: ValueKey('att-$_attendanceClassId-$_attendanceSectionId'),
                      classId: _attendanceClassId!,
                      sectionId: _attendanceSectionId!,
                      className: _attendanceClassName,
                      sectionName: _attendanceSectionName,
                    )
                  : _buildNoAssignmentCard(
                      'No homeroom or class assigned for attendance marking.\nContact school administration to assign your class.',
                    ))
              : const TeacherOwnAttendanceView(),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryText
              : AppColors.scaffoldBackground,
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

  Widget _buildAllocationSelectorChips(BuildContext context) {
    if (_isLoadingAllocations) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final list = _allocations?.allocations ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: list.map((item) {
            final isSelected = _selectedAllocation?.id == item.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  '${item.className} ${item.sectionName} • ${item.subjectName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.surface : AppColors.primaryText,
                  ),
                ),
                selected: isSelected,
                backgroundColor: AppColors.scaffoldBackground,
                selectedColor: AppColors.primaryText,
                checkmarkColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryText : AppColors.border,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedAllocation = item);
                    if (_classesSubTab == 2) {
                      context.read<MaterialsBloc>().add(
                            LoadClassMaterialsEvent(item.classId, item.subjectId),
                          );
                    } else if (_classesSubTab == 3) {
                      context.read<CurriculumBloc>().add(
                            LoadCurriculumUnitsEvent(item.classId, item.subjectId),
                          );
                    }
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoAssignmentCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTab(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton(
                  title: 'Student Roster',
                  isSelected: _classesSubTab == 0,
                  onTap: () {
                    setState(() => _classesSubTab = 0);
                    if (_rosterSegment == 0) {
                      _loadHomeroomRoster();
                    } else if (_rosterSegment == 1) {
                      _loadTaughtRoster();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Update Student Details',
                  isSelected: _classesSubTab == 5,
                  onTap: () {
                    setState(() {
                      _classesSubTab = 5;
                      _rosterSegment = 0;
                    });
                    _loadHomeroomRoster();
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Homework',
                  isSelected: _classesSubTab == 1,
                  onTap: () {
                    setState(() => _classesSubTab = 1);
                    context.read<HomeworkBloc>().add(
                          const LoadTeacherHomeworkEvent(),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Study Materials',
                  isSelected: _classesSubTab == 2,
                  onTap: () {
                    setState(() => _classesSubTab = 2);
                    final cId = _activeClassId ?? '';
                    final sId = _activeSubjectId ?? '';
                    if (cId.isNotEmpty && sId.isNotEmpty) {
                      context.read<MaterialsBloc>().add(
                            LoadClassMaterialsEvent(cId, sId),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Syllabus & Topics',
                  isSelected: _classesSubTab == 3,
                  onTap: () {
                    setState(() => _classesSubTab = 3);
                    final cId = _activeClassId ?? '';
                    final sId = _activeSubjectId ?? '';
                    if (cId.isNotEmpty && sId.isNotEmpty) {
                      context.read<CurriculumBloc>().add(
                            LoadCurriculumUnitsEvent(cId, sId),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Examinations',
                  isSelected: _classesSubTab == 4,
                  onTap: () {
                    setState(() => _classesSubTab = 4);
                    context.read<ExamsBloc>().add(const LoadExamsEvent());
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'My Timetable',
                  isSelected: _classesSubTab == 6,
                  onTap: () {
                    setState(() => _classesSubTab = 6);
                    context.read<ScheduleBloc>().add(const LoadTeacherTimetableEvent());
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Substitutions',
                  isSelected: _classesSubTab == 7,
                  onTap: () {
                    setState(() => _classesSubTab = 7);
                    context.read<ScheduleBloc>().add(const LoadTeacherSubstitutionsEvent());
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Online Classes',
                  isSelected: _classesSubTab == 8,
                  onTap: () {
                    setState(() => _classesSubTab = 8);
                    context.read<ScheduleBloc>().add(const LoadOnlineClassesEvent());
                  },
                ),
                if (_allocations?.homeroom != null) ...[
                  const SizedBox(width: 8),
                  _buildSubTabButton(
                    title: 'Birthdays',
                    isSelected: _classesSubTab == 9,
                    onTap: () => setState(() => _classesSubTab = 9),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_classesSubTab == 9) {
                if (_allocations?.homeroom == null) {
                  return _buildNoAssignmentCard(
                    'Class birthdays are available only for Class Teachers assigned to a homeroom.',
                  );
                }
                final hr = _allocations!.homeroom!;
                return BlocProvider<AcademicsBloc>(
                  create: (ctx) => AcademicsBloc(
                    repository: ctx.read<AcademicsRepository>(),
                  )..add(LoadClassmatesBirthdaysEvent()),
                  child: StudentBirthdaysView(
                    key: ValueKey('teacher-bday-${hr.classId}-${hr.sectionId}'),
                    title: "${hr.className} ${hr.sectionName} Today's Birthdays",
                    emptyMessage: 'No students in your homeroom have a birthday today',
                    autoLoad: false,
                  ),
                );
              }
              if (_classesSubTab == 6) {
                return const TeacherTimetableView();
              }
              if (_classesSubTab == 7) {
                return const TeacherSubstitutionsView();
              }
              if (_classesSubTab == 8) {
                return const TeacherOnlineClassesView();
              }
              if (_classesSubTab == 1) {
                return Column(
                  children: [
                    _buildAllocationSelectorChips(context),
                    Expanded(
                      child: TeacherHomeworkManageView(
                        key: ValueKey('hw-$_activeClassId-$_activeSectionId-$_activeSubjectId'),
                        classId: _activeClassId,
                        sectionId: _activeSectionId,
                        subjectId: _activeSubjectId,
                      ),
                    ),
                  ],
                );
              }
              if (_classesSubTab == 2) {
                if (_activeClassId == null || _activeSubjectId == null) {
                  return _buildNoAssignmentCard('No subject allocated to load study materials.');
                }
                return Column(
                  children: [
                    _buildAllocationSelectorChips(context),
                    Expanded(
                      child: AcademicMaterialsView(
                        key: ValueKey('mat-$_activeClassId-$_activeSubjectId'),
                        classId: _activeClassId!,
                        subjectId: _activeSubjectId!,
                      ),
                    ),
                  ],
                );
              }
              if (_classesSubTab == 3) {
                if (_activeClassId == null || _activeSubjectId == null) {
                  return _buildNoAssignmentCard('No subject allocated to load syllabus & topics.');
                }
                return Column(
                  children: [
                    _buildAllocationSelectorChips(context),
                    Expanded(
                      child: CurriculumView(
                        key: ValueKey('curr-$_activeClassId-$_activeSubjectId'),
                        classId: _activeClassId!,
                        subjectId: _activeSubjectId!,
                      ),
                    ),
                  ],
                );
              }
              if (_classesSubTab == 4) {
                return Column(
                  children: [
                    _buildAllocationSelectorChips(context),
                    Expanded(
                      child: ExamsListView(
                        key: ValueKey('exam-$_activeClassId-$_activeSectionId'),
                        userRole: 'TEACHER',
                        classId: _activeClassId,
                        sectionId: _activeSectionId,
                      ),
                    ),
                  ],
                );
              }

              // ClassesSubTab 0 (Student Roster) and 5 (Update Student Details)
              return _buildRosterSection(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRosterSection(BuildContext context) {
    final isDetailsTab = _classesSubTab == 5;
    final effectiveSegment = isDetailsTab ? 0 : _rosterSegment;

    return Column(
      children: [
        if (isDetailsTab && _allocations?.homeroom != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Class Teacher Edit Mode (${_allocations!.homeroom!.className} ${_allocations!.homeroom!.sectionName}): Tap the edit icon next to any student to update roll number, blood group, emergency contact, or medical notes.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
        if (!isDetailsTab)
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSubTabButton(
                    title: 'Homeroom',
                    isSelected: _rosterSegment == 0,
                    onTap: () {
                      setState(() {
                        _rosterSegment = 0;
                        _selectedClassSectionFilter = null;
                        _selectedSubjectFilter = null;
                      });
                      _loadHomeroomRoster();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildSubTabButton(
                    title: 'All Taught Students',
                    isSelected: _rosterSegment == 1,
                    onTap: () {
                      setState(() {
                        _rosterSegment = 1;
                      });
                      _loadTaughtRoster();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildSubTabButton(
                    title: 'Classes & Sections',
                    isSelected: _rosterSegment == 2,
                    onTap: () {
                      setState(() {
                        _rosterSegment = 2;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: BlocBuilder<AcademicsBloc, AcademicsState>(
            builder: (context, state) {
              if (effectiveSegment == 2) {
                return _buildClassesSectionsBody(context);
              }
              if (effectiveSegment == 0) {
                return _buildHomeroomRosterBody(context, state);
              }
              return _buildTaughtRosterBody(context, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationsErrorCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _loadAllocations(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeroomRosterBody(BuildContext context, AcademicsState state) {
    if (_isLoadingAllocations && _allocations == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_allocationsError != null && _allocations == null) {
      return _buildAllocationsErrorCard(_allocationsError!);
    }

    final homeroom = _allocations?.homeroom;
    if (homeroom == null) {
      return _buildNoAssignmentCard(
        'You are not currently assigned as a Class Teacher for any homeroom.\nHomeroom roster and details editing are only available for Class Teachers.',
      );
    }

    final isLoading =
        state is AcademicsLoading && _activeRosterLoadSegment == 0 && _homeroomRosterCache == null;
    final errorMsg = _homeroomRosterCache == null ? _homeroomRosterError : null;
    final students = _homeroomRosterCache ?? const <StudentRosterItem>[];

    return StudentRosterView(
      key: const ValueKey('teacher-roster-homeroom'),
      title: '${homeroom.className} ${homeroom.sectionName} Homeroom Roster',
      students: students,
      isLoading: isLoading,
      errorMessage: errorMsg,
      onRetry: () => _loadHomeroomRoster(force: true),
      onRefresh: () async {
        _loadHomeroomRoster(force: true);
        await Future.delayed(const Duration(milliseconds: 250));
      },
      canEdit: true,
      emptyMessage: 'No students are enrolled in your homeroom class yet.',
      onEditStudent: (student) => _openEditStudentDetailsDialog(context, student),
    );
  }

  List<StudentRosterItem> _filterTaughtStudents(List<StudentRosterItem> source) {
    final allocsForSubject = _selectedSubjectFilter == null
        ? const <String>{}
        : (_allocations?.allocations ?? [])
            .where((a) => a.subjectId == _selectedSubjectFilter)
            .map((a) => '${a.classId}-${a.sectionId}')
            .toSet();

    return source.where((s) {
      if (_selectedClassSectionFilter != null) {
        if (s.classId == null || s.sectionId == null) return false;
        if ('${s.classId}-${s.sectionId}' != _selectedClassSectionFilter) return false;
      }
      if (_selectedSubjectFilter != null) {
        if (s.subjectIds.isNotEmpty) {
          if (!s.subjectIds.contains(_selectedSubjectFilter)) return false;
        } else {
          final csKey = '${s.classId ?? ''}-${s.sectionId ?? ''}';
          if (!allocsForSubject.contains(csKey)) return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildTaughtRosterBody(BuildContext context, AcademicsState state) {
    if (_isLoadingAllocations && _allocations == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_allocationsError != null && _allocations == null && _taughtRosterCache == null) {
      return _buildAllocationsErrorCard(_allocationsError!);
    }

    final subjects = _distinctSubjects;
    final classSections = _distinctClassSections;
    final isLoading =
        state is AcademicsLoading && _activeRosterLoadSegment == 1 && _taughtRosterCache == null;
    final errorMsg = _taughtRosterCache == null ? _taughtRosterError : null;
    final rawStudents = _taughtRosterCache ?? const <StudentRosterItem>[];
    final filtered = _filterTaughtStudents(rawStudents);

    return Column(
      children: [
        if (subjects.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('All Subjects', style: TextStyle(fontSize: 11)),
                      selected: _selectedSubjectFilter == null,
                      onSelected: (val) {
                        if (val) setState(() => _selectedSubjectFilter = null);
                      },
                      backgroundColor: AppColors.scaffoldBackground,
                      selectedColor: AppColors.primaryText,
                      checkmarkColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _selectedSubjectFilter == null
                            ? AppColors.surface
                            : AppColors.primaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...subjects.map((sub) {
                    final isSel = _selectedSubjectFilter == sub.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          sub.code.isNotEmpty ? '${sub.name} (${sub.code})' : sub.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: isSel,
                        onSelected: (val) {
                          setState(() {
                            _selectedSubjectFilter = val ? sub.id : null;
                          });
                        },
                        backgroundColor: AppColors.scaffoldBackground,
                        selectedColor: AppColors.primaryText,
                        checkmarkColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.surface : AppColors.primaryText,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      avatar: Icon(
                        Icons.view_agenda_outlined,
                        size: 14,
                        color: _groupBySubject ? AppColors.surface : AppColors.primaryAccent,
                      ),
                      label: const Text('Group by Subject', style: TextStyle(fontSize: 11)),
                      selected: _groupBySubject,
                      onSelected: (val) => setState(() => _groupBySubject = val),
                      backgroundColor: AppColors.indigo50,
                      selectedColor: AppColors.primaryAccent,
                      checkmarkColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _groupBySubject ? AppColors.surface : AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (classSections.isNotEmpty)
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('All Classes', style: TextStyle(fontSize: 11)),
                      selected: _selectedClassSectionFilter == null,
                      onSelected: (val) {
                        if (val) setState(() => _selectedClassSectionFilter = null);
                      },
                      backgroundColor: AppColors.scaffoldBackground,
                      selectedColor: AppColors.primaryText,
                      checkmarkColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: _selectedClassSectionFilter == null
                            ? AppColors.surface
                            : AppColors.primaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...classSections.map((cs) {
                    final key = '${cs.classId}-${cs.sectionId}';
                    final isSel = _selectedClassSectionFilter == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cs.label, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        onSelected: (val) {
                          setState(() {
                            _selectedClassSectionFilter = val ? key : null;
                          });
                        },
                        backgroundColor: AppColors.scaffoldBackground,
                        selectedColor: AppColors.primaryText,
                        checkmarkColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.surface : AppColors.primaryText,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        Expanded(
          child: _groupBySubject && !isLoading && errorMsg == null && subjects.isNotEmpty
              ? _buildGroupedBySubjectList(context, filtered, subjects)
              : StudentRosterView(
                  key: const ValueKey('teacher-roster-taught'),
                  title: 'All Taught Students',
                  students: filtered,
                  isLoading: isLoading,
                  errorMessage: errorMsg,
                  onRetry: () => _loadTaughtRoster(force: true),
                  onRefresh: () async {
                    await _loadAllocations(reloadRoster: false);
                    _loadTaughtRoster(force: true);
                    await Future.delayed(const Duration(milliseconds: 250));
                  },
                  canEdit: false,
                  showClassSectionBadge: true,
                  showSubjectTags: true,
                  emptyMessage: 'No taught students found for the selected filter.',
                ),
        ),
      ],
    );
  }

  Widget _buildGroupedBySubjectList(
    BuildContext context,
    List<StudentRosterItem> filtered,
    List<({String id, String name, String code})> subjects,
  ) {
    final activeSubjects = _selectedSubjectFilter != null
        ? subjects.where((s) => s.id == _selectedSubjectFilter).toList()
        : subjects;

    final groups = <({
      ({String id, String name, String code}) subject,
      List<StudentRosterItem> students,
    })>[];

    for (final sub in activeSubjects) {
      final subClassKeys = (_allocations?.allocations ?? [])
          .where((a) => a.subjectId == sub.id)
          .map((a) => '${a.classId}-${a.sectionId}')
          .toSet();
      final subStudents = filtered.where((s) {
        if (s.subjectIds.isNotEmpty) return s.subjectIds.contains(sub.id);
        return subClassKeys.contains('${s.classId ?? ''}-${s.sectionId ?? ''}');
      }).toList();
      if (subStudents.isNotEmpty) {
        groups.add((subject: sub, students: subStudents));
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAllocations(reloadRoster: false);
        _loadTaughtRoster(force: true);
        await Future.delayed(const Duration(milliseconds: 250));
      },
      child: groups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No students grouped under the selected subject filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: groups.length,
              itemBuilder: (context, idx) {
                final group = groups[idx];
                final sub = group.subject;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.indigo50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.indigo100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 16, color: AppColors.primaryAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sub.code.isNotEmpty ? '${sub.name} (${sub.code})' : sub.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            Text(
                              '${group.students.length} ${group.students.length == 1 ? 'student' : 'students'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...group.students.map((student) {
                        final csLabel = student.classSectionLabel;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                name: student.fullName.isNotEmpty ? student.fullName : 'Student',
                                avatarUrl: student.avatarUrl,
                                radius: 16,
                                fontSize: 12,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName.isNotEmpty ? student.fullName : 'Student',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    Text(
                                      [
                                        ?csLabel,
                                        if (student.admissionNumber.isNotEmpty)
                                          'Adm: ${student.admissionNumber}',
                                      ].join(' • '),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (student.rollNumber != null &&
                                  student.rollNumber!.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBackground,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'Roll ${student.rollNumber}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildClassesSectionsBody(BuildContext context) {
    if (_isLoadingAllocations && _allocations == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_allocationsError != null && _allocations == null) {
      return _buildAllocationsErrorCard(_allocationsError!);
    }

    final summaries = _classSectionSummaries;
    if (summaries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadAllocations(reloadRoster: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildNoAssignmentCard(
              'No classes or sections are currently assigned to your profile.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAllocations(reloadRoster: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: summaries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = summaries[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.indigo50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.indigo100),
                      ),
                      child: const Icon(
                        Icons.class_outlined,
                        size: 18,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.className} • ${item.sectionName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.studentCount != null
                                ? '${item.studentCount} ${item.studentCount == 1 ? 'Student' : 'Students'} Enrolled'
                                : 'Assigned Section',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.isHomeroom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'Class Teacher',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (item.subjects.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.subjects.map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          sub.code.isNotEmpty ? '${sub.name} (${sub.code})' : sub.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    'Homeroom Supervision (No Subject Allocation)',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (item.isHomeroom && item.subjects.isEmpty) {
                        setState(() {
                          _rosterSegment = 0;
                          _selectedClassSectionFilter = null;
                          _selectedSubjectFilter = null;
                        });
                        _loadHomeroomRoster();
                      } else {
                        setState(() {
                          _rosterSegment = 1;
                          _selectedClassSectionFilter = '${item.classId}-${item.sectionId}';
                          _selectedSubjectFilter = null;
                          _groupBySubject = false;
                        });
                        _loadTaughtRoster();
                      }
                    },
                    icon: const Icon(Icons.groups_outlined, size: 16),
                    label: Text(item.isHomeroom && item.subjects.isEmpty
                        ? 'Open Homeroom Roster'
                        : 'View Students'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryAccent,
                      side: const BorderSide(color: AppColors.indigo100),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditStudentDetailsDialog(
    BuildContext context,
    StudentRosterItem student,
  ) {
    final rollCtrl = TextEditingController(text: student.rollNumber ?? '');
    final phoneCtrl = TextEditingController(text: student.emergencyPhone ?? '');
    final medicalCtrl = TextEditingController(text: student.medicalNotes ?? '');
    String? selectedBloodGroup = student.bloodGroup;

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (selectedBloodGroup != null &&
        selectedBloodGroup.isNotEmpty &&
        !bloodGroups.contains(selectedBloodGroup)) {
      bloodGroups.add(selectedBloodGroup);
    }

    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.edit_note, size: 20, color: AppColors.primaryText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Student Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          '${student.fullName} • Adm: ${student.admissionNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 14, color: AppColors.secondaryText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Identity fields (Admission: ${student.admissionNumber}, Class/Section) are immutable.',
                              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: rollCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Roll Number',
                        hintText: 'e.g. 15',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBloodGroup,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Not Specified', style: TextStyle(color: AppColors.secondaryText)),
                        ),
                        ...bloodGroups.map((bg) => DropdownMenuItem(
                              value: bg,
                              child: Text(bg),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedBloodGroup = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Phone',
                        hintText: 'e.g. +91 9876543210',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: medicalCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Medical Notes / Allergies',
                        hintText: 'e.g. Asthmatic, allergic to peanuts',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final trimmedPhone = phoneCtrl.text.trim();
                          if (trimmedPhone.isNotEmpty && trimmedPhone.length < 5) {
                            setDialogState(() {
                              errorMessage = 'Emergency phone must be at least 5 characters or left blank.';
                            });
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });
                          try {
                            final profileRepo = context.read<ProfileRepository>();
                            await profileRepo.updateStudentProfileByTeacher(
                              student.id,
                              rollNumber: rollCtrl.text.trim(),
                              bloodGroup: selectedBloodGroup ?? '',
                              emergencyContactPhone: trimmedPhone,
                              medicalNotes: medicalCtrl.text.trim(),
                            );
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student details updated successfully'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                              if (_rosterSegment == 0 && _allocations?.homeroom != null) {
                                _loadHomeroomRoster(force: true);
                              } else {
                                _loadTaughtRoster(force: true);
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: AppColors.surface,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
