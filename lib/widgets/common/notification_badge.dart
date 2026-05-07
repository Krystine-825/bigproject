
import 'package:flutter/material.dart';
import '../../controllers/notification_controller.dart';
import '../../core/app_colors.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor = AppColors.textLight,
    this.backgroundColor = AppColors.white,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final ctrl = NotificationController();

  late final Stream<int> unreadStream;

   @override
  void initState() {
    super.initState();
    unreadStream = ctrl.streamUnreadCount(); 
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadStream,
      builder: (context, snap) {
        final count = snap.data ?? 0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    color: count > 0 ? AppColors.primary : widget.iconColor,
                    size: 22,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}