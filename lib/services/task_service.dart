import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Create task (admin)
  Future<void> createTask(TaskModel task) async {
    final id = _uuid.v4();
    await _db.collection('tasks').doc(id).set(task.toMap());
  }

  // Get tasks for a user
  Stream<List<TaskModel>> getUserTasks(String uid) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get all tasks (admin)
  Stream<List<TaskModel>> getAllTasks() {
    return _db
        .collection('tasks')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get tasks for review (submitted or in_process)
  Stream<List<TaskModel>> getReviewableTasks() {
    return _db
        .collection('tasks')
        .where('status', whereIn: ['submitted', 'in_process'])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Upload proof file to Firebase Storage
  Future<String> uploadProofFile(XFile file, String taskId) async {
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    final ref = _storage.ref('proofs/$taskId/${_uuid.v4()}.$ext');
    
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        final uploadTask = ref.putData(
          bytes, 
          SettableMetadata(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}')
        );
        final snapshot = await uploadTask.timeout(const Duration(seconds: 90));
        return await snapshot.ref.getDownloadURL();
      } else {
        final uploadTask = ref.putFile(File(file.path));
        final snapshot = await uploadTask.timeout(const Duration(seconds: 90));
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      throw 'Upload failed (Network/Timeout). Please check your connection and try again.';
    }
  }

  // Submit proof
  Future<void> submitProof({
    required String taskId,
    required ProofModel proof,
  }) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'submitted',
      'proof': proof.toMap(),
    });
  }

  // Mark task as in process when admin starts reviewing
  Future<void> markTaskInProcess(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'in_process',
    });
  }

  // Admin: verify task with marks and note
  Future<void> verifyTask(String taskId, {required double marks, String? note}) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'verified',
      'proof.marks': marks,
      'proof.adminNote': note ?? 'Approved - Task Completed',
    });
  }

  // Admin: reject task
  Future<void> rejectTask(String taskId, {String? note}) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'rejected',
      'proof.adminNote': note ?? 'Rejected — insufficient proof',
    });
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // Get task stats for a user
  Future<Map<String, int>> getUserTaskStats(String uid) async {
    final snap = await _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .get();
    int total = snap.docs.length;
    int pending = 0, submitted = 0, verified = 0, rejected = 0;
    for (var doc in snap.docs) {
      final status = doc.data()['status'] ?? '';
      if (status == 'pending') {
        pending++;
      } else if (status == 'submitted') {
        submitted++;
      } else if (status == 'verified') {
        verified++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }
    return {
      'total': total,
      'pending': pending,
      'submitted': submitted,
      'verified': verified,
      'rejected': rejected,
    };
  }

  // Get tasks for a specific course
  Stream<List<TaskModel>> getTasksForCourse(String courseId) {
    return _db
        .collection('tasks')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
