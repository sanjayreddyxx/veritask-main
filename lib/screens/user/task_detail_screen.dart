import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../widgets/app_widgets.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  final _linkCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitProof() async {
    final link = _linkCtrl.text.trim();
    if (link.isEmpty) {
      _showSnack('Please enter a submission link (e.g., GitHub, Drive)');
      return;
    }

    if (!link.startsWith('http')) {
      _showSnack('Please enter a valid URL starting with http/https');
      return;
    }

    setState(() => _loading = true);
    try {
      final proof = ProofModel(
        link: link,
        fileType: 'link',
        submittedAt: DateTime.now(),
      );
      await _taskService.submitProof(taskId: widget.task.id, proof: proof);
      if (mounted) {
        _showSnack('Solution link submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final canSubmit = task.status == 'pending' || task.status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Solution Workbench',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            _InfoCard(task: task),
            const SizedBox(height: 24),

            // Existing submission view
            if (task.proof != null) ...[
              _ProofViewCard(proof: task.proof!),
              const SizedBox(height: 24),
            ],

            // Submission input section
            if (canSubmit) ...[
              const Text('Submit Your Solution',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _linkCtrl,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Paste project URL (GitHub, Google Drive, etc.)',
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.link_rounded, color: kPrimary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PremiumButton(
                onPressed: _submitProof,
                label: 'Submit solution link',
                icon: Icons.rocket_launch_rounded,
                isLoading: _loading,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TaskModel task;
  const _InfoCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ),
              StatusBadge(task.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(task.description,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
          const Divider(height: 24),
          _InfoRow(Icons.calendar_today_outlined, 'Due date',
              DateFormat('d MMM yyyy').format(task.dueDate)),
          const SizedBox(height: 8),
          _InfoRow(Icons.label_outline, 'Category', task.category),
          const SizedBox(height: 8),
          _InfoRow(Icons.flag_outlined, 'Priority',
              task.priority[0].toUpperCase() + task.priority.substring(1)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _ProofViewCard extends StatelessWidget {
  final ProofModel proof;
  const _ProofViewCard({required this.proof});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: kPrimary, size: 20),
              const SizedBox(width: 8),
              const Text('Submitted Solution',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(
                DateFormat('d MMM, HH:mm').format(proof.submittedAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (proof.link != null)
            GestureDetector(
              onTap: () => _launchURL(proof.link!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        color: Color(0xFF4F46E5), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Project Link',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F46E5))),
                          Text(proof.link!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E1B4B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ),
          if (proof.adminNote != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Review Note',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(proof.adminNote!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
