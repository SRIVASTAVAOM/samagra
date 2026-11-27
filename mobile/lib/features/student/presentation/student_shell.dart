import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/samagra_back_button.dart';
import '../../academics/bloc/academics_bloc.dart';
import '../../academics/bloc/academics_event.dart';
import '../../academics/bloc/academics_state.dart';
import '../../academics/models/subject_model.dart';
import '../../academics/presentation/student_roster_view.dart';
import '../../academics/presentation/subject_teachers_view.dart';
import '../../academics/repository/academics_repository.dart';
import '../../academics/bloc/exams_bloc.dart';
import '../../academics/repositories/exams_repository.dart';
import '../../academics/views/exams_list_view.dart';
import '../../attendance/bloc/attendance_bloc.dart';
import '../../attendance/bloc/attendance_event.dart';
import '../../attendance/presentation/student_attendance_history_view.dart';
import '../../attendance/repository/attendance_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/user_model.dart';
import '../../curriculum/bloc/curriculum_bloc.dart';
import '../../curriculum/presentation/curriculum_view.dart';
import '../../curriculum/repository/curriculum_repository.dart';
import '../../homework/bloc/homework_bloc.dart';
import '../../homework/presentation/student_homework_view.dart';
import '../../homework/repository/homework_repository.dart';
import '../../leaves/bloc/leaves_bloc.dart';
import '../../leaves/bloc/leaves_event.dart';
import '../../leaves/presentation/student_leave_view.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../materials/bloc/materials_bloc.dart';
import '../../materials/presentation/academic_materials_view.dart';
import '../../materials/repository/materials_repository.dart';
import '../../schedule/presentation/student_timetable_view.dart';
import '../../profiles/bloc/profile_bloc.dart';
import '../../profiles/bloc/profile_event.dart';
import '../../profiles/bloc/profile_state.dart';
import '../../profiles/presentation/student_profile_view.dart';
import '../../profiles/repository/profile_repository.dart';
import '../bloc/student_features_bloc.dart';
import '../bloc/student_features_event.dart';
import '../bloc/student_features_state.dart';
import '../repository/student_features_repository.dart';
import 'views/school_contact_view.dart';
import 'views/student_birthdays_view.dart';
import 'views/student_complaints_view.dart';
import 'views/student_dashboard_view.dart';
import 'views/student_feedback_view.dart';
import 'views/student_fees_view.dart';
import 'views/student_notices_view.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../schedule/presentation/student_online_classes_view.dart';
import '../../schedule/repository/schedule_repository.dart';

class StudentShell extends StatefulWidget {
  final UserModel user;

  const StudentShell({super.key, required this.user});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;
  int _academicSubTab =
      0; // 0: Homework, 1: Materials, 2: Syllabus, 3: Classmates, 4: Birthdays, 5: Teachers, 6: Exams
  int _servicesSubTab =
      0; // 0: Profile, 1: Leaves, 2: Notices, 3: Complaints, 4: Feedback, 5: Contact
  final List<_StudentNavigationLocation> _navigationHistory = [];

  List<SubjectModel> _subjects = [];
  SubjectModel? _selectedSubject;
  bool _loadingSubjects = false;
  AcademicsBloc? _academicsBloc;
  bool _handlingSystemBack = false;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  CurriculumBloc? _curriculumBloc;
  MaterialsBloc? _materialsBloc;

  void _loadClassmates() {
    final classId = widget.user.classId ?? '';
    final sectionId = widget.user.sectionId ?? '';
    if (classId.isEmpty || sectionId.isEmpty) {
      return;
    }
    _academicsBloc?.add(
      LoadClassRosterEvent(
        classId: classId,
        sectionId: sectionId,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubjects();
    });
  }

  Future<void> _fetchSubjects() async {
    if (!mounted) return;
    try {
      setState(() => _loadingSubjects = true);
      final repo = context.read<AcademicsRepository>();
      final subjects = await repo.getSubjects(classId: widget.user.classId);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          if (subjects.isNotEmpty) {
            _selectedSubject = subjects.first;
          }
          _loadingSubjects = false;
        });

        // Immediately dispatch events so Materials and Syllabus are pre-loaded
        if (subjects.isNotEmpty) {
          final classId = widget.user.classId ?? '';
          final firstSubId = subjects.first.id;
          if (classId.isNotEmpty) {
            _materialsBloc?.add(LoadClassMaterialsEvent(classId, firstSubId));
            _curriculumBloc?.add(LoadCurriculumUnitsEvent(classId, firstSubId));
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  void _navigateToTab(
    int tabIndex, {
    int? academicSubTab,
    int? servicesSubTab,
  }) {
    final nextLocation = _StudentNavigationLocation(
      selectedIndex: tabIndex,
      academicSubTab: academicSubTab ?? _academicSubTab,
      servicesSubTab: servicesSubTab ?? _servicesSubTab,
    );
    if (!nextLocation.matches(_currentLocation)) {
      _navigationHistory.add(_currentLocation);
    }
    setState(() {
      _selectedIndex = tabIndex;
      if (academicSubTab != null) {
        _academicSubTab = academicSubTab;
      }
      if (servicesSubTab != null) {
        _servicesSubTab = servicesSubTab;
      }
    });

    final classId = widget.user.classId ?? '';
    final subjectId =
        _selectedSubject?.id ??
        (_subjects.isNotEmpty ? _subjects.first.id : '');
    if (tabIndex == 2) {
      if (academicSubTab == 3) {
        _loadClassmates();
      } else if (academicSubTab == 4) {
        _academicsBloc?.add(LoadClassmatesBirthdaysEvent());
      } else if (academicSubTab == 5) {
        _academicsBloc?.add(LoadSubjectTeachersEvent());
      } else if (classId.isNotEmpty && subjectId.isNotEmpty) {
        if (academicSubTab == 1) {
          _materialsBloc?.add(LoadClassMaterialsEvent(classId, subjectId));
        } else if (academicSubTab == 2) {
          _curriculumBloc?.add(LoadCurriculumUnitsEvent(classId, subjectId));
        }
      }
    }
  }

  _StudentNavigationLocation get _currentLocation => _StudentNavigationLocation(
    selectedIndex: _selectedIndex,
    academicSubTab: _academicSubTab,
    servicesSubTab: _servicesSubTab,
  );

  bool get _canNavigateBack => _navigationHistory.isNotEmpty;

  void _navigateBack() {
    if (_navigationHistory.isEmpty || _handlingSystemBack) return;
    _handlingSystemBack = true;
    final previous = _navigationHistory.removeLast();
    setState(() {
      _selectedIndex = previous.selectedIndex;
      _academicSubTab = previous.academicSubTab;
      _servicesSubTab = previous.servicesSubTab;
    });
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _handlingSystemBack = false;
    });
  }

  void _navigateToAcademicSubTab(int subTab) {
    if (_academicSubTab == subTab) return;
    _navigationHistory.add(_currentLocation);
    setState(() => _academicSubTab = subTab);
  }

  void _navigateToServicesSubTab(int subTab) {
    if (_servicesSubTab == subTab) return;
    _navigationHistory.add(_currentLocation);
    setState(() => _servicesSubTab = subTab);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) {
            final bloc = AcademicsBloc(
              repository: ctx.read<AcademicsRepository>(),
            );
            _academicsBloc = bloc;
            if ((widget.user.classId ?? '').isNotEmpty &&
                (widget.user.sectionId ?? '').isNotEmpty) {
              bloc.add(
                LoadClassRosterEvent(
                  classId: widget.user.classId ?? '',
                  sectionId: widget.user.sectionId ?? '',
                ),
              );
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (ctx) =>
              ProfileBloc(repository: ctx.read<ProfileRepository>())
                ..add(LoadStudentProfileEvent()),
        ),
        BlocProvider(
          create: (ctx) =>
              AttendanceBloc(repository: ctx.read<AttendanceRepository>())
                ..add(const LoadStudentOwnAttendanceEvent()),
        ),
        BlocProvider(
          create: (ctx) =>
              LeavesBloc(repository: ctx.read<LeavesRepository>())
                ..add(const LoadStudentMyLeavesEvent()),
        ),
        BlocProvider(
          create: (ctx) =>
              HomeworkBloc(ctx.read<HomeworkRepository>())
                ..add(const LoadStudentHomeworkEvent()),
        ),
        BlocProvider(
          create: (ctx) {
            final bloc = CurriculumBloc(ctx.read<CurriculumRepository>());
            _curriculumBloc = bloc;
            final classId = widget.user.classId ?? '';
            final subjectId =
                _selectedSubject?.id ??
                (_subjects.isNotEmpty ? _subjects.first.id : '');
            if (classId.isNotEmpty && subjectId.isNotEmpty) {
              bloc.add(LoadCurriculumUnitsEvent(classId, subjectId));
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (ctx) {
            final bloc = MaterialsBloc(ctx.read<MaterialsRepository>());
            _materialsBloc = bloc;
            final classId = widget.user.classId ?? '';
            final subjectId =
                _selectedSubject?.id ??
                (_subjects.isNotEmpty ? _subjects.first.id : '');
            if (classId.isNotEmpty && subjectId.isNotEmpty) {
              bloc.add(LoadClassMaterialsEvent(classId, subjectId));
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (ctx) =>
              ExamsBloc(repository: ctx.read<ExamsRepository>())
                ..add(const LoadExamsEvent()),
        ),
        BlocProvider(
          create: (ctx) =>
              StudentFeaturesBloc(
                  repository: ctx.read<StudentFeaturesRepository>(),
                )
                ..add(const LoadStudentNoticesEvent())
                ..add(const LoadStudentFeesEvent()),
        ),
        BlocProvider(
          create: (ctx) =>
              ScheduleBloc(repository: ctx.read<ScheduleRepository>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && !Navigator.of(context).canPop()) {
                _navigateBack();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.scaffoldBackground,
              appBar: AppBar(
                leading: _selectedIndex != 0 &&
                        _canNavigateBack &&
                        !(_selectedIndex == 2 &&
                            (_academicSubTab == 1 || _academicSubTab == 2))
                    ? SamagraBackButton(onPressed: _navigateBack)
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          top: 10,
                          bottom: 10,
                          right: 2,
                        ),
                        child: Image.asset(
                          'assets/images/logo_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                leadingWidth: 56,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedIndex == 0
                          ? 'Student Dashboard'
                          : widget.user.displayName,
                    ),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        String subtitle = 'Student Portal';
                        if (state is StudentProfileLoaded) {
                          final isUuid = RegExp(
                            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                          );
                          final rawCls = state.profile.className;
                          final rawSec = state.profile.sectionName;
                          final cls =
                              (rawCls != null &&
                                  rawCls.trim().isNotEmpty &&
                                  !isUuid.hasMatch(rawCls))
                              ? rawCls.trim()
                              : 'Grade 10';
                          final sec =
                              (rawSec != null &&
                                  rawSec.trim().isNotEmpty &&
                                  !isUuid.hasMatch(rawSec))
                              ? rawSec.trim()
                              : 'Section A';
                          subtitle = '$cls • $sec';
                          if (state.profile.rollNumber != null &&
                              state.profile.rollNumber!.isNotEmpty &&
                              !isUuid.hasMatch(state.profile.rollNumber!)) {
                            subtitle += ' • Roll #${state.profile.rollNumber}';
                          }
                        }
                        return Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  BlocBuilder<StudentFeaturesBloc, StudentFeaturesState>(
                    builder: (context, state) {
                      int unreadCount = 0;
                      if (state is StudentNoticesLoaded) {
                        unreadCount = state.notices.length;
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Notifications & Homework Alerts',
                            icon: const Icon(
                              Icons.notifications_outlined,
                              size: 22,
                              color: AppColors.primaryText,
                            ),
                            onPressed: () {
                              _navigateToTab(4, servicesSubTab: 2);
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE11D48),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Sign Out',
                    icon: const Icon(
                      Icons.logout,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequestedEvent());
                    },
                  ),
                BlocBuilder<StudentFeaturesBloc, StudentFeaturesState>(
                  builder: (context, state) {
                    int unreadCount = 0;
                    if (state is StudentNoticesLoaded) {
                      unreadCount = state.notices.length;
                    } else {
                      unreadCount = context
                          .read<StudentFeaturesBloc>()
                          .cachedNotices
                          .length;
                    }
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Notifications & Homework Alerts',
                          icon: const Icon(Icons.notifications_outlined,
                              size: 22, color: AppColors.primaryText),
                          onPressed: () {
                            _navigateToTab(4, servicesSubTab: 2);
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE11D48),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
              body: PageStorage(
                bucket: _pageStorageBucket,
                child: _buildCurrentTab(context),
              ),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.0),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => _navigateToTab(idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check),
                      label: 'Attendance',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: 'Academics',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: 'Fees',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.apps_outlined),
                      selectedIcon: Icon(Icons.apps),
                      label: 'Services',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return StudentDashboardView(
          user: widget.user,
          onNavigateToTab: _navigateToTab,
        );
      case 1:
        return const StudentAttendanceHistoryView();
      case 2:
        return _buildAcademicsTab(context);
      case 3:
        return const StudentFeesView();
      case 4:
      default:
        return _buildServicesTab(context);
    }
  }

  // --- ACADEMICS TAB ---
  Widget _buildAcademicsTab(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(bottom: BorderSide(color: Color(0xFFE3ECF8))),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildSubTabButton(
                  title: 'Homework',
                  icon: Icons.assignment_outlined,
                  isSelected: _academicSubTab == 0,
                  onTap: () {
                    _navigateToAcademicSubTab(0);
                    context.read<HomeworkBloc>().add(
                      const LoadStudentHomeworkEvent(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Study Materials',
                  icon: Icons.menu_book_outlined,
                  isSelected: _academicSubTab == 1,
                  onTap: () {
                    _navigateToAcademicSubTab(1);
                    final classId = widget.user.classId ?? '';
                    final subjectId = _selectedSubject?.id ?? '';
                    if (classId.isNotEmpty && subjectId.isNotEmpty) {
                      context.read<MaterialsBloc>().add(
                        LoadClassMaterialsEvent(classId, subjectId),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Syllabus',
                  icon: Icons.schema_outlined,
                  isSelected: _academicSubTab == 2,
                  onTap: () {
                    _navigateToAcademicSubTab(2);
                    final classId = widget.user.classId ?? '';
                    final subjectId = _selectedSubject?.id ?? '';
                    if (classId.isNotEmpty && subjectId.isNotEmpty) {
                      context.read<CurriculumBloc>().add(
                        LoadCurriculumUnitsEvent(classId, subjectId),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Classmates',
                  icon: Icons.groups_outlined,
                  isSelected: _academicSubTab == 3,
                  onTap: () {
                    _navigateToAcademicSubTab(3);
                    _loadClassmates();
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Birthdays',
                  icon: Icons.cake_outlined,
                  isSelected: _academicSubTab == 4,
                  onTap: () {
                    _navigateToAcademicSubTab(4);
                    context.read<AcademicsBloc>().add(
                      LoadClassmatesBirthdaysEvent(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Teachers',
                  icon: Icons.person_outline,
                  isSelected: _academicSubTab == 5,
                  onTap: () {
                    _navigateToAcademicSubTab(5);
                    context.read<AcademicsBloc>().add(
                      LoadSubjectTeachersEvent(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Exams & Results',
                  icon: Icons.assignment_turned_in_outlined,
                  isSelected: _academicSubTab == 6,
                  onTap: () {
                    _navigateToAcademicSubTab(6);
                    context.read<ExamsBloc>().add(const LoadExamsEvent());
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Online Classes',
                  icon: Icons.videocam_outlined,
                  isSelected: _academicSubTab == 7,
                  onTap: () {
                    _navigateToAcademicSubTab(7);
                    context.read<ScheduleBloc>().add(
                      const LoadOnlineClassesEvent(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Timetable',
                  isSelected: _academicSubTab == 8,
                  onTap: () {
                    setState(() => _academicSubTab = 8);
                    context.read<ScheduleBloc>().add(const LoadStudentTimetableEvent());
                  },
                ),
              ],
            ),
          ),
        ),
        // Sub-tab content
        Expanded(
          child: Builder(
            builder: (context) {
              if (_academicSubTab == 8) {
                return const StudentTimetableView();
              }
              if (_academicSubTab == 7) {
                return const StudentOnlineClassesView();
              }
              if (_academicSubTab == 0) {
                return const StudentHomeworkView();
              }
              if (_academicSubTab == 1) {
                final classId = widget.user.classId ?? '';
                final currentSub =
                    _selectedSubject ??
                    (_subjects.isNotEmpty ? _subjects.first : null);
                return Column(
                  children: [
                    _buildSubjectSelectorChips(context, isMaterials: true),
                    Expanded(
                      child: AcademicMaterialsView(
                        key: ValueKey('mat-$classId-${currentSub?.id}'),
                        classId: classId,
                        subjectId: currentSub?.id ?? '',
                        subjectName: currentSub?.name,
                        showBackButton: _canNavigateBack,
                        onBack: _navigateBack,
                      ),
                    ),
                  ],
                );
              }
              if (_academicSubTab == 2) {
                final classId = widget.user.classId ?? '';
                final currentSub =
                    _selectedSubject ??
                    (_subjects.isNotEmpty ? _subjects.first : null);
                return Column(
                  children: [
                    _buildSubjectSelectorChips(context, isMaterials: false),
                    Expanded(
                      child: CurriculumView(
                        key: ValueKey('curr-$classId-${currentSub?.id}'),
                        classId: classId,
                        subjectId: currentSub?.id ?? '',
                        showBackButton: _canNavigateBack,
                        onBack: _navigateBack,
                      ),
                    ),
                  ],
                );
              }
              if (_academicSubTab == 4) {
                return const StudentBirthdaysView();
              }
              if (_academicSubTab == 6) {
                return const ExamsListView(userRole: 'STUDENT');
              }

              // AcademicsBloc handles Subtabs 3 (Classmates) and 5 (Teachers)
              if (_academicSubTab == 3 &&
                  ((widget.user.classId ?? '').isEmpty ||
                      (widget.user.sectionId ?? '').isEmpty)) {
                return StudentRosterView(
                  students: const [],
                  isStudentClassmatesMode: true,
                  errorMessage:
                      'Class or section assignment is missing for your profile.',
                  onRetry: _loadClassmates,
                );
              }

              return BlocBuilder<AcademicsBloc, AcademicsState>(
                builder: (context, state) {
                  if (state is AcademicsLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (state is AcademicsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 36,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                if (_academicSubTab == 3) {
                                  _loadClassmates();
                                } else if (_academicSubTab == 5) {
                                  context.read<AcademicsBloc>().add(
                                    LoadSubjectTeachersEvent(),
                                  );
                                }
                              },
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

                  if (_academicSubTab == 3 && state is RosterLoaded) {
                    return StudentRosterView(
                      students: state.students,
                      isStudentClassmatesMode: true,
                      onRetry: _loadClassmates,
                    );
                  }

                  if (_academicSubTab == 5 && state is SubjectTeachersLoaded) {
                    return SubjectTeachersView(
                      teachers: state.teachers,
                      onRetry: () =>
                          _academicsBloc?.add(LoadSubjectTeachersEvent()),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelectorChips(
    BuildContext context, {
    required bool isMaterials,
  }) {
    if (_loadingSubjects) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_subjects.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _subjects.map((sub) {
            final isSelected = _selectedSubject?.id == sub.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.surface
                        : AppColors.primaryText,
                  ),
                ),
                backgroundColor: AppColors.surface,
                selectedColor: const Color(0xFF1677F2),
                checkmarkColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1677F2)
                      : const Color(0xFFE3ECF8),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedSubject = sub);
                    final classId = widget.user.classId ?? '';
                    if (classId.isNotEmpty) {
                      if (isMaterials) {
                        context.read<MaterialsBloc>().add(
                          LoadClassMaterialsEvent(classId, sub.id),
                        );
                      } else {
                        context.read<CurriculumBloc>().add(
                          LoadCurriculumUnitsEvent(classId, sub.id),
                        );
                      }
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

  // --- SERVICES TAB ---
  Widget _buildServicesTab(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton(
                  title: 'My Profile',
                  isSelected: _servicesSubTab == 0,
                  onTap: () => _navigateToServicesSubTab(0),
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Leave Applications',
                  isSelected: _servicesSubTab == 1,
                  onTap: () => _navigateToServicesSubTab(1),
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Notices',
                  isSelected: _servicesSubTab == 2,
                  onTap: () => _navigateToServicesSubTab(2),
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'Complaints',
                  isSelected: _servicesSubTab == 3,
                  onTap: () => _navigateToServicesSubTab(3),
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'School Feedback',
                  isSelected: _servicesSubTab == 4,
                  onTap: () => _navigateToServicesSubTab(4),
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  title: 'School Contact',
                  isSelected: _servicesSubTab == 5,
                  onTap: () => _navigateToServicesSubTab(5),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildServicesContent()),
      ],
    );
  }

  Widget _buildServicesContent() {
    switch (_servicesSubTab) {
      case 0:
        return const StudentProfileView();
      case 1:
        return const StudentLeaveView();
      case 2:
        return const StudentNoticesView();
      case 3:
        return const StudentComplaintsView();
      case 4:
        return const StudentFeedbackView();
      case 5:
      default:
        return const SchoolContactView();
    }
  }

  Widget _buildSubTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1677F2), Color(0xFF24B9F2)],
                  )
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1677F2)
                  : const Color(0xFFE3ECF8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF14233F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentNavigationLocation {
  final int selectedIndex;
  final int academicSubTab;
  final int servicesSubTab;

  const _StudentNavigationLocation({
    required this.selectedIndex,
    required this.academicSubTab,
    required this.servicesSubTab,
  });

  bool matches(_StudentNavigationLocation other) =>
      selectedIndex == other.selectedIndex &&
      academicSubTab == other.academicSubTab &&
      servicesSubTab == other.servicesSubTab;
}
