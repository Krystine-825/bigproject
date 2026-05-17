
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const { cleanText, validateContent, generateTitle } = require('../utils/helpers');
const { generateQuestionsFromAI } = require('./ai.service');


const MAX_EXAMS_PER_DAY = 10;

async function processAndSaveExam(userId, extractedText, fileName, config) {
    const db = getFirestore();
    if (extractedText.trim().length < 100) {
        throw new HttpsError('invalid-argument', 'Nội dung văn bản trống.');
    }

    const cleanedText = cleanText(extractedText);
    const validation = validateContent(cleanedText);
    if (!validation.valid) throw new HttpsError('invalid-argument', validation.reason);

    const today = new Date().toLocaleDateString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
    const quotaRef = db.collection('ai_quotas').doc(userId);
    let oldUsageCount = 0;

    // ktra quota = transaction
    await db.runTransaction(async (transaction) => {
        const quotaDoc = await transaction.get(quotaRef);
        if (quotaDoc.exists && quotaDoc.data().date === today) {
        oldUsageCount = quotaDoc.data().count || 0;
        if (oldUsageCount >= MAX_EXAMS_PER_DAY) {
            logger.warn(`[QUOTA] User ${userId} hết lượt.`);
            throw new HttpsError('resource-exhausted', `Bạn đã sử dụng hết ${MAX_EXAMS_PER_DAY} lượt tạo đề hôm nay.`);
        }
        }
        transaction.set(quotaRef, {
        date: today,
        count: oldUsageCount + 1,
        updatedAt: FieldValue.serverTimestamp()
        }, { merge: true });
    });

    // gọi & lưu firestore
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
        return { success: true, exam: { id: docRef.id, ...examData } };

    } catch (error) {
        // hoàn quota nếu lỗi
        await quotaRef.set({ count: oldUsageCount, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        logger.error('[PROCESS ERROR]', error);
        throw new HttpsError('internal', `Lỗi tạo đề: ${error.message}`);
    }
}

module.exports = { processAndSaveExam };