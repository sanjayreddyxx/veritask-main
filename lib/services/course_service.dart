import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create course (admin only)
  Future<void> createCourse(CourseModel course) async {
    final id = _uuid.v4();
    final newCourse = CourseModel(
      id: id,
      title: course.title,
      description: course.description,
      instructor: course.instructor,
      authorId: course.authorId,
      duration: course.duration,
      category: course.category,
      imageUrl: course.imageUrl,
      createdAt: DateTime.now(),
    );
    await _db.collection('courses').doc(id).set(newCourse.toMap());
  }

  // Get all courses (visible to everyone)
  Stream<List<CourseModel>> getCourses() {
    return _db
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get courses by a specific author
  Stream<List<CourseModel>> getCoursesByAuthor(String authorId) {
    return _db
        .collection('courses')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update course (admin only)
  Future<void> updateCourse(CourseModel course) async {
    await _db.collection('courses').doc(course.id).update(course.toMap());
  }

  // Delete course (admin only)
  Future<void> deleteCourse(String courseId) async {
    await _db.collection('courses').doc(courseId).delete();
  }

  // ─── Enrollment Logic ───────────────────────────────────────────

  // Student requests enrollment
  Future<void> requestEnrollment({
    required String courseId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final id = '${courseId}_$userId';
    final enrollment = EnrollmentModel(
      id: id,
      courseId: courseId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      status: EnrollmentStatus.pending,
      updatedAt: DateTime.now(),
    );
    await _db.collection('enrollments').doc(id).set(enrollment.toMap());
  }

  // Admin gets all enrollments for a course
  Stream<List<EnrollmentModel>> getEnrollmentsForCourse(String courseId) {
    return _db
        .collection('enrollments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EnrollmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Admin updates status (accept/reject)
  Future<void> updateEnrollmentStatus(String enrollmentId, EnrollmentStatus status) async {
    await _db.collection('enrollments').doc(enrollmentId).update({
      'status': status.toString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Check if user is enrolled or has pending request
  Stream<EnrollmentModel?> getUserEnrollment(String courseId, String userId) {
    return _db
        .collection('enrollments')
        .doc('${courseId}_$userId')
        .snapshots()
        .map((doc) => doc.exists ? EnrollmentModel.fromMap(doc.data()!, doc.id) : null);
  }

  // Get courses a user is accepted into
  Stream<List<CourseModel>> getEnrolledCourses(String userId) {
    return _db
        .collection('enrollments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EnrollmentStatus.accepted.toString())
        .snapshots()
        .asyncMap((snap) async {
          List<CourseModel> courses = [];
          for (var doc in snap.docs) {
            final enrollment = EnrollmentModel.fromMap(doc.data(), doc.id);
            final cDoc = await _db.collection('courses').doc(enrollment.courseId).get();
            if (cDoc.exists) {
              courses.add(CourseModel.fromMap(cDoc.data()!, cDoc.id));
            }
          }
          return courses;
        });
  }
}
