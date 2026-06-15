class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String? authorId; // UID of the admin who created it
  final String duration;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    this.authorId,
    required this.duration,
    required this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CourseModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      authorId: map['authorId'],
      duration: map['duration'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructor': instructor,
      'authorId': authorId,
      'duration': duration,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  CourseModel copyWith({
    String? title,
    String? description,
    String? instructor,
    String? authorId,
    String? duration,
    String? category,
    String? imageUrl,
  }) {
    return CourseModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      authorId: authorId ?? this.authorId,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
