import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Đọc hết',
                style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('HÔM NAY'),
          _notifItem(
            icon: Icons.description_outlined,
            iconBg: AppColors.primary.withOpacity(0.1),
            iconColor: AppColors.primary,
            title: 'Đề thi mới được giao',
            content: 'GV Nguyễn Văn A vừa giao Kiểm tra giữa kỳ cho lớp 12A1',
            time: '10 phút trước',
            isUnread: true,
          ),
          _notifItem(
            icon: Icons.check_circle,
            iconBg: Colors.green.withOpacity(0.1),
            iconColor: Colors.green,
            title: 'Nộp bài thành công',
            content: 'Hệ thống đã ghi nhận bài làm môn Toán của bạn lúc 08:30',
            time: '2 giờ trước',
            isUnread: true,
          ),
          const SizedBox(height: 8),
          _section('HÔM QUA'),
          _notifItem(
            icon: Icons.error_outline,
            iconBg: Colors.red.withOpacity(0.1),
            iconColor: Colors.red,
            title: 'Đã rời khỏi lớp',
            content: 'Bạn đã được quản trị viên xóa khỏi danh sách lớp Luyện thi Đại học khối A',
            time: '1 ngày trước',
            isUnread: false,
          ),
          _notifItem(
            icon: Icons.campaign_outlined,
            iconBg: Colors.grey.withOpacity(0.1),
            iconColor: Colors.grey,
            title: 'Thông báo từ nhà trường',
            content: 'Lịch thi học kỳ I đã được cập nhật chính thức trên cổng thông tin',
            time: '1 ngày trước',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _notifItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String content,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textLight, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}