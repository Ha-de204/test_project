import 'dart:io';

class OcrService {

  Future<Map<String, dynamic>> scanReceipt(File image) async {

    await Future.delayed(const Duration(seconds: 2));

    // MOCK RESPONSE
    return {
      "amount": 125000,
      "type": "expense",
      "title": "Highlands Coffee",
      "note": "Trà đào",
      "date": DateTime.now().toIso8601String(),
      "categorySuggestion": "Đồ ăn",
    };
  }
}