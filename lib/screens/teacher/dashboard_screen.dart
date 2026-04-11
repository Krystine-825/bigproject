import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'class_list_screen.dart';
import '../../widgets/common/custom_button_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;
  int _selectedClass = 0;

  // Data tạm — sau thay bằng Firestore
  final _stats = [
    {'icon': Icons.school_rounded, 'label': 'Lớp học', 'value': '12'},
    {'icon': Icons.group_rounded, 'label': 'Học sinh', 'value': '450'},
    {'icon': Icons.description_rounded, 'label': 'Đề thi', 'value': '86'},
  ];

  final _classes = ['12A1 - B1', '11B2 - A2', '10C3 - B2', '12D1 - A1'];

  final _activities = [
    {
      'icon': Icons.task_alt_rounded,
      'bgColor': Color(0xFFEFF6FF),
      'iconColor': Color(0xFF007BFF),
      'title': 'Đã chấm bài thi',
      'subtitle': 'Kiểm tra 15p - Lớp 12A1',
      'time': '10 phút trước',
    },
    {
      'icon': Icons.note_add_rounded,
      'bgColor': Color(0xFFFFF7ED),
      'iconColor': Color(0xFFF97316),
      'title': 'Đề thi mới được tạo',
      'subtitle': 'Giữa học kỳ 2 - Môn Toán',
      'time': '1 giờ trước',
    },
    {
      'icon': Icons.group_add_rounded,
      'bgColor': Color(0xFFF0FDF4),
      'iconColor': Color(0xFF22C55E),
      'title': 'Học sinh mới tham gia',
      'subtitle': 'Lê Văn Bình - Lớp 11B2',
      'time': '3 giờ trước',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _statsSection(),
                    _classesSection(),
                    _activitiesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: _selectedNav),
    );
  }

  Widget _header() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          // Avatar + tên
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
                  // Chấm xanh online
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào,',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                  const Text(
                    'Nguyễn Văn A',
                    style: TextStyle(
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
          // Nút thông báo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textLight,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: _stats.map((stat) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: stat == _stats.last ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _classesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lớp học của tôi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: sang màn danh sách lớp
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Danh sách lớp cuộn ngang
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _classes.length,
            itemBuilder: (_, i) {
              final selected = _selectedClass == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedClass = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      _classes[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _activitiesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: sang màn lịch sử
                },
                child: const Text(
                  'Lịch sử',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: _activities.take(3).map((a) => _activityCard(a)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _activityCard(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: a['bgColor'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              a['icon'] as IconData,
              color: a['iconColor'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Thời gian
          Text(
            a['time'] as String,
            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  void onNavTapped(int i) {
    setState(() {
      _selectedNav = i;
    });
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClassListScreen()),
        );
        break;
    }
  }
}
