class Question {
  final int? id;
  final String imagePath;
  final String subject;
  final String topic;
  final String exam;
  final String? note; // Opsiyonel (nullable) not alanı
  final String? category; // Yeni özellik: İsteğe bağlı (nullable) etiket alanı
  final String nextReviewDate;
  final int isLearned; // 0 veya 1 (SQLite bool tutmuyor)
  
  // Gelecek özellikler için alanlar
  final DateTime createdAt;
  final int interval;
  final double easeFactor;
  final int reviewCount;

  Question({
    this.id,
    required this.imagePath,
    required this.subject,
    required this.topic,
    required this.exam,
    this.note,
    this.category,
    required this.nextReviewDate,
    this.isLearned = 0,
    required this.createdAt,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.reviewCount = 0,
  });

  // DB'den okumak için
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      imagePath: map['imagePath'],
      subject: map['subject'],
      topic: map['topic'],
      exam: map['exam'] ?? 'Genel',
      note: map['note'],
      category: map['category'],
      nextReviewDate: map['nextReviewDate'],
      isLearned: map['isLearned'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      interval: map['interval'],
      easeFactor: map['easeFactor'],
      reviewCount: map['reviewCount'],
    );
  }

  // DB'ye yazmak için
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'subject': subject,
      'topic': topic,
      'exam': exam,
      'note': note,
      'category': category,
      'nextReviewDate': nextReviewDate,
      'isLearned': isLearned,
      'createdAt': createdAt.toIso8601String(),
      'interval': interval,
      'easeFactor': easeFactor,
      'reviewCount': reviewCount,
    };
  }

  // Obje kopyalamak için
  Question copyWith({
    int? id,
    String? imagePath,
    String? subject,
    String? topic,
    String? exam,
    String? note,
    String? category,
    String? nextReviewDate,
    int? isLearned,
    DateTime? createdAt,
    int? interval,
    double? easeFactor,
    int? reviewCount,
  }) {
    return Question(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      exam: exam ?? this.exam,
      note: note ?? this.note,
      category: category ?? this.category,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      isLearned: isLearned ?? this.isLearned,
      createdAt: createdAt ?? this.createdAt,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
