import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SlidingNotification extends StatefulWidget {
  final Map<String, dynamic> message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const SlidingNotification({
    super.key,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  _SlidingNotificationState createState() => _SlidingNotificationState();
}
class _SlidingNotificationState extends State<SlidingNotification> with TickerProviderStateMixin {

  late AnimationController _controller;
  late AnimationController _lineController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _lineAnimation;
  Timer? _timer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _lineController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: Curves.linear,
      ),
    );

    _controller.forward();
    _lineController.forward();

    _timer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _isDismissed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < 0) {
            _dismiss();
          }
        },
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.surface.withOpacity(.1),
                          offset: Offset(0, 2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          radius: 24,
                          child: ClipOval(
                            child: widget.message['avatarUrl'] != null
                                ? Image.network(
                              widget.message['avatarUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Transform.translate(
                                offset: Offset(0, 5),
                                child: Icon(
                                  CupertinoIcons.person_alt,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            )
                                : Transform.translate(
                              offset: Offset(0, 5),
                              child: Icon(
                                CupertinoIcons.person_alt,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.message['name'],
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message['msg'],
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'now',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),Positioned(
                    bottom: 0,
                    left: 16,
                    child: AnimatedBuilder(
                      animation: _lineAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 2,
                          width: MediaQuery.of(context).size.width * _lineAnimation.value,
                          color: Colors.cyan,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}