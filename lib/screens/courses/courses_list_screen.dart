import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../widgets/app_widgets.dart';
import 'course_detail_screen.dart';
import 'create_edit_course_screen.dart';

class CoursesListScreen extends StatefulWidget {
  final bool isAdmin;
  final String? userId; // If provided, show only enrolled courses
  const CoursesListScreen({super.key, required this.isAdmin, this.userId});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final _courseService = CourseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Determine which stream to use
    final stream = widget.userId != null 
      ? _courseService.getEnrolledCourses(widget.userId!)
      : _courseService.getCourses();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.userId != null ? 'My Curriculum' : 'Knowledge Base', 
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search my courses...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimary, width: 1),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final courses = snap.data ?? [];
                final filtered = courses.where((c) {
                  return c.title.toLowerCase().contains(_searchQuery) ||
                         c.category.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.school_rounded, size: 48, color: const Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No material available yet' 
                              : 'No matches found',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final course = filtered[idx];
                    return CourseCard(
                      course: course,
                      isAdmin: widget.isAdmin,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailScreen(
                              course: course,
                              isAdmin: widget.isAdmin,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? PremiumButton(
              label: 'Add Course',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateEditCourseScreen(),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
