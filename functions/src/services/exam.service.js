const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const { cleanText, validateContent, generateTitle } = require('../utils/helpers');
const { generateQuestionsFromAI } = require('./ai.service');

const MAX_EXAMS_PER_DAY = 3;
const MAX_CHARS = 40000;

async function processAndSaveExam(userId, extractedText, fileName, config) {
  const db = getFirestore(); 

  if (extractedText.trim().length < 100) {
    throw new HttpsError('invalid-argument', 'Nội dung văn bản trống. Vui lòng đảm bảo file PDF có thể đọc được chữ.');
  }

  if (extractedText.length > MAX_CHARS) {
    throw new HttpsError('out-of-range', `File quá dài (${extractedText.length} ký tự). Vui lòng tách nhỏ PDF và tải lên dưới ${MAX_CHARS} ký tự để AI xử lý tốt nhất.`);
  }

  const cleanedText = cleanText(extractedText);
  const validation = validateContent(cleanedText);
  if (!validation.valid) throw new HttpsError('invalid-argument', validation.reason);

  const today = new Date().toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
  const quotaRef = db.collection('ai_quotas').doc(userId);
  let oldUsageCount = 0;

  // 
  await db.runTransaction(async (transaction) => {
    const quotaDoc = await transaction.get(quotaRef);
    if (quotaDoc.exists && quotaDoc.data().date === today) {
      oldUsageCount = quotaDoc.data().count || 0;
      if (oldUsageCount >= MAX_EXAMS_PER_DAY) {
        logger.warn(`[QUOTA] Giáo viên ${userId} đã hết lượt hôm nay.`);
        throw new HttpsError(
          'resource-exhausted', 
          `Bạn đã sử dụng hết ${MAX_EXAMS_PER_DAY} lượt tạo đề bằng AI của ngày hôm nay. Vui lòng quay lại vào ngày mai nhé!`
        );
      }
    }
    transaction.set(quotaRef, {
      date: today,
      count: oldUsageCount + 1,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  });

  //
  try {
    const questions = await generateQuestionsFromAI(cleanedText, config);
    
    const examData = {
      title: generateTitle(fileName),
      teacher_id: userId,
      source_pdf_name: fileName,
      questions: questions,
      status: 'draft',
      question_count: questions.length,
      created_at: new Date().toISOString(),
      assignments: [],
      assigned_class_ids: [],
    };

    const docRef = await db.collection('exams').add(examData);
    return { success: true, exam: { exam_id: docRef.id, ...examData } };

  } catch (error) {
    //
    await quotaRef.set({ 
      count: Math.max(0, oldUsageCount), 
      updatedAt: FieldValue.serverTimestamp() 
    }, { merge: true });
    
    logger.error('generateExamFromPdf error:', error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', `Lỗi xử lý: ${error.message}`);
  }
}

module.exports = { processAndSaveExam };