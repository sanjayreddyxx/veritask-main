import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../widgets/app_widgets.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final CourseModel? course;

  const CreateEditCourseScreen({super.key, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String _category = 'Education';
  bool _loading = false;

  final _categories = [
    'Education',
    'Web Development',
    'Design',
    'Business',
    'Freelance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkRole();
    if (widget.course != null) {
      final c = widget.course!;
      _titleCtrl.text = c.title;
      _instructorCtrl.text = c.instructor;
      _durationCtrl.text = c.duration;
      _descCtrl.text = c.description;
      if (_categories.contains(c.category)) {
        _category = c.category;
      } else {
        _category = 'Other';
      }
    }
  }

  Future<void> _checkRole() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final role = await AuthService().getUserRole(uid);
    if (!mounted) return;
    if (role != 'admin') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Admins Only'),
          backgroundColor: kDanger,
        ),
      );
    }
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final courseService = CourseService();
      if (widget.course != null) {
        // Edit Mode
        final updated = widget.course!.copyWith(
          title: _titleCtrl.text.trim(),
          instructor: _instructorCtrl.text.trim(),
          duration: _durationCtrl.text.trim(),
          category: _category,
          description: _descCtrl.text.trim(),
        );
        await courseService.updateCourse(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course updated successfully!')),
          );
          // Pop twice to get back to the courses list and force screen refresh
          Navigator.pop(context); // Pop edit screen
          Navigator.pop(context); // Pop detail screen
        }
      } else {
        // Create Mode
        final adminId = AuthService().currentUser?.uid;
        final newCourse = CourseModel(
          id: '',
          title: _titleCtrl.text.trim(),
          instructor: _instructorCtrl.text.trim(),
          authorId: adminId,
          duration: _durationCtrl.text.trim(),
          category: _category,
          description: _descCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
        await courseService.createCourse(newCourse);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course created successfully!')),
          );
          Navigator.pop(context); // Pop create screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.course != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Course' : 'Add Course'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Modify course parameters' : 'Create a new course',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in all fields. Courses are immediately visible to all users.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course title',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Please enter a course title' : null,
                ),
                const SizedBox(height: 16),

                // Instructor
                TextFormField(
                  controller: _instructorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instructor name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Please enter instructor\'s name' : null,
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duration (e.g. 6 Weeks, 10 Hours)',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Please specify course duration' : null,
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Course description',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEdit ? Icons.save : Icons.add_circle_outline, color: Colors.white),
                  label: Text(
                    isEdit ? 'Save Changes' : 'Create Course',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructorCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}
