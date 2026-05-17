class QuestionModel {
  final int id;
  final String question;
  final String answer;
  final String type;
  final List<String>? options;
  final String explanation;
  final String? passage; // Thêm trường chứa đoạn văn cho câu hỏi Đọc hiểu
  
  const QuestionModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.type,
    this.options,
    required this.explanation,
    this.passage, 
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      type: json['type'] as String,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String,
      passage: json['passage'] as String?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'type': type,
      if (options != null) 'options': options,
      'explanation': explanation,
      if (passage != null) 'passage': passage, 
    };
  }

  QuestionModel copyWith({
    int? id,
    String? question,
    String? answer,
    String? type,
    List<String>? options,
    String? explanation,
    String? passage, 
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      type: type ?? this.type,
      options: options ?? this.options,
      explanation: explanation ?? this.explanation,
      passage: passage ?? this.passage, 
    );
  }
}