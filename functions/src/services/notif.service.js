// functions/src/services/notif.service.js
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

async function sendPushNotification(userId, title, body, type, extra = {}) {
  const db = getFirestore(); 
  
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return { success: false };

    const tokens = userDoc.data()?.fcm_tokens ?? [];
    if (tokens.length === 0) return { success: false };

    const dataPayload = { type };
    for (const [k, v] of Object.entries(extra)) {
      dataPayload[k] = String(v);
    }

    const message = {
      tokens, 
      notification: { title, body }, 
      data: dataPayload,
      android: { 
        notification: { channelId: "edu_exam_default", priority: "high", sound: "default" } 
      },
      apns: { 
        payload: { aps: { sound: "default", badge: 1 } } 
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);
    logger.info(`[FCM] Gửi tới ${tokens.length} thiết bị — thành công: ${response.successCount}, thất bại: ${response.failureCount}`);

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

    if (expiredTokens.length > 0) {
      await db.collection("users").doc(userId).update({
        fcm_tokens: FieldValue.arrayRemove(...expiredTokens), 
      });
      logger.info(`[FCM] Đã xoá ${expiredTokens.length} token hết hạn của user ${userId}`);
    }

    return { success: true, sent: response.successCount };

  } catch (error) {
    logger.error('[FCM ERROR]', error);
    return { success: false, error: error.message };
  }
}

module.exports = { sendPushNotification };