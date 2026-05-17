
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');



//Hàm core xử lý gửi thông báo đẩy qua FCM
async function sendPushNotification(userId, title, body, type, extra = {}) {
    const db = getFirestore();
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) return { success: false, reason: 'User not found' };

        const tokens = userDoc.data()?.fcm_tokens ?? [];
        if (tokens.length === 0) return { success: false, reason: 'No FCM tokens' };

        // Ép kiểu tất cả các value trong payload về chuỗi (String) theo quy định của Firebase Cloud Messaging
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

        // Gửi thông báo
        const response = await getMessaging().sendEachForMulticast(message);
        logger.info(`[FCM] Sent to ${tokens.length} devices - Success: ${response.successCount}`);

        // Tìm và lọc các Token đã hết hạn / bị lỗi
        const expiredTokens = [];
        response.responses.forEach((res, i) => {
        if (!res.success && res.error?.code?.includes("registration-token")) {
            expiredTokens.push(tokens[i]);
        }
        });

        // Dọn rác Token trên Firestore
        if (expiredTokens.length > 0) {
        await db.collection("users").doc(userId).update({
            fcm_tokens: FieldValue.arrayRemove(...expiredTokens),
        });
        logger.info(`[FCM] Cleaned up ${expiredTokens.length} expired tokens for user ${userId}`);
        }

        return { success: true, sent: response.successCount };

    } catch (error) {
        logger.error('[FCM ERROR]', error);
        return { success: false, error: error.message };
    }
}

module.exports = { sendPushNotification };