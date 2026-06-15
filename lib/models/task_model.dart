class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority; // 'low', 'medium', 'high'
  final String status;   // 'pending', 'submitted', 'in_process', 'verified', 'rejected'
  final String assignedTo; // uid
  final String assignedBy; // uid
  final String? courseId; // Optional: Link to a course
  final String? courseName; // Cached for easy display in reviews
  final String? studentName; // Cached for easy display in reviews
  final double? maxMarks; // Total possible marks
  final DateTime dueDate;
  final DateTime createdAt;
  final ProofModel? proof;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.assignedBy,
    this.courseId,
    this.courseName,
    this.studentName,
    this.maxMarks,
    required this.dueDate,
    required this.createdAt,
    this.proof,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      courseId: map['courseId'],
      courseName: map['courseName'],
      studentName: map['studentName'],
      maxMarks: map['maxMarks']?.toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      proof: map['proof'] != null
          ? ProofModel.fromMap(map['proof'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'courseId': courseId,
      'courseName': courseName,
      'studentName': studentName,
      'maxMarks': maxMarks,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'proof': proof?.toMap(),
    };
  }

  TaskModel copyWith({
    String? status, 
    ProofModel? proof,
    String? courseName,
    String? studentName,
    double? maxMarks,
  }) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      courseId: courseId,
      courseName: courseName ?? this.courseName,
      studentName: studentName ?? this.studentName,
      maxMarks: maxMarks ?? this.maxMarks,
      dueDate: dueDate,
      createdAt: createdAt,
      proof: proof ?? this.proof,
    );
  }
}

class ProofModel {
  final String? fileUrl;
  final String? fileType; // 'image', 'document', 'link'
  final String? link; // URL link
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime submittedAt;
  final String? adminNote;
  final double? marks;

  ProofModel({
    this.fileUrl,
    this.fileType,
    this.link,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.submittedAt,
    this.adminNote,
    this.marks,
  });

  factory ProofModel.fromMap(Map<String, dynamic> map) {
    return ProofModel(
      fileUrl: map['fileUrl'],
      fileType: map['fileType'],
      link: map['link'],
      locationAddress: map['locationAddress'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      submittedAt: DateTime.fromMillisecondsSinceEpoch(
        map['submittedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      adminNote: map['adminNote'],
      marks: map['marks']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileUrl': fileUrl,
      'fileType': fileType,
      'link': link,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'submittedAt': submittedAt.millisecondsSinceEpoch,
      'adminNote': adminNote,
      'marks': marks,
    };
  }
}
