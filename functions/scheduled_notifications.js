

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');


let _db;
function db() {
  if (!_db) _db = getFirestore();
  return _db;
}

// Chạy mỗi 15 phút, quét tất cả đề đang assigned để gửi thông báo nhắc nộp bài cho học sinh và nhắc đóng đề cho giáo viên
exports.scheduledExamNotifications = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'asia-southeast1',
    timeZone: 'Asia/Ho_Chi_Minh',
  },
  async () => {
    const now = new Date();

    // Lấy tất cả đề đang ở trạng thái assigned
    const examsSnap = await db()
      .collection('exams')
      .where('status', '==', 'assigned')
      .get();

    if (examsSnap.empty) return;

    const tasks = [];

    for (const examDoc of examsSnap.docs) {
      const exam = examDoc.data();
      const examId = examDoc.id;
      const examName = exam.title || exam.name || 'Bài kiểm tra';
      const teacherId = exam.teacher_id || '';
      const assignments = exam.assignments || [];

      for (const assignment of assignments) {
        const closeAt = new Date(assignment.closeAt || assignment.close_at);
        const classId = assignment.classId || assignment.class_id || '';
        const className = assignment.className || assignment.class_name || 'Lớp học';

        if (!classId || isNaN(closeAt.getTime())) continue;

        const diffMs = closeAt - now;
        const diffMin = diffMs / 60000;

        // Lấy danh sách học sinh active trong lớp 
        const memberSnap = await db()
          .collection('class_members')
          .where('class_id', '==', classId)
          .where('status', '==', 'active')
          .get();

        const allStudentIds = memberSnap.docs.map(
          (d) => d.data().student_id
        ).filter(Boolean);

        if (allStudentIds.length === 0) continue;

        // Lấy danh sách học sinh đã nộp bài 
        const subSnap = await db()
          .collection('submissions')
          .where('exam_id', '==', examId)
          .where('class_id', '==', classId)
          .get();

        const submittedIds = new Set(
          subSnap.docs.map((d) => d.data().student_id).filter(Boolean)
        );
        const submittedCount = submittedIds.size;
        const totalCount = allStudentIds.length;

        // Học sinh chưa nộp 
        const unsubmittedIds = allStudentIds.filter(
          (id) => !submittedIds.has(id)
        );

        const closeStr = _formatTime(closeAt);
        const closeDateStr = _formatDate(closeAt);

        
        // examDeadline: nhắc trước 24h (window 15 phút)
       
        if (diffMin >= 1425 && diffMin < 1440 && unsubmittedIds.length > 0) {
          // diffMin ≈ 1440 = 24 giờ, window ±15 phút
          tasks.push(
            _notifyBatch({
              userIds: unsubmittedIds,
              type: 'exam_deadline',
              title: '⏰ Sắp hết hạn nộp bài (còn 24 giờ)',
              body: `Còn 24 giờ để nộp "${examName}" lớp "${className}". Hạn: ${closeDateStr} ${closeStr}.`,
              data: { examId, classId, examName, className },
            })
          );
        }

        
        //  examDeadline: nhắc trước 1h (window 15 phút)
        
        if (diffMin >= 45 && diffMin < 60 && unsubmittedIds.length > 0) {
          tasks.push(
            _notifyBatch({
              userIds: unsubmittedIds,
              type: 'exam_deadline',
              title: '⏰ Sắp hết hạn nộp bài (còn 1 giờ)',
              body: `Còn 1 giờ để nộp "${examName}" lớp "${className}". Hạn: ${closeStr} hôm nay.`,
              data: { examId, classId, examName, className },
            })
          );
        }

       
        // examClosingSoon: nhắc giáo viên trước 1h
   
        if (diffMin >= 45 && diffMin < 60 && teacherId) {
          tasks.push(
            _notifyOne({
              userId: teacherId,
              type: 'exam_closing_soon',
              title: '⚠️ Đề thi sắp đóng',
              body: `"${examName}" lớp "${className}" đóng lúc ${closeStr} hôm nay. Đã nộp: ${submittedCount}/${totalCount}.`,
              data: { examId, classId, examName, className, submittedCount, totalCount },
            })
          );
        }

        
        // examClosed: đề vừa đóng (window 15 phút sau closeAt)
        
        if (diffMin >= -15 && diffMin < 0) {
          // Kiểm tra đã gửi thông báo examClosed chưa (tránh gửi lại)
          const alreadySent = await _checkAlreadySent(examId, classId, 'exam_closed');
          if (!alreadySent) {
            // Thông báo giáo viên
            if (teacherId) {
              tasks.push(
                _notifyOne({
                  userId: teacherId,
                  type: 'exam_closed',
                  title: '🔒 Đề thi đã đóng',
                  body: `"${examName}" lớp "${className}" đã hết hạn. Đã nộp: ${submittedCount}/${totalCount} học sinh.`,
                  data: { examId, classId, examName, className, submittedCount, totalCount },
                })
              );
            }

            // Thông báo học sinh chưa nộp
            if (unsubmittedIds.length > 0) {
              tasks.push(
                _notifyBatch({
                  userIds: unsubmittedIds,
                  type: 'exam_expired_unsubmitted',
                  title: '❌ Bạn đã bỏ lỡ bài thi',
                  body: `Đã hết hạn nộp "${examName}" lớp "${className}" mà bạn chưa nộp.`,
                  data: { examId, classId, examName, className },
                })
              );
            }

            // Đánh dấu đã gửi để không gửi lại lần sau
            tasks.push(
              db().collection('_notification_sent').add({
                examId,
                classId,
                type: 'exam_closed',
                sentAt: new Date().toISOString(),
              })
            );
          }
        }
      }
    }

    await Promise.allSettled(tasks);
  }
);


// Ghi 1 thông báo in-app + gửi push cho 1 user
async function _notifyOne({ userId, type, title, body, data }) {
  if (!userId) return;
  await Promise.allSettled([
    // Ghi Firestore (in-app)
    db().collection('notifications').add({
      user_id: userId,
      type,
      title,
      body,
      is_read: false,
      created_at: new Date().toISOString(),
      data: data || {},
    }),
    // Push notification
    _sendPush(userId, title, body, type, data),
  ]);
}

// Ghi nhiều thông báo in-app + gửi push cho nhiều user
async function _notifyBatch({ userIds, type, title, body, data }) {
  const valid = (userIds || []).filter(Boolean);
  if (valid.length === 0) return;

  const now = new Date().toISOString();

  // Ghi Firestore theo batch (mỗi batch tối đa 500 doc)
  for (let i = 0; i < valid.length; i += 400) {
    const chunk = valid.slice(i, i + 400);
    const batch = db().batch();
    for (const uid of chunk) {
      const ref = db().collection('notifications').doc();
      batch.set(ref, {
        user_id: uid,
        type,
        title,
        body,
        is_read: false,
        created_at: now,
        data: data || {},
      });
    }
    await batch.commit();
  }

  // Gửi push song song
  await Promise.allSettled(
    valid.map((uid) => _sendPush(uid, title, body, type, data))
  );
}

// Gửi FCM push notification cho 1 user (đọc fcm_tokens từ Firestore)
async function _sendPush(userId, title, body, type, data) {
  try {
    const userDoc = await db().collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const tokens = userDoc.data().fcm_tokens || [];
    if (tokens.length === 0) return;

    const messaging = getMessaging();

    // Gửi cho tất cả token của user (có thể dùng nhiều thiết bị)
    const results = await Promise.allSettled(
      tokens.map((token) =>
        messaging.send({
          token,
          notification: { title, body },
          android: {
            priority: 'high',
            notification: {
              channelId: 'edu_exam_default', // phải khớp với FcmService.channelId
              sound: 'default',
            },
          },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } },
          },
          data: {
            type: type || '',
            ..._stringifyData(data),
          },
        })
      )
    );

    // Xóa token hết hạn khỏi Firestore
    const expiredTokens = [];
    results.forEach((result, idx) => {
      if (
        result.status === 'rejected' &&
        (result.reason?.code === 'messaging/registration-token-not-registered' ||
          result.reason?.code === 'messaging/invalid-registration-token')
      ) {
        expiredTokens.push(tokens[idx]);
      }
    });

    if (expiredTokens.length > 0) {
      await db().collection('users').doc(userId).update({
        fcm_tokens: FieldValue.arrayRemove(...expiredTokens),
      });
    }
  } catch (err) {
    console.error(`[FCM] Lỗi gửi push cho ${userId}:`, err.message);
  }
}

// Kiểm tra đã gửi thông báo loại này cho exam+class chưa
async function _checkAlreadySent(examId, classId, type) {
  try {
    const snap = await db()
      .collection('_notification_sent')
      .where('examId', '==', examId)
      .where('classId', '==', classId)
      .where('type', '==', type)
      .limit(1)
      .get();
    return !snap.empty;
  } catch {
    return false;
  }
}

// Convert data object sang dạng string (FCM data payload chỉ nhận string)
function _stringifyData(data) {
  if (!data) return {};
  const result = {};
  for (const [key, value] of Object.entries(data)) {
    result[key] = String(value);
  }
  return result;
}

function _formatTime(date) {
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}

function _formatDate(date) {
  return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
}