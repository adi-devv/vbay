import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/smooth_toggle.dart';
import 'package:vbay/components/teal_button.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/pages/nav/profile/user_details_page.dart';
import 'package:vbay/pages/sell/camera_page.dart';
import 'package:vbay/providers/active_seeks_provider.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';
import 'package:flutter/services.dart';

class MyBottomNavbar extends StatefulWidget {
  final void Function(int) onTabChange;

  const MyBottomNavbar({
    super.key,
    required this.onTabChange,
  });

  @override
  MyBottomNavbarState createState() => MyBottomNavbarState();
}

class MyBottomNavbarState extends State<MyBottomNavbar> {
  int _selectedIndex = 0;
  bool _unread = false;

  void changeTab(int index) {
    _onTabChange(index);
  }

  int getIndex() {
    return _selectedIndex;
  }

  void _onTabChange(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
    widget.onTabChange(index);
  }

  void toggleUnread(bool val) {
    if (mounted) {
      setState(() => _unread = val);
    }
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                CupertinoIcons.app_badge_fill,
                "Sell An Item",
                "Post an item you want to sell",
                context,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                CupertinoIcons.search,
                "Seek An Item",
                "Let others know what you're looking for!",
                context,
                () {
                  showSeekDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    String description,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSeekDialog(BuildContext context, [Seek? seek]) {
    final TextEditingController seekController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    bool isUrgent = seek?.isUrgent ?? false;
    seekController.text = seek?.itemName ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Seek",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: seekController,
                    focusNode: focusNode,
                    style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                    decoration: InputDecoration(
                      labelText: 'What are you seeking?',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onInverseSurface),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30), // Set max length
                    ],
                  ),
                  const SizedBox(height: 24),
                  SmoothToggle(
                    initialIndex: isUrgent ? 1 : 0,
                    onTabChange: (selectedIndex) {
                      isUrgent = selectedIndex == 1;
                    },
                    tabs: const [
                      GButton(
                        icon: Icons.indeterminate_check_box_outlined,
                        text: 'Regular',
                      ),
                      GButton(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        text: 'Urgent',
                      ),
                    ],
                    isUrgent: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (seek != null) Utils.buildEmptyIcon(),
                      TealButton(
                        text: seek != null ? 'Update' : 'Publish',
                        onTap: () async {
                          if (seekController.text.isEmpty) {
                            focusNode.requestFocus();
                            Utils.showSnackBar(context, 'Please fill in all required fields.');
                            return;
                          } else if (seek?.itemName == seekController.text) {
                            if (seek?.reasons != null) {
                              Utils.showSnackBar(navigatorKey.currentContext!, 'Please rephrase.');
                              Navigator.pop(context);
                              return;
                            }
                            if (isUrgent == seek?.isUrgent) {
                              Utils.showSnackBar(navigatorKey.currentContext!, 'No change made.');
                            } else {
                              if (!mounted) return;

                              context
                                  .read<UserDataProvider>()
                                  .toggleUrgentStatus(seek!, isUrgent, context.read<ActiveSeeksProvider>());
                            }
                            Navigator.pop(context);
                            return;
                          }
                          final seekData = {
                            'itemName': seekController.text.trim(),
                            'isUrgent': isUrgent,
                            'updatedAt': FieldValue.serverTimestamp(),
                            'status': "Pending",
                          };
                          if (!mounted) return;
                          Utils.showLoading(context);
                          if (seek != null) {
                            if (seek.reasons != null) {
                              seekData['reasons'] = seek.reasons!;
                            }
                            await UserDataService().updateAd(context, seek.itemID, seekData, isSeek: true);
                          } else {
                            await UserDataService().createAd(context, seekData, isSeek: true);
                          }

                          Navigator.pop(context);
                        },
                      ),
                      if (seek != null)
                        Row(
                          children: [
                            SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                  onPressed: () => Utils.showDialogBox(
                                      context: context,
                                      message:
                                          'Are you sure you want to delete this seek?\nThis action cannot be undone.',
                                      onConfirm: () async {
                                        await UserDataService().deleteAdOrSeek(context, seek);
                                        Navigator.pop(context);
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      }),
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[400],
                                    size: 30,
                                  )),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      seekController.dispose();
      focusNode.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GNav(
        padding: const EdgeInsets.symmetric(vertical: 10),
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        selectedIndex: _selectedIndex,
        color: Theme.of(context).colorScheme.onPrimary,
        activeColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        tabBorderRadius: 16,
        onTabChange: (index) async {
          if (index == 2) {
            if ((await UserDataService().fetchUserProfile())?['hostel'] == null) {
              Utils.showDialogBox(
                  context: context,
                  message: 'Please update your profile to publish Ads.',
                  confirmText: "View Profile",
                  onConfirm: () {
                    _onTabChange(4);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserDetailsPage()),
                    );
                  });
              return;
            }
            _showCreateOptions(context);
          } else {
            _onTabChange(index);
          }
        },
        tabs: [
          GButton(
            icon: _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
            iconSize: 30,
            iconColor: Theme.of(context).colorScheme.onPrimary,
            iconActiveColor: Theme.of(context).colorScheme.onPrimary,
          ),
          GButton(
            icon: CupertinoIcons.search,
            iconSize: 25,
            iconColor: Theme.of(context).colorScheme.onPrimary,
            iconActiveColor: Theme.of(context).colorScheme.onPrimary,
            leading: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: _selectedIndex == 1 ? 3.1416 : 0, // Flip when selected
              ),
              duration: const Duration(milliseconds: 300),
              builder: (context, angle, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(angle),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 25,
                  ),
                );
              },
            ),
          ),
          GButton(
            icon: CupertinoIcons.plus_app_fill,
            iconSize: 35,
            iconColor: Color(0xFF00C1A2),
            iconActiveColor: Color(0xFF00C1A2),
          ),
          GButton(
            icon: _selectedIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
            iconSize: 24,
            margin: const EdgeInsets.only(top: 2),
            iconColor: Theme.of(context).colorScheme.onPrimary,
            iconActiveColor: Theme.of(context).colorScheme.onPrimary,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _selectedIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                if (_unread == true)
                  Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )),
              ],
            ),
          ),
          GButton(
            icon: _selectedIndex == 4 ? Icons.person : Icons.person_outline,
            iconSize: 28,
            iconColor: Theme.of(context).colorScheme.onPrimary,
            iconActiveColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}
