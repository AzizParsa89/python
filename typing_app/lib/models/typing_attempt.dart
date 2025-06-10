class TypingAttempt {
  final int? id;
  final int userId; // Or a User object if you prefer to nest it
  final int sentenceId; // Or a Sentence object
  final String typedText;
  final double timeTakenSeconds;
  final double? accuracy; // Calculated by backend
  final int? wpm; // Calculated by backend
  final DateTime? submittedAt; // Set by backend

  TypingAttempt({
    this.id,
    required this.userId,
    required this.sentenceId,
    required this.typedText,
    required this.timeTakenSeconds,
    this.accuracy,
    this.wpm,
    this.submittedAt,
  });

  factory TypingAttempt.fromJson(Map<String, dynamic> json) {
    return TypingAttempt(
      id: json['id'],
      userId: json['user'], // Assuming backend returns user ID
      sentenceId: json['sentence'], // Assuming backend returns sentence ID
      typedText: json['typed_text'],
      timeTakenSeconds: (json['time_taken_seconds'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      wpm: json['wpm'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // For sending to backend, we might only need a subset of fields
    return {
      // 'id': id, // Usually not sent for creation
      'user': userId,
      'sentence': sentenceId,
      'typed_text': typedText,
      'time_taken_seconds': timeTakenSeconds,
      // Accuracy and WPM are calculated by the backend, so not sent
    };
  }
}
