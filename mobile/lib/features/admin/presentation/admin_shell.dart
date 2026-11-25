import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/user_model.dart';
import '../models/admin_dashboard_model.dart';
import '../repository/admin_repository.dart';
import 'views/admin_dashboard_view.dart';

class AdminShell extends StatefulWidget {
  final UserModel user;

  const AdminShell({super.key, required this.user});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminDashboardView(user: widget.user),
      const AdminNoticesView(),
      _buildAdminProfileView(),
    ];
  }

  Widget _buildAdminProfileView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Principal / Admin Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        backgroundColor: AppColors.primaryAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(widget.user.displayName),
              subtitle: Text(widget.user.email ?? widget.user.identifier),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout from App', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              context.read<AuthBloc>().add(LogoutRequestedEvent());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryAccent),
            label: 'Pulse',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded, color: AppColors.primaryAccent),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded, color: AppColors.primaryAccent),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class AdminNoticesView extends StatefulWidget {
  const AdminNoticesView({super.key});

  @override
  State<AdminNoticesView> createState() => _AdminNoticesViewState();
}

class _AdminNoticesViewState extends State<AdminNoticesView> {
  final _adminRepo = AdminRepository();
  late Future<List<AdminNoticeItem>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = _adminRepo.fetchNotices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'School Circulars & Notices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        backgroundColor: AppColors.primaryAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            tooltip: 'Refresh Notices',
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadNotices(),
        child: FutureBuilder<List<AdminNoticeItem>>(
          future: _noticesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notices = snapshot.data ?? [];

            if (notices.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.campaign_rounded,
                              size: 64,
                              color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Circulars',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Broadcast urgent circulars directly to parents and teachers from the Pulse tab.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notice = notices[index];
                Color badgeBg;
                Color badgeColor;
                Color badgeBorder;

                switch (notice.priority.toUpperCase()) {
                  case 'URGENT':
                    badgeBg = const Color(0xFFFEF2F2);
                    badgeColor = const Color(0xFFB91C1C);
                    badgeBorder = const Color(0xFFFCA5A5);
                    break;
                  case 'INFO':
                    badgeBg = const Color(0xFFF0FDFA);
                    badgeColor = const Color(0xFF0F766E);
                    badgeBorder = const Color(0xFF99F6E4);
                    break;
                  case 'NORMAL':
                  default:
                    badgeBg = const Color(0xFFEFF6FF);
                    badgeColor = const Color(0xFF1D4ED8);
                    badgeBorder = const Color(0xFFBFDBFE);
                    break;
                }

                final pubDate = notice.publishedAt != null
                    ? (notice.publishedAt!.contains('T')
                        ? notice.publishedAt!.split('T')[0]
                        : notice.publishedAt!)
                    : '';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeBorder),
                            ),
                            child: Text(
                              notice.priority,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.group_outlined,
                              size: 13, color: AppColors.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            'Audience: ${notice.targetRole ?? "ALL"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pubDate.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: AppColors.secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              pubDate,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 16),
                      Text(
                        notice.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
