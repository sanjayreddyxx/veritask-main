enum EnrollmentStatus { pending, accepted, rejected }

class EnrollmentModel {
  final String id;
  final String courseId;
  final String userId;
  final String userName;
  final String userEmail;
  final EnrollmentStatus status;
  final DateTime updatedAt;

  EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.updatedAt,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return EnrollmentModel(
      id: docId,
      courseId: map['courseId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      userEmail: map['userEmail'] ?? '',
      status: EnrollmentStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => EnrollmentStatus.pending,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'status': status.toString(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
