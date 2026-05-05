import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'class_list_screen.dart';
import 'class_detail_screen.dart';
import '../../widgets/common/custom_button_nav.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/class_controller.dart';
import '../../controllers/exam_controller.dart';
import '../../data/models/class_model.dart';
import '../../data/models/exam_model.dart';
import '../../widgets/common/notification_badge.dart';
import '../notification/notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _selectedNav = 0;
  String _teacherName = '';
  final _classController = ClassController();
  final _examController = ExamController();

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await AuthController().getUserName();
    if (mounted) setState(() => _teacherName = name ?? 'Giáo viên');
  }

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
                  const Text(
                    'Xin chào,',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                  Text(
                    _teacherName,
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
          NotificationBadge(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: StreamBuilder<List<ClassModel>>(
        stream: _classController.streamMyClasses(),
        builder: (context, classSnap) {
          return StreamBuilder<List<ExamModel>>(
            stream: _examController.streamMyExams(),
            builder: (context, examSnap) {
              final classes = classSnap.data ?? [];
              final classCount = classes.length;
              final studentCount = classes.fold<int>(
                0,
                (s, c) => s + c.studentCount,
              );
              final examCount = examSnap.data?.length ?? 0;

              final stats = [
                {
                  'icon': Icons.school_rounded,
                  'label': 'Lớp học',
                  'value': '$classCount',
                },
                {
                  'icon': Icons.group_rounded,
                  'label': 'Học sinh',
                  'value': '$studentCount',
                },
                {
                  'icon': Icons.description_rounded,
                  'label': 'Đề thi',
                  'value': '$examCount',
                },
              ];

              return Row(
                children: stats.map((stat) {
                  final isLast = stat == stats.last;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 12),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassListScreen()),
                ),
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
        SizedBox(
          height: 40,
          child: StreamBuilder<List<ClassModel>>(
            stream: _classController.streamMyClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final classes = (snapshot.data ?? []).take(5).toList();
              if (classes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Chưa có lớp học nào',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: classes.length,
                itemBuilder: (_, i) {
                  final cls = classes[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailScreen(
                          classId: cls.id,
                          className: cls.name,
                          classCode: cls.code,
                        ),
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cls.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
            children: const [
              Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        _RecentActivitiesWidget(
          classController: _classController,
          examController: _examController,
        ),
      ],
    );
  }
}

class _RecentActivitiesWidget extends StatelessWidget {
  final ClassController classController;
  final ExamController examController;

  const _RecentActivitiesWidget({
    required this.classController,
    required this.examController,
  });

  String _timeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExamModel>>(
      stream: examController.streamMyExams(),
      builder: (context, examSnap) {
        return StreamBuilder<List<ClassModel>>(
          stream: classController.streamMyClasses(),
          builder: (context, classSnap) {
            final activities = <Map<String, dynamic>>[];

            for (final exam in (examSnap.data ?? [])) {
              if (exam.isAssigned) {
                final lastAssign = exam.assignments.isNotEmpty
                    ? exam.assignments.last
                    : null;
                activities.add({
                  'icon': Icons.send_rounded,
                  'bgColor': const Color(0xFFEFF6FF),
                  'iconColor': const Color(0xFF007BFF),
                  'title': 'Đề thi đã được giao',
                  'subtitle': '${exam.name} → ${lastAssign?.className ?? ''}',
                  'sortKey': lastAssign?.assignedAt ?? exam.createdAt,
                });
              } else {
                activities.add({
                  'icon': Icons.note_add_rounded,
                  'bgColor': const Color(0xFFFFF7ED),
                  'iconColor': const Color(0xFFF97316),
                  'title': 'Đề thi mới được tạo',
                  'subtitle': exam.name,
                  'sortKey': exam.createdAt,
                });
              }
            }

            for (final cls in (classSnap.data ?? [])) {
              if (cls.studentCount > 0) {
                activities.add({
                  'icon': Icons.group_add_rounded,
                  'bgColor': const Color(0xFFF0FDF4),
                  'iconColor': const Color(0xFF22C55E),
                  'title': 'Lớp đang có học sinh',
                  'subtitle': '${cls.name} · ${cls.studentCount} học sinh',
                  'sortKey': '',
                });
              }
            }

            activities.sort(
              (a, b) =>
                  (b['sortKey'] as String).compareTo(a['sortKey'] as String),
            );

            final display = activities.take(4).toList();

            if (display.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chưa có hoạt động nào',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: display.map((a) => _activityCard(a)).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _activityCard(Map<String, dynamic> a) {
    final timeStr = (a['sortKey'] as String).isNotEmpty
        ? _timeAgo(a['sortKey'] as String)
        : '';
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
          if (timeStr.isNotEmpty)
            Text(
              timeStr,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}
