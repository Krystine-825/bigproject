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
const {getMessaging} = require("firebase-admin/messaging");

require("dotenv").config(); 
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore'); 
const OpenAI                = require('openai');
const { scheduledExamNotifications } = require('./scheduled_notifications');


initializeApp();

const db      = getFirestore();
const openai  = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

exports.scheduledExamNotifications = scheduledExamNotifications; 

// Cloud Function: generateExamFromPdf
exports.generateExamFromPdf = onCall(
  { timeoutSeconds: 300, memory: '512MiB' },
  async (request) => {
    // CHỈ NHẬN TEXT TỪ CLIENT - KHÔNG NHẬN FILE PDF NỮA
    const {
      teacherId, extractedText, fileName, config,
    } = request.data;

    // Validate input
    if (!teacherId || !extractedText) {
      throw new HttpsError('invalid-argument', 'Thiếu tham số bắt buộc. Cần có teacherId và extractedText.');
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
      if (extractedText.trim().length < 100) {
        throw new HttpsError(
          'invalid-argument',
          'Nội dung văn bản trống. Vui lòng đảm bảo file PDF có thể đọc được chữ.'
        );
      }
      const rawText = extractedText;

      const MAX_CHARS = 40000;
      if (rawText.length > MAX_CHARS) {
        throw new HttpsError('out-of-range', `File quá dài (${rawText.length} ký tự). Vui lòng tách nhỏ PDF và tải lên dưới ${MAX_CHARS} ký tự để AI xử lý tốt nhất.`);
      }

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


function _cleanText(raw) {
  return raw
    .replace(/\r\n/g, '\n')         // chuẩn hoá xuống dòng
    .replace(/\n{3,}/g, '\n\n')     // bỏ dòng trống thừa
    .replace(/[ \t]{2,}/g, ' ')     // bỏ space thừa
    .replace(/[^\x20-\x7E\n\u00C0-\u024F]/g, ' ') // giữ ASCII + Latin Extended
    .replace(/\s{2,}/g, ' ')        // clean lại space sau replace
    .trim();
}

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
    targetCEFR = 'B1', // Nhận tham số mốc CEFR từ Flutter, mặc định là B1 để tránh lỗi
  } = config;

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
  const systemPrompt = _buildSystemPrompt(typeInstructions, targetCEFR);
  const userPrompt   = _buildUserPrompt(
    inputText, questionCount, questionTypes, targetCEFR
  );

  // kiểm tra có model có đọc hết file được extracted không
  logger.info(`[DEBUG INPUT] Tổng số ký tự nhận được từ Flutter: ${text.length}`);
  logger.info(`[DEBUG INPUT] Số ký tự thực tế nhét vào Prompt gửi AI: ${inputText.length}`);
  logger.info(`[DEBUG INPUT] Mốc CEFR được chọn: ${targetCEFR}`);
  logger.info(`[DEBUG INPUT] 50 ký tự đầu: "${inputText.slice(0, 50)}..."`);
  logger.info(`[DEBUG INPUT] 50 ký tự cuối: "...${inputText.slice(-50)}"`);


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

      // Đánh số id từ 1 và TRẢ VỀ KẾT QUẢ THÀNH CÔNG (Không cần sort theo Dễ/TB/Khó nữa)
      return parsed.questions.map((q, i) => ({ ...q, id: i + 1 }));

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

// prompt hệ thống đã siết chặt luật "Câu hỏi độc lập"
function _buildSystemPrompt(typeInstructions, targetCEFR) {
  return `You are an expert English language teacher and exam designer. Your task is to create an English exam strictly targeted at the **${targetCEFR}** CEFR level based on the provided text.

CRITICAL RULES (STRICTLY ENFORCED):
1. 100% SELF-CONTAINED QUESTIONS: The student will NOT see the original text. EVERY question MUST provide full context within itself so it makes perfect sense on its own.
2. NO EXTERNAL REFERENCES: NEVER use phrases like "according to the passage", "in paragraph 2", or "for Question 14". 
3. ADAPT, DON'T COPY: If you extract a sentence from a reading passage to test vocabulary or grammar, you MUST rewrite it into a standalone, logical sentence.
4. NO READING COMPREHENSION: DO NOT test facts from stories or articles (e.g., "Singapore is a dirty city"). Test ONLY general English Grammar and Vocabulary rules.
5. TARGET LEVEL: All questions, correct answers, and distractors MUST strictly align with the ${targetCEFR} CEFR level.
6. LANGUAGE: The entire output MUST be 100% in English. NO Vietnamese.

OUTPUT FORMAT:
Return a valid JSON object strictly matching this structure:
{
  "questions": [
    {
      "type": "multiple_choice" | "fill_in" | "true_false",
      "question": "string",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."], // For multiple_choice ONLY. MUST include "A.", "B.", "C.", "D." prefixes.
      "answer": "string", 
      "explanation": "A concise explanation of the grammar rule or vocabulary usage."
    }
  ]
}

${typeInstructions}`;
}


// hướng dẫn theo từng loại câu hỏi đã được thiết kế lại
function _buildTypeInstructions(types) {
  const instructions = [];

  if (types.includes('multiple_choice')) {
    instructions.push(`MULTIPLE CHOICE rules:
- Provide exactly 4 options (A, B, C, D).
- Provide a COMPLETE sentence with a blank "___" to test grammar/vocabulary, OR provide a standalone sentence and ask for a synonym.
- NEVER ask "Which word fits in Question 14?". You must write the full sentence containing the blank.`);
  }

  if (types.includes('fill_in')) {
    instructions.push(`FILL IN THE BLANK rules:
- Use "___" to mark the blank in a COMPLETE, self-contained sentence.
- The sentence MUST have enough context clues for the student to deduce the answer logically without needing any external text.
- Answer is a single word or short phrase (max 4 words).`);
  }

  if (types.includes('true_false')) {
    instructions.push(`TRUE/FALSE rules (GRAMMAR/VOCAB ONLY):
- DO NOT test facts from the source text (e.g., "John went to the store" -> True/False). The student hasn't read the text!
- INSTEAD, test grammar rules, vocabulary definitions, or spelling.
- Example of a GOOD True/False question: "The word 'rapidly' functions as an adjective in English." (Answer: False)
- Example of a GOOD True/False question: "In the sentence 'She has went to Paris', the verb tense is grammatically correct." (Answer: False)`);
  }

  return instructions.join('\n\n');
}


// prompt người dùng
function _buildUserPrompt(text, questionCount, types, targetCEFR) {
  const typesLabel = types.map(t => ({
    multiple_choice: 'multiple_choice',
    fill_in:         'fill_in',
    true_false:      'true_false',
  }[t])).join(', ');

  return `Create a ${targetCEFR} English exam based strictly on the text provided below.

TASK REQUIREMENTS:
1. Level: ALL questions MUST be exactly at the ${targetCEFR} level.
2. Quantity: Generate EXACTLY ${questionCount} questions.
3. Permitted Types: Use ONLY these formats: ${typesLabel}.

TEXT TO USE:
"""
${text}
"""

Return EXACTLY ${questionCount} items in JSON format. Do not stop until you reach this exact number.`;
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

// notification — onCall v2, Flutter gọi hàm này sau khi _write() ghi vào Firestore
exports.sendPushOnNotification = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    const { userId, title, body, type, data: extra = {} } = request.data;
    if (!userId || !title || !body) {
      throw new HttpsError("invalid-argument", "Thiếu tham số bắt buộc");
    }

    // Lấy FCM token(s) của user — tái sử dụng db đã có sẵn
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const tokens = userDoc.data()?.fcm_tokens ?? [];
    if (tokens.length === 0) return; // user đã tắt thông báo

    // Chuyển tất cả extra thành string (FCM yêu cầu)
    const dataPayload = { type };
    for (const [k, v] of Object.entries(extra)) {
      dataPayload[k] = String(v);
    }

    const message = {
      tokens,
      notification: { title, body },
      data: dataPayload,
      android: {
        notification: {
          channelId: "edu_exam_default",
          priority: "high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);
    logger.info(`[FCM] Gửi tới ${tokens.length} thiết bị — thành công: ${response.successCount}, thất bại: ${response.failureCount}`);

    // Dọn token hết hạn
    const expiredTokens = [];
    response.responses.forEach((res, i) => {
      if (
        !res.success &&
        (res.error?.code === "messaging/invalid-registration-token" ||
          res.error?.code === "messaging/registration-token-not-registered")
      ) {
        expiredTokens.push(tokens[i]);
      }
    });

    // ✅ Lỗi #5 đã sửa: arrayRemove(...expiredTokens) đúng cú pháp JS
    // nhưng nếu expiredTokens rỗng thì gọi arrayRemove() không tham số → lỗi Firestore
    // Guard bên ngoài (expiredTokens.length > 0) đã an toàn, giữ nguyên
    if (expiredTokens.length > 0) {
      await db.collection("users").doc(userId).update({
        fcm_tokens: FieldValue.arrayRemove(...expiredTokens), // spread array thành từng arg riêng
      });
      logger.info(`[FCM] Đã xoá ${expiredTokens.length} token hết hạn của user ${userId}`);
    }

    return { success: true, sent: response.successCount };
  }
);