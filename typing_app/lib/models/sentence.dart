class Sentence {
  final int id;
  final String text;
  final String language;
  final String difficulty;

  Sentence({
    required this.id,
    required this.text,
    required this.language,
    required this.difficulty,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'],
      text: json['text'],
      language: json['language'],
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'language': language,
      'difficulty': difficulty,
    };
  }
}
