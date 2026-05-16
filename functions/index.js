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

  // Kiểm tra độ dài tối thiểu
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

function _getCEFRDescription(level) {
  const cefrGuides = {
    'A1': 'A1 (Beginner): Everyday vocabulary, simple present/continuous, basic prepositions, pronouns.',
    'A2': 'A2 (Elementary): Past simple, future (will/going to), comparatives, basic modals (can, must), daily life vocabulary.',
    'B1': 'B1 (Intermediate): Present perfect, past continuous, conditionals (0, 1st, 2nd), relative clauses, gerunds/infinitives.',
    'B2': 'B2 (Upper-Intermediate): Past perfect, complex conditionals, reported speech, passive voice, phrasal verbs, idioms.',
    'C1': 'C1 (Advanced): Inversions, cleft sentences, subjunctive, nuanced vocabulary, collocations.',
    'C2': 'C2 (Proficient): Near-native nuance, obscure vocabulary, cultural idioms, complex layered sentences.'
  };
  return cefrGuides[level] || cefrGuides['B1'];
}

// Prompt Hệ thống (Kỷ luật sắt)
function _buildSystemPrompt(typeInstructions, targetCEFR) {
  const cefrGuide = _getCEFRDescription(targetCEFR);

  return `You are an expert English exam creator. Your task is to create a BRAND NEW, STANDALONE English Grammar and Vocabulary quiz strictly at the **${targetCEFR}** CEFR level.

CEFR LEVEL GUIDELINE:
${cefrGuide}

CRITICAL RULES (FAILING THESE WILL RUIN THE APP):
1. THE INPUT IS MAYBE AN OLD EXAMS: The text I provide is probrably an old, messy exam, reading passage, or OCR text. It contains questions, reading passages, and question numbers.
2. DO NOT BE A PHOTOCOPIER: You MUST NEVER copy existing questions from the text. You MUST NEVER copy reading comprehension questions (e.g., "What is the main idea?", "What does 'they' refer to?").
3. 100% STANDALONE SENTENCES: Every single question you create MUST be a completely new, invented sentence that makes perfect sense on its own. The student will NEVER see the input text.
4. PURE GRAMMAR & VOCABULARY: Only test grammar rules, verb tenses, prepositions, or vocabulary meanings.
5. BAN LIST: You are STRICTLY FORBIDDEN from using the following words in your questions or explanations: "passage", "text", "author", "paragraph", "Question", "line".

OUTPUT FORMAT (Valid JSON Only):
{
  "questions": [
    {
      "type": "multiple_choice" | "fill_in" | "true_false",
      "question": "string (The newly invented standalone sentence)",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."], // For multiple_choice ONLY.
      "answer": "string (The exact correct answer)", 
      "explanation": "string (Explain the grammar/vocab rule universally, DO NOT mention the source text)"
    }
  ]
}

${typeInstructions}`;
}

// Hướng dẫn chi tiết từng loại câu hỏi
function _buildTypeInstructions(types) {
  const instructions = [];

  if (types.includes('multiple_choice')) {
    instructions.push(`MULTIPLE CHOICE rules:
- Provide 4 options prefixed exactly with "A. ", "B. ", "C. ", "D. ".
- Provide a COMPLETE, standalone sentence with a blank "___" to test grammar/vocabulary.
- Example: "I ________ to the market when it started raining." (A. went, B. was going, C. go, D. am going)`);
  }

  if (types.includes('fill_in')) {
    instructions.push(`FILL IN THE BLANK rules:
- Provide a COMPLETE, standalone sentence with a blank "___".
- Example: "She is very good ___ playing the piano." (Answer: at)`);
  }

  if (types.includes('true_false')) {
    instructions.push(`TRUE/FALSE rules:
- Test UNIVERSAL grammar rules, spelling, or vocabulary. DO NOT test facts.
- Example: "The plural form of 'child' is 'childrens'." (Answer: False)
- Example: "The word 'rapidly' is an adverb." (Answer: True)`);
  }

  return instructions.join('\n\n');
}

// Prompt Người dùng
function _buildUserPrompt(text, questionCount, types, targetCEFR) {
  const typesLabel = types.map(t => ({
    multiple_choice: 'multiple_choice',
    fill_in:         'fill_in',
    true_false:      'true_false',
  }[t])).join(', ');

  return `Generate EXACTLY ${questionCount} STANDALONE grammar/vocabulary questions at the ${targetCEFR} level.

Question Types allowed: ${typesLabel}.

MANDATORY INSTRUCTIONS:
- Look at the text below ONLY to find vocabulary words or grammar topics.
- IGNORE all formatting, question numbers, reading passages, and stories in the text.
- INVENT ${questionCount} completely new, unrelated sentences to test the students.

SOURCE TEXT FOR VOCAB INSPIRATION ONLY:
"""
${text}
"""

Generate the JSON output now.`;
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