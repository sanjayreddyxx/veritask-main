import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';
import '../../models/task_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/task_service.dart';
import '../../widgets/app_widgets.dart';
import '../../services/auth_service.dart';
import '../admin/create_task_screen.dart';
import '../admin/admin_review_screen.dart';
import 'create_edit_course_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final CourseModel course;
  final bool isAdmin;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.isAdmin,
  });

  Future<void> _deleteCourse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CourseService().deleteCourse(course.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted successfully')),
        );
        Navigator.pop(context); // Go back to list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(course.category);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: categoryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: isAdmin
                ? [
                    _buildActionButton(Icons.edit_rounded, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEditCourseScreen(course: course),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.delete_outline_rounded, () => _deleteCourse(context)),
                    const SizedBox(width: 16),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor, categoryColor.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: -30,
                    child: Icon(Icons.school_rounded, size: 240, color: Colors.white.withOpacity(0.1)),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.menu_book_rounded, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              course.category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0, -32, 0),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDynamicInfoCard(
                          icon: Icons.person_rounded,
                          color: kPrimary,
                          title: 'Expert Instructor',
                          value: course.instructor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDynamicInfoCard(
                          icon: Icons.timer_rounded,
                          color: kWarning,
                          title: 'Course Duration',
                          value: course.duration,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Curriculum Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF475569),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildCourseTasksSection(context),
                  const SizedBox(height: 48),

                  if (!isAdmin)
                    _buildStudentEnrollmentSection(context),
                  
                  if (isAdmin)
                    _buildAdminEnrollmentSection(context),

                  if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: PremiumButton(
                      label: 'Assign Task to Course',
                      icon: Icons.add_task_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateTaskScreen(
                              adminUid: AuthService().currentUser?.uid ?? '',
                              courseId: course.id,
                              courseName: course.title,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTasksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Tasks & Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<TaskModel>>(
          stream: TaskService().getTasksForCourse(course.id),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading tasks: ${snap.error}', style: const TextStyle(color: kDanger, fontSize: 13)),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snap.data ?? [];
            if (tasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.assignment_outlined, color: Color(0xFF94A3B8), size: 32),
                    SizedBox(height: 12),
                    Text(
                      'No tasks assigned to this course yet.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: tasks.map((t) => _buildTaskRow(context, t)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskRow(BuildContext context, TaskModel t) {
    return GestureDetector(
      onTap: () => _showSubmissionReview(context, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getPriorityColor(t.priority).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_rounded, color: _getPriorityColor(t.priority), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Assigned to: ${t.studentName ?? "User"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      if (t.maxMarks != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${t.maxMarks!.toInt()} PTS',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kPrimary),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        DateFormat('d MMM, HH:mm').format(t.createdAt),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  void _showSubmissionReview(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: AdminReviewScreen(
          // We wrap the TaskModel into a single-item view 
          // but specifically for this one task
          taskService: TaskService(), 
          singleTaskId: task.id, 
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return kDanger;
      case 'low': return kSuccess;
      default: return kWarning;
    }
  }

  Widget _buildStudentEnrollmentSection(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<EnrollmentModel?>(
      stream: CourseService().getUserEnrollment(course.id, user.uid),
      builder: (context, snap) {
        final enrollment = snap.data;

        if (enrollment == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text(
                  'Join this learning community to access all tasks and assessments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  label: 'Request Enrollment',
                  icon: Icons.send_rounded,
                  onPressed: () async {
                    final userData = await AuthService().getCurrentUserModel();
                    await CourseService().requestEnrollment(
                      courseId: course.id,
                      userId: user.uid,
                      userName: userData?.name ?? 'Anonymous',
                      userEmail: userData?.email ?? '',
                    );
                  },
                ),
              ],
            ),
          );
        }

        if (enrollment.status == EnrollmentStatus.pending) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your enrollment request is pending administrator approval.',
                    style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        if (enrollment.status == EnrollmentStatus.rejected) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: kDanger),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your enrollment request was not accepted at this time.',
                    style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: kSuccess),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Enrollment Active: You have full access to this curriculum.',
                  style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminEnrollmentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enrollment Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<EnrollmentModel>>(
          stream: CourseService().getEnrollmentsForCourse(course.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final enrollments = snap.data ?? [];
            final pending = enrollments.where((e) => e.status == EnrollmentStatus.pending).toList();
            final accepted = enrollments.where((e) => e.status == EnrollmentStatus.accepted).toList();

            return Column(
              children: [
                // Pending Requests
                if (pending.isNotEmpty) ...[
                  const SectionHeader(title: 'Pending Requests'),
                  ...pending.map((e) => _buildEnrollmentRow(e, true)),
                  const SizedBox(height: 24),
                ],

                // Active Students
                const SectionHeader(title: 'Enrolled Students'),
                if (accepted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No students currently enrolled',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                else
                  ...accepted.map((e) => _buildEnrollmentRow(e, false)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnrollmentRow(EnrollmentModel e, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimary.withOpacity(0.1),
            child: Text(
              e.userName[0].toUpperCase(),
              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                Text(
                  e.userEmail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (isPending) ...[
            IconButton(
              onPressed: () => CourseService().updateEnrollmentStatus(e.id, EnrollmentStatus.accepted),
              icon: const Icon(Icons.check_circle_rounded, color: kSuccess),
              tooltip: 'Accept',
            ),
            IconButton(
              onPressed: () => CourseService().updateEnrollmentStatus(e.id, EnrollmentStatus.rejected),
              icon: const Icon(Icons.cancel_rounded, color: kDanger),
              tooltip: 'Reject',
            ),
          ] else
            const Icon(Icons.verified_rounded, color: kPrimary, size: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildDynamicInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education': return const Color(0xFF0EA5E9);
      case 'development': return const Color(0xFF10B981);
      case 'design': return const Color(0xFFEC4899);
      case 'business': return const Color(0xFFF59E0B);
      case 'freelance': return const Color(0xFF8B5CF6);
      default: return kPrimary;
    }
  }
}

