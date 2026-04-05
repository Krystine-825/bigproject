const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore }      = require('firebase-admin/firestore');
const { getStorage }        = require('firebase-admin/storage');
const OpenAI                = require('openai');
const pdfParse              = require('pdf-parse');

initializeApp();

const db      = getFirestore();
const storage = getStorage();
const openai  = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ════════════════════════════════════════════════════════════════════════════════
// Cloud Function: generateExamFromPdf
// ════════════════════════════════════════════════════════════════════════════════
exports.generateExamFromPdf = onCall(
  { timeoutSeconds: 300, memory: '512MiB' },
  async (request) => {
    const {
      classId, teacherId, pdfUrl,
      storagePath, extractedText, fileName, config,
    } = request.data;

    // ── Validate input ─────────────────────────────────────────────────────────
    if (!classId || !teacherId || !storagePath) {
      throw new HttpsError('invalid-argument', 'Thiếu tham số bắt buộc');
    }

    try {
      // ── Bước 1: Lấy text từ PDF ───────────────────────────────────────────────
      // Flutter đã extract và gửi lên để tiết kiệm thời gian,
      // nhưng nếu thiếu thì download và parse lại
      let rawText = extractedText && extractedText.trim().length > 100
        ? extractedText
        : await _extractTextFromStorage(storagePath);

      // ── Bước 2: Làm sạch text ────────────────────────────────────────────────
      const cleanedText = _cleanText(rawText);

      // ── Bước 3: Validate nội dung phía backend (double-check) ────────────────
      const contentCheck = _validateContent(cleanedText);
      if (!contentCheck.valid) {
        throw new HttpsError('invalid-argument', contentCheck.reason);
      }

      // ── Bước 4: Gọi OpenAI ───────────────────────────────────────────────────
      const questions = await _callOpenAI(cleanedText, config);

      // ── Bước 5: Lưu vào Firestore ────────────────────────────────────────────
      const examData = {
        title:           _generateTitle(fileName),
        class_id:        classId,
        teacher_id:      teacherId,
        source_pdf_name: fileName,
        storage_path:    storagePath,
        questions:       questions,
        status:          'draft',
        question_count:  questions.length,
        created_at:      new Date().toISOString(),
      };

      const docRef = await db.collection('exams').add(examData);

      return {
        success: true,
        exam: { exam_id: docRef.id, ...examData },
      };

    } catch (err) {
      console.error('generateExamFromPdf error:', err);
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', `Lỗi xử lý: ${err.message}`);
    }
  }
);


// ════════════════════════════════════════════════════════════════════════════════
// Helper: Download & extract text từ Storage
// ════════════════════════════════════════════════════════════════════════════════
async function _extractTextFromStorage(storagePath) {
  const bucket = storage.bucket();
  const file   = bucket.file(storagePath);
  const [buffer] = await file.download();

  const parsed = await pdfParse(buffer);
  const text   = parsed.text;

  if (!text || text.trim().length < 100) {
    throw new HttpsError(
      'invalid-argument',
      'PDF không đọc được text. Có thể là file scan ảnh.'
    );
  }
  return text;
}


// ════════════════════════════════════════════════════════════════════════════════
// Helper: Làm sạch text
// ════════════════════════════════════════════════════════════════════════════════
function _cleanText(raw) {
  return raw
    .replace(/\r\n/g, '\n')         // chuẩn hoá xuống dòng
    .replace(/\n{3,}/g, '\n\n')     // bỏ dòng trống thừa
    .replace(/[ \t]{2,}/g, ' ')     // bỏ space thừa
    .replace(/[^\x20-\x7E\n\u00C0-\u024F]/g, ' ') // giữ ASCII + Latin Extended
    .replace(/\s{2,}/g, ' ')        // clean lại space sau replace
    .trim();
}


// ════════════════════════════════════════════════════════════════════════════════
// Helper: Validate nội dung phía backend (double-check sau khi làm sạch)
// ════════════════════════════════════════════════════════════════════════════════
function _validateContent(text) {
  const total = text.length;
  if (total < 100) {
    return { valid: false, reason: 'Nội dung PDF quá ngắn sau khi xử lý' };
  }

  // Đếm ký tự tiếng Việt có dấu đặc trưng (ă, â, ê, ô, ơ, ư, đ và các biến thể)
  const viPattern = /[àáâãèéêìíòóôõùúăắặẳẵằấầẩẫậđêếệểễờớợởỡưứựừửữ]/gi;
  const viCount   = (text.match(viPattern) || []).length;
  if (viCount / total > 0.10) {
    return {
      valid: false,
      reason: `File chứa quá nhiều tiếng Việt (${((viCount/total)*100).toFixed(0)}%). Vui lòng dùng tài liệu tiếng Anh.`,
    };
  }

  // Ký tự toán học / công thức
  const mathPattern = /[∑∫∂√∞±×÷≤≥≠≈α-ωΑ-Ω²³⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉]/g;
  const mathCount   = (text.match(mathPattern) || []).length;
  if (mathCount / total > 0.05) {
    return {
      valid: false,
      reason: `File chứa quá nhiều ký tự toán học/công thức (${((mathCount/total)*100).toFixed(0)}%). Chỉ chấp nhận tài liệu ngôn ngữ thuần túy.`,
    };
  }

  // Tỉ lệ ký tự ASCII (a-z, A-Z, space, dấu câu cơ bản)
  const engPattern = /[a-zA-Z0-9 .,!?;:'"()\-\n]/g;
  const engCount   = (text.match(engPattern) || []).length;
  if (engCount / total < 0.55) {
    return {
      valid: false,
      reason: 'Nội dung tiếng Anh quá ít. Vui lòng chọn tài liệu tiếng Anh.',
    };
  }

  return { valid: true };
}


async function _callOpenAI(text, config) {
  const {
    questionCount = 10,
    easyRatio     = 0.4,
    mediumRatio   = 0.4,
    hardRatio     = 0.2,
    questionTypes = ['multiple_choice', 'fill_in', 'true_false'],
  } = config;

  const easyCount   = Math.round(questionCount * easyRatio);
  const mediumCount = Math.round(questionCount * mediumRatio);
  const hardCount   = questionCount - easyCount - mediumCount;

  // Cắt text nếu quá dài (GPT-4o context limit)
  const maxChars  = 12000;
  const inputText = text.length > maxChars
    ? text.slice(0, maxChars) + '\n\n[... nội dung đã được rút gọn ...]'
    : text;

  const typeInstructions = _buildTypeInstructions(questionTypes);
  const systemPrompt = _buildSystemPrompt(typeInstructions);
  const userPrompt   = _buildUserPrompt(
    inputText, easyCount, mediumCount, hardCount, questionTypes
  );

  const response = await openai.chat.completions.create({
    model:       'gpt-4o',
    temperature: 0.7,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user',   content: userPrompt   },
    ],
    response_format: { type: 'json_object' }, // đảm bảo trả về JSON
  });

  const raw  = response.choices[0].message.content;
  const parsed = JSON.parse(raw);

  if (!parsed.questions || !Array.isArray(parsed.questions)) {
    throw new Error('OpenAI trả về dữ liệu không đúng định dạng');
  }

  // Đánh số id từ 1
  return parsed.questions.map((q, i) => ({ ...q, id: i + 1 }));
}


// ─── Prompt hệ thống ──────────────────────────────────────────────────────────
function _buildSystemPrompt(typeInstructions) {
  return `You are an expert English language teacher creating exam questions from provided text.

STRICT RULES:
- Generate questions ONLY based on the provided text content
- All questions must test English language skills: grammar, vocabulary, comprehension, usage
- Do NOT create math, science, or formula-based questions
- Do NOT translate or use Vietnamese in any part of the output
- Every question must be answerable from the provided text

OUTPUT: Return a valid JSON object with this exact structure:
{
  "questions": [
    {
      "type": "multiple_choice" | "fill_in" | "true_false",
      "difficulty": "easy" | "medium" | "hard",
      "question": "string",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],  // only for multiple_choice
      "answer": "string",  // for MC: "A", "B", "C", or "D". For fill_in: the word/phrase. For T/F: "True" or "False"
      "explanation": "Brief explanation in English (1-2 sentences)"
    }
  ]
}

${typeInstructions}`;
}


// ─── Hướng dẫn theo từng loại câu hỏi ───────────────────────────────────────
function _buildTypeInstructions(types) {
  const instructions = [];

  if (types.includes('multiple_choice')) {
    instructions.push(`MULTIPLE CHOICE rules:
- Provide exactly 4 options (A, B, C, D)
- Only one correct answer
- Distractors must be plausible but clearly wrong
- Test grammar, vocabulary, or reading comprehension`);
  }

  if (types.includes('fill_in')) {
    instructions.push(`FILL IN THE BLANK rules:
- Use "___" to mark the blank in the question
- Answer is a single word or short phrase (max 4 words)
- Blank should test a key vocabulary word or grammar structure
- Context must make the answer clear`);
  }

  if (types.includes('true_false')) {
    instructions.push(`TRUE/FALSE rules:
- Statement must be unambiguously True or False based on the text
- Mix True and False answers roughly equally
- Avoid trivially obvious statements`);
  }

  return instructions.join('\n\n');
}


// ─── Prompt người dùng ───────────────────────────────────────────────────────
function _buildUserPrompt(text, easyCount, mediumCount, hardCount, types) {
  const typesLabel = types.map(t => ({
    multiple_choice: 'multiple_choice',
    fill_in:         'fill_in',
    true_false:      'true_false',
  }[t])).join(', ');

  return `Create English exam questions from the following text.

REQUIRED DISTRIBUTION:
- Easy questions: ${easyCount}
- Medium questions: ${mediumCount}
- Hard questions: ${hardCount}
- Question types to use: ${typesLabel}
- Spread the types as evenly as possible across difficulty levels

TEXT TO USE:
"""
${text}
"""

Generate exactly ${easyCount + mediumCount + hardCount} questions total. Return JSON only.`;
}


// ─── Sinh tiêu đề đề thi từ tên file ─────────────────────────────────────────
function _generateTitle(fileName) {
  return fileName
    .replace(/\.pdf$/i, '')
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .trim()
    || 'English Exam';
}