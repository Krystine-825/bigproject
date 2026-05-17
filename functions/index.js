const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');
require("dotenv").config();
const { processAndSaveExam } = require('./src/services/exam.service');
const { sendPushNotification } = require('./src/services/notif.service');

initializeApp();
const db = getFirestore();

//  tạo đề thi ừ pdf
exports.generateExamFromPdf = onCall(
  { timeoutSeconds: 300, memory: '512MiB' },
  async (request) => {
    // Bắt buộc người dùng phải đăng nhập thật (chống truyền teacherId ảo)
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Bạn phải đăng nhập để sử dụng tính năng này.');
    }
    
    const userId = request.auth.uid; // Lấy ID thật từ Token
    const { extractedText, fileName, config } = request.data;

    return await processAndSaveExam(userId, extractedText, fileName, config);
  }
);

// gửi noti push
exports.sendPushOnNotification = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    // Lấy dữ liệu Client gửi lên
    const { userId, title, body, type, data: extra = {} } = request.data;
    
    if (!userId || !title || !body) {
      throw new HttpsError("invalid-argument", "Thiếu tham số bắt buộc");
    }

    // Gọi sang Service để xử lý
    return await sendPushNotification(userId, title, body, type, extra);
  }
);