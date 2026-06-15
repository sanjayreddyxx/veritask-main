import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/course_service.dart';
import '../../models/user_model.dart';
import '../../models/course_model.dart';
import '../../widgets/app_widgets.dart';
import 'admin_review_screen.dart';
import '../courses/courses_list_screen.dart';
import '../courses/course_detail_screen.dart';
import '../courses/create_edit_course_screen.dart';
import '../user/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _taskService = TaskService();
  UserModel? _user;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminHomeTab(taskService: _taskService, user: _user),
      const CoursesListScreen(isAdmin: true),
      AdminReviewScreen(taskService: _taskService),
      ProfileScreen(user: _user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? PremiumButton(
              label: 'Create Course',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateEditCourseScreen()),
              ),
              color: kPrimary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: kPrimary,
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
              _navItem(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Courses'),
              _navItem(Icons.rate_review_outlined, Icons.rate_review_rounded, 'Review'),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(activeIcon, size: 24),
      ),
      label: label,
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  final TaskService taskService;
  final UserModel? user;
  const _AdminHomeTab({required this.taskService, this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: kPrimary,
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Hub',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                Text('Managing: ${user?.name ?? ""}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 10)),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => AuthService().signOut(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: kPrimary.withOpacity(0.1),
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? "A",
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Admin User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'admin@mevonics.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? 'ADMINISTRATOR',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                SectionHeader(title: 'Administrative Tools'),
                const SizedBox(height: 16),

                const SizedBox(height: 32),
                SectionHeader(
                  title: 'Available Courses',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoursesListScreen(isAdmin: true),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stream of all courses
                StreamBuilder<List<CourseModel>>(
                  stream: CourseService().getCourses(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final courses = snap.data ?? [];
                    if (courses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.auto_stories_outlined, color: Colors.grey.withOpacity(0.5), size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'No courses published yet',
                              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: courses.take(3).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CourseCard(
                          course: c,
                          isAdmin: true,
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(course: c, isAdmin: true),
                              ),
                            );
                          },
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),
                
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'You are in Management Mode. Submissions tracking and full course registry are available in their respective tabs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
