

function cleanText(raw) {
  return raw
    .replace(/\r\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .replace(/[^\x20-\x7E\n\u00C0-\u024F]/g, ' ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function validateContent(text) {
  const normalizedText = text.normalize('NFC');
  const cleanStr = normalizedText.replace(/\s+/g, '');
  const totalChars = cleanStr.length;

  if (totalChars < 50) return { valid: false, reason: 'Nội dung PDF quá ngắn (dưới 50 ký tự).' };

  const viCount = (cleanStr.match(/[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/gi) || []).length;
  if (viCount / totalChars > 0.5) return { valid: false, reason: 'File chứa quá nhiều tiếng Việt.' };

  const mathCount = (cleanStr.match(/[∑∫∂√∞±×÷≤≥≠≈α-ωΑ-Ω²³⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉]/g) || []).length;
  if (mathCount / totalChars > 0.05) return { valid: false, reason: 'File chứa quá nhiều ký tự toán học.' };

  const engCount = (cleanStr.match(/[a-zA-Z0-9.,!?;:'"()\[\]\-_]/g) || []).length;
  if (engCount / totalChars < 0.70) return { valid: false, reason: 'Nội dung tiếng Anh quá ít hoặc bị lỗi font.' };

  return { valid: true };
}

function generateTitle(fileName) {
  return fileName
    .replace(/\.pdf$/i, '')
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .trim() || 'English Exam';
}

module.exports = { cleanText, validateContent, generateTitle };