import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfValidationResult {
  final bool isValid;
  final String? errorMessage;

  const PdfValidationResult.ok()
      : isValid = true,
        errorMessage = null;

  const PdfValidationResult.error(this.errorMessage) : isValid = false;
}

class PdfValidator {
  static const int maxSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int minTotalTextChars = 300;
  static const int minCharsPerPage = 45;
  static const double maxImagePageRatio = 0.0;      // Không cho phép trang scan nào
  static const double maxVietnameseRatio = 0.08;
  static const double maxMathRatio = 0.06;
  static const double minEnglishRatio = 0.68;

  static PdfValidationResult validate({
    required String fileName,
    required int fileSizeBytes,
    required List<int> bytes,
  }) {
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return const PdfValidationResult.error('Chỉ chấp nhận file PDF (.pdf)');
    }

    if (fileSizeBytes > maxSizeBytes) {
      final mb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return PdfValidationResult.error('File quá lớn (${mb}MB). Giới hạn tối đa là 10MB.');
    }

    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
    } catch (_) {
      return const PdfValidationResult.error('File PDF bị hỏng hoặc không đọc được.');
    }

    try {
      return _analyzeDocument(document);
    } finally {
      document.dispose();
    }
  }

  static PdfValidationResult _analyzeDocument(PdfDocument doc) {
    final pageCount = doc.pages.count;
    if (pageCount == 0) {
      return const PdfValidationResult.error('File PDF không có trang nào.');
    }

    final extractor = PdfTextExtractor(doc);
    final StringBuffer fullText = StringBuffer();
    int scanPages = 0;
    int emptyPages = 0;

    for (int i = 0; i < pageCount; i++) {
      final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i).trim();
      final charCount = pageText.length;

      fullText.write(pageText);
      fullText.write(' ');

      if (charCount < minCharsPerPage) {
        final isScan = _isLikelyScanPage(pageText, charCount);
        if (isScan) {
          scanPages++;
        } else if (charCount == 0) {
          emptyPages++;
        }
      }
    }

    final totalText = fullText.toString().trim();

    if (totalText.length < minTotalTextChars) {
      return const PdfValidationResult.error(
        'Tài liệu quá ít nội dung text.\nVui lòng upload file PDF có chữ thật (không phải scan ảnh).',
      );
    }

    final validPages = pageCount - emptyPages;
    if (validPages > 0) {
      final scanRatio = scanPages / validPages;
      if (scanRatio > maxImagePageRatio) {
        return const PdfValidationResult.error(
          'File chứa trang scan ảnh.\nVui lòng chỉ upload file PDF có text thật (không phải file scan).',
        );
      }
    }

    return _analyzeLanguageContent(totalText);
  }

  //kiểm tra scan 
  static bool _isLikelyScanPage(String pageText, int charCount) {
    // Nếu trang có rất ít chữ → rất có khả năng là scan ảnh
    if (charCount < 20) return true;

    // Nếu trang có nhiều khoảng trắng bất thường hoặc rất ít từ
    final words = pageText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words < 8) return true;

    return false;
  }

  
  static PdfValidationResult _analyzeLanguageContent(String text) {
    int vietnamese = 0;
    int math = 0;
    int english = 0;
    int total = 0;

    for (final rune in text.runes) {
      total++;
      final code = rune;

      if (_isVietnamese(code)) {
        vietnamese++;
      } else if (_isMath(code)) math++;
      else if (_isEnglish(code)) english++;
    }

    if (total == 0) {
      return const PdfValidationResult.error('Không tìm thấy nội dung text nào.');
    }

    final viRatio = vietnamese / total;
    final mathRatio = math / total;
    final engRatio = english / total;

    if (viRatio > maxVietnameseRatio) {
      final pct = (viRatio * 100).round();
      return PdfValidationResult.error(
        'Tài liệu chứa quá nhiều tiếng Việt ($pct%).\nVui lòng upload tài liệu tiếng Anh thuần túy.',
      );
    }

    if (mathRatio > maxMathRatio) {
      final pct = (mathRatio * 100).round();
      return PdfValidationResult.error(
        'Tài liệu chứa quá nhiều ký tự toán học/công thức ($pct%).\nChỉ chấp nhận tài liệu ngôn ngữ thông thường.',
      );
    }

    if (engRatio < minEnglishRatio) {
      final pct = (engRatio * 100).round();
      return PdfValidationResult.error(
        'Nội dung tiếng Anh chỉ chiếm $pct% — quá thấp.\nVui lòng chọn tài liệu tiếng Anh rõ ràng.',
      );
    }

    return const PdfValidationResult.ok();
  }

  static bool _isVietnamese(int code) {
    return (code >= 0x1E00 && code <= 0x1EFF) ||
           (code >= 0x00C0 && code <= 0x01FF) ||
           const [0x0110, 0x0111, 0x0128, 0x0129, 0x0168, 0x0169].contains(code);
  }

  static bool _isMath(int code) {
    return (code >= 0x2200 && code <= 0x22FF) ||
           (code >= 0x2A00 && code <= 0x2AFF) ||
           (code >= 0x1D400 && code <= 0x1D7FF) ||
           (code >= 0x0391 && code <= 0x03C9);
  }

  static bool _isEnglish(int code) {
    return (code >= 65 && code <= 90) || 
           (code >= 97 && code <= 122) || 
           (code >= 48 && code <= 57) ||
           const [32, 33, 34, 39, 40, 41, 44, 45, 46, 58, 59, 63].contains(code);
  }
}