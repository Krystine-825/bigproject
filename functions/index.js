/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.

//setGlobalOptions({ maxInstances: 100 });
// chỗ này quyết định được bao nhiêu người xài chức năng sinh đề, có thẻ xóa luôn dòng này để Firebase tự scale 
/* thật ra nguyên lý của nó sẽ giống như là tạo tối đa 100 máy chủ ảo chạy song song. 
Nếu có 101 giáo viên bấm tạo đề cùng một phần ngàn giây, người thứ 101 sẽ bị đưa vào hàng đợi cho đến khi 1 trong 100 người kia xong. 
Cho nên cái số maxInstances mình bật thì số người dùng đợi 1 khoảng như nhau thôi, nên tối ưu nữa thì chỉ có đổi model khác :v*/

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


require("dotenv").config(); 
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore'); // Đã thêm FieldValue để lưu thời gian
const { getStorage }        = require('firebase-admin/storage');
const OpenAI                = require('openai');

initializeApp();

const db      = getFirestore();
const storage = getStorage();
const openai  = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Cloud Function: generateExamFromPdf
exports.generateExamFromPdf = onCall(
  { timeoutSeconds: 300, memory: '512MiB' },
  async (request) => {
    const {
      teacherId, pdfUrl,
      storagePath, extractedText, fileName, config,
    } = request.data;

    // Validate input
    if (!teacherId || !storagePath) {
      throw new HttpsError('invalid-argument', 'Thiếu tham số bắt buộc');
    }

    
    //GIỚI HẠN 2 ĐỀ / NGÀY
    const MAX_EXAMS_PER_DAY = 2;
    const today = new Date().toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
    const quotaRef = db.collection('ai_quotas').doc(teacherId);
    const quotaDoc = await quotaRef.get();
    let usageCount = 0;

    if (quotaDoc.exists) {
      const quotaData = quotaDoc.data();
      if (quotaData.date === today) {
        usageCount = quotaData.count || 0;
        if (usageCount >= MAX_EXAMS_PER_DAY) {
          logger.warn(`[QUOTA] Giáo viên ${teacherId} đã hết lượt hôm nay.`);
          throw new HttpsError(
            'resource-exhausted', 
            `Bạn đã sử dụng hết ${MAX_EXAMS_PER_DAY} lượt tạo đề bằng AI của ngày hôm nay. Vui lòng quay lại vào ngày mai nhé!`
          );
        }
      }
    }

    try {
      // Đã xóa cơ chế fallback parse PDF vì backend không còn thư viện pdf-parse
      if (!extractedText || extractedText.trim().length < 100) {
        throw new HttpsError(
          'invalid-argument',
          'Nội dung văn bản trống. Vui lòng đảm bảo file PDF có thể đọc được chữ.'
        );
      }
      const rawText = extractedText;

      // làm sạch text
      const cleanedText = _cleanText(rawText);

      // Validate nội dung phía backend (double-check)
      const contentCheck = _validateContent(cleanedText);
      if (!contentCheck.valid) {
        throw new HttpsError('invalid-argument', contentCheck.reason);
      }

      // Cộng lượt trước khi gọi AI để khóa spam
      await quotaRef.set({
        date: today,
        count: usageCount + 1,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      let questions;
      try {
        // Gọi OpenAI (Bắt đầu chờ 30 - 60s)
        questions = await _callOpenAI(cleanedText, config);
      } catch (aiError) {
        // nếu ai bị lỗi thì hoàn lại lượt lại cho người dùng
        await quotaRef.set({
          count: Math.max(0, usageCount), // Trả về số đếm cũ trước khi bấm
          updatedAt: FieldValue.serverTimestamp()
        }, { merge: true });
        
        throw aiError; // Ném lỗi ra để khối catch tổng bắt lấy
      }

      // Lưu vào Firestore
      const examData = {
        title:           _generateTitle(fileName),
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

  const MAX_CHARS = 40000; // 
  if (text.length > MAX_CHARS) {
    throw new HttpsError('out-of-range', `File quá dài (${text.length} ký tự). Vui lòng tách nhỏ PDF và tải lên dưới ${MAX_CHARS} ký tự để AI xử lý tốt nhất.`);
  }

  return text; 
}

function _cleanText(raw) {
  return raw
    .replace(/\r\n/g, '\n')         // chuẩn hoá xuống dòng
    .replace(/\n{3,}/g, '\n\n')     // bỏ dòng trống thừa
    .replace(/[ \t]{2,}/g, ' ')     // bỏ space thừa
    .replace(/[^\x20-\x7E\n\u00C0-\u024F]/g, ' ') // giữ ASCII + Latin Extended
    .replace(/\s{2,}/g, ' ')        // clean lại space sau replace
    .trim();
}

/*
function _validateContent(text) {
  // Loại bỏ khoảng trắng và xuống dòng để tính tỷ lệ chính xác (Chỉ đếm chữ và số)
  const cleanText = text.replace(/\s+/g, '');
  const totalChars = cleanText.length;

  if (totalChars < 50) { 
    return { valid: false, reason: 'Nội dung PDF quá ngắn sau khi xử lý.' };
  }

  // 1. Tối ưu Regex tiếng Việt (Đủ 134 ký tự có dấu)
  const viPattern = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/gi;
  const viCount   = (cleanText.match(viPattern) || []).length;
  const viRatio   = viCount / totalChars;
  
  if (viRatio > 0.05) { 
    return {
      valid: false,
      reason: `File chứa tiếng Việt (${(viRatio * 100).toFixed(1)}%). Vui lòng dùng tài liệu tiếng Anh.`,
    };
  }

  // 2. Ký tự toán học / công thức
  const mathPattern = /[∑∫∂√∞±×÷≤≥≠≈α-ωΑ-Ω²³⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉]/g;
  const mathCount   = (cleanText.match(mathPattern) || []).length;
  const mathRatio   = mathCount / totalChars;

  if (mathRatio > 0.05) {
    return {
      valid: false,
      reason: `File chứa quá nhiều ký tự toán học/công thức (${(mathRatio * 100).toFixed(1)}%). Chỉ chấp nhận tài liệu ngôn ngữ thuần túy.`,
    };
  }

  // 3. Tỉ lệ ký tự ASCII (Tiếng Anh + Số + Dấu câu)
  const engPattern = /[a-zA-Z0-9.,!?;:'"()\-]/g;
  const engCount   = (cleanText.match(engPattern) || []).length;
  const engRatio   = engCount / totalChars;

  if (engRatio < 0.70) { 
    return {
      valid: false,
      reason: 'Nội dung tiếng Anh quá ít hoặc file bị mã hóa lỗi. Vui lòng chọn tài liệu tiếng Anh chuẩn.',
    };
  }

  return { valid: true };
}
*/
function _validateContent(text) {
  // chuẩn hóa Unicode cho PDF 
  // gộp các ký tự bị tách dấu (NFD) thành ký tự hoàn chỉnh (NFC) để Regex nhận diện chính xác
  const normalizedText = text.normalize('NFC');
  
  // loại bỏ khoảng trắng và xuống dòng để tính toán tỷ lệ trên nội dung thực
  const cleanText = normalizedText.replace(/\s+/g, '');
  const totalChars = cleanText.length;

  // 1. Kiểm tra độ dài tối thiểu
  if (totalChars < 50) { 
    return { valid: false, reason: 'Nội dung PDF quá ngắn sau khi xử lý (dưới 50 ký tự).' };
  }

  // chặn Tiếng Việt (chặn file có > 50% tiếng Việt)
  const viPattern = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/gi;
  const viCount   = (cleanText.match(viPattern) || []).length;
  const viRatio   = viCount / totalChars;
  
  if (viRatio > 0.5) { 
    return {
      valid: false,
      reason: `File chứa tiếng Việt (${(viRatio * 100).toFixed(1)}%). Vui lòng dùng tài liệu tiếng Anh.`,
    };
  }

  // chặn Ký tự toán học / công thức phức tạp 
  const mathPattern = /[∑∫∂√∞±×÷≤≥≠≈α-ωΑ-Ω²³⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉]/g;
  const mathCount   = (cleanText.match(mathPattern) || []).length;
  const mathRatio   = mathCount / totalChars;

  if (mathRatio > 0.05) {
    return {
      valid: false,
      reason: `File chứa quá nhiều ký tự toán học/công thức (${(mathRatio * 100).toFixed(1)}%). Chỉ chấp nhận tài liệu ngôn ngữ thuần túy.`,
    };
  }

  // kiểm tra tỷ lệ tiếng Anh chuẩn (ASCII + Dấu câu)
  // đã bao gồm các dấu gạch dưới ___ và ngoặc vuông [] thường dùng trong đề thi
  const engPattern = /[a-zA-Z0-9.,!?;:'"()\[\]\-_]/g;
  const engCount   = (cleanText.match(engPattern) || []).length;
  const engRatio   = engCount / totalChars;

  if (engRatio < 0.70) { 
    return {
      valid: false,
      reason: 'Nội dung tiếng Anh quá ít hoặc file bị mã hóa lỗi. Vui lòng chọn tài liệu tiếng Anh chuẩn.',
    };
  }

  return { valid: true };
}


async function _callOpenAI(text, config) {
  const {
    questionCount = 10,
    questionTypes = ['multiple_choice', 'fill_in', 'true_false'],
  } = config;

  // 1 Đề có 3 phần: 40% Dễ, 40% TB, 20% Khó)
  const easyCount   = Math.round(questionCount * 0.4);
  const mediumCount = Math.round(questionCount * 0.4);
  const hardCount   = questionCount - easyCount - mediumCount;

  // Cắt text nếu quá dài (GPT-4o context limit)
  const maxChars = 40000; 
  let inputText = text;

  if (text.length > maxChars) {
    // tránh cắt ngang từ/ngang câu
    const snippet = text.slice(0, maxChars);
    
    // tìm vị trí kết thúc câu an toàn (dấu chấm, hỏi, than, xuống dòng)
    const safeCutIndex = Math.max(
      snippet.lastIndexOf('. '),
      snippet.lastIndexOf('? '),
      snippet.lastIndexOf('! '),
      snippet.lastIndexOf('\n')
    );

    // nếu tìm thấy điểm cắt an toàn (gần cuối đoạn), thì cắt ở đó không thì đành cắt cứng.
    const finalCut = safeCutIndex > (maxChars - 500) ? safeCutIndex + 1 : maxChars;
    
    inputText = text.slice(0, finalCut) + '\n\n[... phần còn lại của tài liệu đã được rút gọn để tối ưu AI ...]';
    
    logger.info(`[TỐI ƯU TEXT] File quá dài (${text.length} ký tự). Đã cắt an toàn tại ký tự thứ ${finalCut}.`);
  }

  // khởi tạo Prompt 1 lần duy nhất ở ngoài để tối ưu hiệu năng
  const typeInstructions = _buildTypeInstructions(questionTypes);
  const systemPrompt = _buildSystemPrompt(typeInstructions);
  const userPrompt   = _buildUserPrompt(
    inputText, easyCount, mediumCount, hardCount, questionTypes
  );

  // retry: tối đa thử 3 lần
  const MAX_RETRIES = 3;
  
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      logger.info(`[OPENAI] Bắt đầu gọi API sinh đề (Lần thử: ${attempt}/${MAX_RETRIES})...`);
      
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

      // thống kê Token
      const charCount = raw.length;
      logger.info(`[THỐNG KÊ AI] Số ký tự AI sinh ra: ${charCount} ký tự.`);

      if (response.usage) {
        const promptTokens = response.usage.prompt_tokens;      
        const completionTokens = response.usage.completion_tokens;
        const totalTokens = response.usage.total_tokens;        
        logger.info(`[THỐNG KÊ TOKEN] Đầu vào: ${promptTokens} | Đầu ra: ${completionTokens} | Tổng cộng: ${totalTokens}`);
      }
     
      const parsed = JSON.parse(raw);

      if (!parsed.questions || !Array.isArray(parsed.questions)) {
        throw new Error('OpenAI trả về dữ liệu không đúng định dạng (Thiếu mảng questions).');
      }

      // sắp xếp câu hỏi từ Dễ -> Trung Bình -> Khó để tạo 3 phần rõ rệt
      const diffOrder = { 'easy': 1, 'medium': 2, 'hard': 3 };
      const sortedQuestions = parsed.questions.sort((a, b) => diffOrder[a.difficulty] - diffOrder[b.difficulty]);

      // đánh số id từ 1 sau khi đã sắp xếp và TRẢ VỀ KẾT QUẢ THÀNH CÔNG
      return sortedQuestions.map((q, i) => ({ ...q, id: i + 1 }));

    } catch (error) {
      logger.warn(`[OPENAI ERROR] Lỗi ở lần thử thứ ${attempt}: ${error.message}`);
      
      // nếu đã thử hết số lần cho phép thì ném lỗi ra ngoài cho hàm cha bắt (và hoàn trả lượt sinh đề cho user)
      if (attempt === MAX_RETRIES) {
        throw new Error(`Quá trình sinh đề thất bại sau ${MAX_RETRIES} lần thử: ${error.message}`);
      }

      // back off: tạm ghỉ trước khi thử lại (tránh bị rate limit)
      // lần 1 lỗi->nghỉ 2 giây. lần 2 lỗi->nghỉ 4 giây.
      const delayMs = attempt * 2000; 
      logger.info(`[RETRY] Đang chờ ${delayMs}ms trước khi thử lại...`);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
}

// prompt hệ thống
function _buildSystemPrompt(typeInstructions) {
  return `You are an expert English language teacher creating exam questions from provided text.

STRICT RULES:
- Generate questions ONLY based on the provided text content.
- All questions must test English language skills: grammar, vocabulary, comprehension, usage.
- Do NOT create math, science, or formula-based questions.
- Do NOT translate or use Vietnamese in any part of the output.
- Every question must be answerable directly from the provided text.

DIFFICULTY GUIDELINES:
- Easy: Basic factual recall and direct vocabulary identification from the text.
- Medium: Understanding main ideas, simple inferences, and grammar application.
- Hard: Complex inferences, analyzing author's tone, or deducing the meaning of advanced vocabulary from context.

OUTPUT: Return a valid JSON object with this exact structure:
{
  "questions": [
    {
      "type": "multiple_choice" | "fill_in" | "true_false",
      "difficulty": "easy" | "medium" | "hard",
      "question": "string",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],  // For multiple_choice ONLY. MUST include "A.", "B.", "C.", "D." prefixes.
      "answer": "string",  // For MC: strictly "A", "B", "C", or "D". For fill_in: the exact word/phrase. For T/F: "True" or "False".
      "explanation": "Brief explanation in English detailing why this answer is correct based on the text (1-2 sentences)."
    }
  ]
}

${typeInstructions}`;
}


// hướng dẫn theo từng loại câu hỏi 
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


// prompt người dùng
function _buildUserPrompt(text, easyCount, mediumCount, hardCount, types) {
  const typesLabel = types.map(t => ({
    multiple_choice: 'multiple_choice',
    fill_in:         'fill_in',
    true_false:      'true_false',
  }[t])).join(', ');

  return `Create English exam questions based strictly on the text provided below.

TASK REQUIREMENTS:
1. Difficulty Quotas: You MUST generate EXACTLY ${easyCount} Easy, ${mediumCount} Medium, and ${hardCount} Hard questions.
2. Permitted Types: Use ONLY these formats: ${typesLabel}.
3. Variety: Ensure a mix of permitted types within each difficulty level, but meeting the exact Difficulty Quotas is your highest priority.

TEXT TO USE:
"""
${text}
"""

CRITICAL INSTRUCTION: Your final JSON array MUST contain EXACTLY ${easyCount + mediumCount + hardCount} items. Do not stop until you reach this exact number. Return JSON only.`;
}


// sinh tiêu đề đề thi từ tên file
function _generateTitle(fileName) {
  return fileName
    .replace(/\.pdf$/i, '')
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .trim()
    || 'English Exam';
}