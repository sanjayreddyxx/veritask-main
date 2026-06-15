import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../widgets/app_widgets.dart';

class AdminReviewScreen extends StatelessWidget {
  final TaskService taskService;
  final String? singleTaskId;
  const AdminReviewScreen({super.key, required this.taskService, this.singleTaskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(singleTaskId != null ? 'Submission Details' : 'Evaluation Center'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: singleTaskId != null ? taskService.getAllTasks() : taskService.getReviewableTasks(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var tasks = snap.data ?? [];
          
          if (singleTaskId != null) {
             tasks = tasks.where((t) => t.id == singleTaskId).toList();
          }

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        size: 64, color: kPrimary),
                  ),
                  const SizedBox(height: 24),
                  const Text('All caught up!',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  const Text('No submissions found',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (ctx, i) =>
                _ReviewCard(
                  task: tasks[i], 
                  taskService: taskService,
                  startExpanded: singleTaskId != null,
                ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final TaskModel task;
  final TaskService taskService;
  final bool startExpanded;
  const _ReviewCard({
    required this.task, 
    required this.taskService, 
    this.startExpanded = false
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _loading = false;
  late bool _expanded;
  final _noteCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  Future<void> _verify() async {
    final marks = double.tryParse(_marksCtrl.text.trim()) ?? 0;
    setState(() => _loading = true);
    await widget.taskService.verifyTask(
      widget.task.id,
      marks: marks,
      note: _noteCtrl.text.trim().isNotEmpty
          ? _noteCtrl.text.trim()
          : 'Approved - Excellent Work',
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleExpand() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && widget.task.status == 'submitted') {
      await widget.taskService.markTaskInProcess(widget.task.id);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    await widget.taskService.rejectTask(widget.task.id,
        note: _noteCtrl.text.trim().isNotEmpty
            ? _noteCtrl.text.trim()
            : 'Rejected — insufficient proof');
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final proof = task.proof;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    _buildStatusBadge(task.status),
                  ],
                ),
                if (task.courseName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Course: ${task.courseName}',
                      style: const TextStyle(
                          fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                   const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                   const SizedBox(width: 4),
                   Text(
                    task.studentName ?? 'Student',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM, HH:mm').format(proof?.submittedAt ?? task.createdAt),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: _toggleExpand,
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proof != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted: ${DateFormat('d MMM yyyy, HH:mm').format(proof.submittedAt)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (proof.fileUrl != null) ...[
                      const Text('Proof image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          proof.fileUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (proof.locationAddress != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: kSuccess, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(proof.locationAddress!, style: const TextStyle(fontSize: 12, color: Color(0xFF166534)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ] else ...[
                     const Center(
                       child: Padding(
                         padding: EdgeInsets.symmetric(vertical: 20),
                         child: Text('Task not yet submitted', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                       ),
                     ),
                  ],

                  if (task.status == 'submitted' || task.status == 'in_process') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _marksCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Marks/Score',
                              hintText: task.maxMarks != null ? 'Max: ${task.maxMarks!.toInt()}' : 'e.g. 95',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              labelText: 'Feedback',
                              hintText: 'Good job!',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _reject,
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: kDanger), padding: const EdgeInsets.symmetric(vertical: 14)),
                                  child: const Text('Reject', style: TextStyle(color: kDanger)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _verify,
                                  style: ElevatedButton.styleFrom(backgroundColor: kSuccess, padding: const EdgeInsets.symmetric(vertical: 14)),
                                  child: const Text('Complete Review', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    String label;
    switch (status) {
      case 'in_process': bg = const Color(0xFFFEF9C3); text = const Color(0xFF854D0E); label = 'IN PROCESS'; break;
      case 'submitted': bg = const Color(0xFFEFF6FF); text = kInfo; label = 'WAITING'; break;
      case 'verified': bg = const Color(0xFFF0FDF4); text = kSuccess; label = 'COMPLETED'; break;
      case 'rejected': bg = const Color(0xFFFEF2F2); text = kDanger; label = 'REJECTED'; break;
      default: bg = const Color(0xFFF1F5F9); text = const Color(0xFF64748B); label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }
}
