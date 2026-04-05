class QuestionModel {
  final int id;
  final String question;
  final String answer;
  final String type;
  final String difficulty;
  final List<String>? options;
  final String explanation;
  const QuestionModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.type,
    required this.difficulty,
    this.options,
    required this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      options: (json['options'] as List<dynamic>?)
          ?.map((e)=>e.toString()).toList(),
       explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'type': type,
      'difficulty': difficulty,
      if(options!=null) 'options': options,
      'explanation': explanation,
    };
  }

  QuestionModel copyWith({
    int? id,
    String? question,
    String? answer,
    String? type,
    String? difficulty,
    List<String>? options,
    String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      options: options ?? this.options,
      explanation: explanation ?? this.explanation,
    );
  }
}