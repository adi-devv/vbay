import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vbay/main.dart';
import 'package:vbay/pages/intro_page.dart';
import 'package:vbay/pages/nav/route_page.dart';
import 'package:vbay/services/auth/auth_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ValueNotifier<bool> _isUserDataInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _newSignIn = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (!_isUserDataInitialized.value) {
            _initializeUserData(snapshot.data!);
            _isUserDataInitialized.value = true;
          }

          if (_newSignIn.value) {
            Utils.hideLoading();
            return RoutePage();
          }
          return RoutePage();
          // return IntroPage(
          //   signedIn: true,
          //   onTap: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => const RoutePage()),
          //     );
          //   },
          // );
        } else {
          if (_isUserDataInitialized.value) {
            Future.microtask(() {
              _isUserDataInitialized.value = false;
              _newSignIn.value = false;
            });
          }
        }

        return IntroPage(
          signedIn: false,
          onTap: () async {
            _newSignIn.value = true;
            await AuthService().signInWithGoogle(context);
          },
        );
      },
    );
  }

  Future<void> _initializeUserData(User user) async {
    try {
      await UserDataService().initializeUserData(user);
      appLifecycleKey.currentState?.setupPresence();
    } catch (e) {
      Utils.hideLoading();
      debugPrint("Error initializing user data: $e");

      if (navigatorKey.currentContext != null) {
        Utils.showSnackBar(
          navigatorKey.currentContext!,
          'Internet not available. Please try again.',
          true,
        );
      }
    }
  }
}
