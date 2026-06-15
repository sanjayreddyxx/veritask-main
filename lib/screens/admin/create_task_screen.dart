import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class CreateTaskScreen extends StatefulWidget {
  final String adminUid;
  final String? courseId;
  final String? courseName;
  const CreateTaskScreen({super.key, required this.adminUid, this.courseId, this.courseName});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(); // New field for max marks
  final _taskService = TaskService();

  String _priority = 'medium';
  late String _category;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedUserId;
  bool _loading = false;

  final _categories = [
    'General', 'Education', 'Internship', 'Freelance',
    'Field Work', 'Office', 'Research', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.courseId != null ? 'Education' : 'General';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // For non-course tasks, we still need a single user
    if (widget.courseId == null && _selectedUserId == null) {
      _showSnack('Please select a user to assign the task');
      return;
    }

    setState(() => _loading = true);
    try {
      final maxMarks = double.tryParse(_marksCtrl.text.trim());

      if (widget.courseId != null) {
        // ASSIGN TO ALL ENROLLED STUDENTS
        final enrollmentsSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('courseId', isEqualTo: widget.courseId)
            .where('status', isEqualTo: 'EnrollmentStatus.accepted')
            .get();

        if (enrollmentsSnap.docs.isEmpty) {
          _showSnack('No students are currently enrolled in this course.');
          setState(() => _loading = false);
          return;
        }

        for (var doc in enrollmentsSnap.docs) {
          final data = doc.data();
          final studentId = data['userId'];
          final studentName = data['userName'];

          final task = TaskModel(
            id: '',
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: 'Education',
            priority: 'medium',
            status: 'pending',
            assignedTo: studentId,
            assignedBy: widget.adminUid,
            courseId: widget.courseId,
            courseName: widget.courseName,
            studentName: studentName,
            maxMarks: maxMarks,
            dueDate: _dueDate,
            createdAt: DateTime.now(),
          );
          await _taskService.createTask(task);
        }
      } else {
        // SINGLE USER ASSIGNMENT (Standard Task)
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(_selectedUserId).get();
        final studentName = userSnap.data()?['name'] ?? 'Student';

        final task = TaskModel(
          id: '',
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          priority: _priority,
          status: 'pending',
          assignedTo: _selectedUserId!,
          assignedBy: widget.adminUid,
          courseId: widget.courseId,
          courseName: widget.courseName,
          studentName: studentName,
          maxMarks: maxMarks,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
        );
        await _taskService.createTask(task);
      }

      if (mounted) {
        _showSnack('Tasks published successfully to all students!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isCourseTask = widget.courseId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isCourseTask ? 'Create Class Assignment' : 'Create Task'),
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
                if (isCourseTask)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: kPrimary.withAlpha(13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kPrimary.withAlpha(26)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group_add_rounded, color: kPrimary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'This assignment will be automatically published to all students enrolled in this course.',
                            style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    hintText: 'e.g. Mid-term Research Paper',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Enter assignment title' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Requirements & Instructions',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Enter instructions' : null,
                ),
                const SizedBox(height: 20),

                // MARKS FIELD (Replaces category/priority for courses)
                TextFormField(
                  controller: _marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Marks / Points',
                    hintText: 'e.g. 100',
                    prefixIcon: Icon(Icons.grade_rounded),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Enter maximum marks' : null,
                ),
                const SizedBox(height: 20),

                // Due date
                const Text('Submission Deadline',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: kPrimary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${_dueDate.day} ${_monthName(_dueDate.month)} ${_dueDate.year}',
                          style:
                              const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.expand_more_rounded,
                            color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
                
                if (!isCourseTask) ...[
                  const SizedBox(height: 20),
                  // Category
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 20),

                  // Priority
                  const Text('Importance Level',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Row(
                    children: ['low', 'medium', 'high']
                        .map((p) => Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _priority = p),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _priority == p
                                        ? _priorityColor(p)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _priority == p
                                            ? _priorityColor(p)
                                            : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    p.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _priority == p
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // Assign to user
                  const Text('Assign Responsibility',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'user')
                        .snapshots(),
                    builder: (ctx, snap) {
                      final users = snap.data?.docs
                              .map((d) => UserModel.fromMap(
                                  d.data() as Map<String, dynamic>))
                              .toList() ??
                          [];
                      if (users.isEmpty) {
                        return const Text('No users found in database',
                            style: TextStyle(color: Color(0xFF94A3B8)));
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedUserId,
                        decoration: const InputDecoration(
                          labelText: 'Select collaborator',
                          prefixIcon: Icon(Icons.person_add_outlined),
                        ),
                        items: users
                            .map((u) => DropdownMenuItem(
                                  value: u.uid,
                                            child: Text(u.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedUserId = v);
                        },
                        validator: (v) =>
                            v == null ? 'Select a user' : null,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 40),
                PremiumButton(
                  onPressed: _submit,
                  icon: isCourseTask ? Icons.send_rounded : Icons.check_circle_rounded,
                  label: isCourseTask ? 'Publish to All Students' : 'Publish Task',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m];
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return kDanger;
      case 'low': return kSuccess;
      default: return kWarning;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }
}
