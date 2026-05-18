const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp, getApps } = require('firebase-admin/app');
require("dotenv").config();

if (getApps().length === 0) {
  initializeApp();
}

const { processAndSaveExam } = require('./src/services/exam.service');
const { sendPushNotification } = require('./src/services/notif.service');
const { scheduledExamNotifications } = require('./scheduled_notifications');

exports.scheduledExamNotifications = scheduledExamNotifications; 

exports.generateExamFromPdf = onCall(
  { timeoutSeconds: 300, memory: '512MiB' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Bạn phải đăng nhập để sử dụng tính năng này.');
    }
    const userId = request.auth.uid; 
    const { extractedText, fileName, config } = request.data;
    
    return await processAndSaveExam(userId, extractedText, fileName, config);
  }
);

exports.sendPushOnNotification = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    const { userId, title, body, type, data: extra = {} } = request.data;
    if (!userId || !title || !body) throw new HttpsError("invalid-argument", "Thiếu tham số bắt buộc");
    
    return await sendPushNotification(userId, title, body, type, extra);
  }
);