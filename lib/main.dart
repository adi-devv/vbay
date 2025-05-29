import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:vbay/services/app_lifecycle_handler.dart';
import 'package:vbay/components/my_navigator_observer.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/providers/active_seeks_provider.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/providers/bookmarks_provider.dart';
import 'package:vbay/providers/chat_provider.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:vbay/services/data/notification_service.dart';
import 'package:vbay/firebase_options.dart';
import 'package:vbay/services/auth/auth_gate.dart';
import 'package:vbay/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<AppLifecycleHandlerState> appLifecycleKey = GlobalKey<AppLifecycleHandlerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await Hive.initFlutter();
  await Hive.openBox('settings');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await NotificationService().initNotification();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => ActiveAdsProvider()),
        ChangeNotifierProvider(create: (_) => ActiveSeeksProvider()),
        ChangeNotifierProvider(create: (_) => BookmarksProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: AppLifecycleHandler(
        key: appLifecycleKey,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("MyApp Rebuilt");

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedTheme(
          duration: const Duration(milliseconds: 300),
          data: themeProvider.themeData,
          child: MaterialApp(
            navigatorObservers: [MyNavigatorObserver()],
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            navigatorKey: navigatorKey,
            home: const AuthGate(),
          ),
        );
      },
    );
  }
}

//flutter build appbundle --release --obfuscate --split-debug-info=./debug-symbols/

//To add new device, dev mode --> adb devices

//firebase deploy --only functions
