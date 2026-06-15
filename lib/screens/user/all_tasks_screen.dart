import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../widgets/app_widgets.dart';
import 'task_detail_screen.dart';

class AllTasksScreen extends StatefulWidget {
  final String uid;
  const AllTasksScreen({super.key, required this.uid});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final _taskService = TaskService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('My Learning Tasks', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            pinned: true,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildFilterBar(),
            ),
          ),
          StreamBuilder<List<TaskModel>>(
            stream: _taskService.getUserTasks(widget.uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              var tasks = snap.data ?? [];
              if (_filter != 'all') {
                tasks = tasks.where((t) => t.status == _filter).toList();
              }
              
              if (tasks.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No ${_filter == 'all' ? '' : _filter} tasks found',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final t = tasks[i];
                      return TaskCard(
                        title: t.title,
                        dueDate: DateFormat('d MMM yyyy').format(t.dueDate),
                        status: t.status,
                        priority: t.priority,
                        category: t.category,
                        progress: _statusProgress(t.status),
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t)),
                        ),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'All Tasks'),
      ('pending', 'Pending'),
      ('submitted', 'Reviewing'),
      ('verified', 'Completed'),
      ('rejected', 'Redo'),
    ];
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final active = _filter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: active ? kPrimary : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? kPrimary : const Color(0xFFE2E8F0)),
                boxShadow: active ? [BoxShadow(color: kPrimary.withAlpha(51), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Center(
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'verified': return 1.0;
      case 'submitted': return 0.75;
      case 'rejected': return 0.25;
      default: return 0.1;
    }
  }
}
