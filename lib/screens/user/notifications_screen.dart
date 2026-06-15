import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedTo', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final title = data['title'] ?? '';
              final createdAt = DateTime.fromMillisecondsSinceEpoch(
                  data['createdAt'] ?? 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _notifBg(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_notifIcon(status),
                          color: _notifColor(status), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_notifTitle(status, title),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(_notifBody(status, title),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM, HH:mm').format(createdAt),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _notifIcon(String status) {
    switch (status) {
      case 'verified': return Icons.verified_outlined;
      case 'rejected': return Icons.cancel_outlined;
      case 'submitted': return Icons.upload_outlined;
      default: return Icons.assignment_outlined;
    }
  }

  Color _notifColor(String status) {
    switch (status) {
      case 'verified': return kSuccess;
      case 'rejected': return kDanger;
      case 'submitted': return kInfo;
      default: return kWarning;
    }
  }

  Color _notifBg(String status) {
    switch (status) {
      case 'verified': return const Color(0xFFF0FDF4);
      case 'rejected': return const Color(0xFFFEF2F2);
      case 'submitted': return const Color(0xFFEFF6FF);
      default: return const Color(0xFFFFF7ED);
    }
  }

  String _notifTitle(String status, String taskTitle) {
    switch (status) {
      case 'verified': return 'Task Verified ✅';
      case 'rejected': return 'Task Rejected ❌';
      case 'submitted': return 'Proof Submitted';
      default: return 'New Task Assigned';
    }
  }

  String _notifBody(String status, String taskTitle) {
    switch (status) {
      case 'verified':
        return '"$taskTitle" has been verified by admin.';
      case 'rejected':
        return '"$taskTitle" was rejected. Please resubmit.';
      case 'submitted':
        return 'Your proof for "$taskTitle" is under review.';
      default:
        return 'You have been assigned "$taskTitle".';
    }
  }
}
