import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common/custom_button_nav_student.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final String studentName = "Lê Văn Bình";

  final List<Map<String, dynamic>> stats = [
    {'count': '3', 'label': 'Chưa làm', 'color': Color(0xFFFF9800)},
    {'count': '1', 'label': 'Mới hôm nay', 'color': Color(0xFF007BFF)},
    {'count': '16', 'label': 'Hoàn thành', 'color': Color(0xFF10B981)},
  ];

  final List<Map<String, dynamic>> exams = [
    {
      'icon': Icons.history_edu,
      'iconColor': Color(0xFFFF9800),
      'title': 'Kiểm tra giữa kỳ',
      'className': '12A1',
      'questionCount': 10,
      'badgeText': 'Hôm nay',
      'badgeColor': Color(0xFFFF9800),
      'isCompleted': false,
    },
    {
      'icon': Icons.translate,
      'iconColor': Color(0xFF007BFF),
      'title': 'Từ vựng Unit 5',
      'className': '11B2',
      'questionCount': 8,
      'badgeText': '2 ngày trước',
      'badgeColor': Color(0xFF64748B),
      'isCompleted': false,
    },
    {
      'icon': Icons.spellcheck,
      'iconColor': Color(0xFF6366F1),
      'title': 'Ngữ pháp Unit 6',
      'className': '10C3',
      'questionCount': 12,
      'badgeText': 'Mới',
      'badgeColor': Color(0xFF007BFF),
      'isCompleted': false,
    },
    {
      'icon': Icons.task_alt_rounded,
      'iconColor': Color(0xFF10B981),
      'title': 'Kiểm tra 15 phút',
      'className': '12A1',
      'score': '8/10',
      'grade': 'Giỏi',
      'isCompleted': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statistics(),
                    const SizedBox(height: 32),
                    myExamsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavSt(
        currentIndex: 0,
      ), // Tab Trang chủ
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.textHint,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào buổi sáng,',
                    style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                  ),
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textMedium,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget statistics() {
    return Row(
      children: stats.map((stat) {
        final isHighlighted = stat['label'] == 'Mới hôm nay';
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: isHighlighted
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  stat['count'],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: stat['color'],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat['label'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget myExamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đề thi của bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to all exams
              },
              child: const Text(
                'Xem tất cả >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(children: exams.map((exam) => _buildExamCard(exam)).toList()),
      ],
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    if (exam['isCompleted'] == true) {
      return _buildCompletedCard(exam);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (exam['iconColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              exam['icon'] as IconData,
              color: exam['iconColor'] as Color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (exam['badgeColor'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        exam['badgeText'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: exam['badgeColor'],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoItem(Icons.groups_rounded, exam['className']),
                    const SizedBox(width: 16),
                    _infoItem(
                      Icons.description_rounded,
                      '${exam['questionCount']} câu',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exam['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      exam['score'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _infoItem(Icons.groups_rounded, exam['className']),
                    const SizedBox(width: 16),
                    Text(
                      exam['grade'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMedium),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
      ],
    );
  }

  Widget bottomNav() {
    return const CustomBottomNavSt(
      currentIndex: 0,
    ); // Tab Trang chủ đang active
  }
}
