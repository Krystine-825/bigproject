import 'package:cloud_functions/cloud_functions.dart';

class OpenAIFunctionService {
  final _fn = FirebaseFunctions.instance.httpsCallable('generateExamFromPdf');

  Future<Map<String, dynamic>> generateExam(Map<String, dynamic> payload) async {
    final result = await _fn.call<Map<String, dynamic>>(payload);
    if (result.data['success'] != true) {
      throw Exception(result.data['error'] ?? 'Tạo đề thất bại');
    }
    return result.data['exam'] as Map<String, dynamic>;
  }
}