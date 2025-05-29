import 'package:flutter/cupertino.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vbay/components/my_logo.dart';
import 'package:vbay/components/smooth_toggle.dart';
import 'package:vbay/components/user_agreement.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/pages/nav/profile/user_details_page.dart';
import 'package:flutter/material.dart';
import 'package:vbay/services/auth/auth_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/theme/theme_provider.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout(BuildContext context) {
    AuthService().signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Theme
          .of(context)
          .brightness == Brightness.dark
          ? BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 100,
            offset: Offset(4, 0), // Shadow on the right side
          ),
        ],
      )
          : null,
      child: Drawer(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .secondary,
        child: Column(
          children: [
            SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: DividerThemeData(color: Colors.transparent),
              ),
              child: DrawerHeader(
                child: Center(child: MyLogo(fontSize: 48)),
              ),
            ),
            SmoothToggle(
              tabs: [
                GButton(icon: Icons.dark_mode),
                GButton(icon: Icons.light_mode),
              ],
              initialIndex: Provider
                  .of<ThemeProvider>(context)
                  .isDarkMode ? 0 : 1,
              onTabChange: (index) {
                final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                if (themeProvider.isDarkMode != (index == 0)) {
                  themeProvider.toggleTheme();
                }
              },
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 25),
              child: ListTile(
                  title: Text('Home'),
                  leading: Icon(Icons.home),
                  onTap: () {
                    Navigator.pop(context);
                    BottomNavbarKey.instance.key.currentState?.changeTab(0);
                  }),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25),
              child: ListTile(
                  title: Text('Seeks'),
                  leading: Icon(CupertinoIcons.search),
                  onTap: () {
                    Navigator.pop(context);
                    BottomNavbarKey.instance.key.currentState?.changeTab(1);
                  }),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25),
              child: ListTile(
                  title: Text('Chats'),
                  leading: Icon(Icons.chat_bubble_outline_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    BottomNavbarKey.instance.key.currentState?.changeTab(3);
                  }),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25),
              child: ListTile(
                  title: Text('Feedback'),
                  leading: Icon(Icons.feedback_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    showFeedbackDialog(context);
                  }),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: ListTile(
                leading: SizedBox(
                  width: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/insta2.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text('Follow Us!'),
                onTap: () async {
                  final Uri instaUrl = Uri.parse('https://instagram.com/vbay.app');
                  if (await canLaunchUrl(instaUrl)) {
                    await launchUrl(instaUrl, mode: LaunchMode.externalApplication);
                  } else {
                    Utils.showSnackBar(context, "Couldn't open Instagram");
                  }
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25),
              child: ListTile(
                  title: Text('User Agreement'),
                  leading: Icon(Icons.article_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    showUserAgreement(context);
                  }),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25, bottom: 16),
              child: ListTile(
                title: Text('Logout'),
                leading: Icon(Icons.logout),
                onTap: () {
                  logout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showFeedbackDialog(BuildContext context) {
    final theme = Theme.of(context);
    TextEditingController feedbackController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Feedback Dialog",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: AlertDialog(
            title: const Text(
              "Submit Feedback",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: theme.colorScheme.secondary,
            content: TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: "Share your thoughts",
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              Center(
                child: InkWell(
                  onTap: () {
                    String feedback = feedbackController.text.trim();
                    if (feedback.isNotEmpty) {
                      Navigator.pop(context);
                      UserDataService().postFeedback(feedback);
                      Utils.showSnackBar(navigatorKey.currentContext!, 'Your feedback has been recorded!');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .secondary,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
