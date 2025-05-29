import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  AppLifecycleHandlerState createState() => AppLifecycleHandlerState();
}

class AppLifecycleHandlerState extends State<AppLifecycleHandler> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  DatabaseReference? _userRef;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setupPresence();

    // Future.microtask(() async {
    //   await migrateAllUsersSoldItems();
    // });
  }

  void setupPresence() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _userRef = _dbRef.child("status/$uid");
    var userData = await UserDataService().fetchUserData();
    _userRef!.set({
      "isActive": true,
      "lastActive": ServerValue.timestamp,
      'college': userData?['profile']['college'],
    });
    _userRef!.onDisconnect().update({
      "isActive": false,
      "lastActive": ServerValue.timestamp,
    });
  }

  void disconnect() {
    _userRef?.update({
      "isActive": false,
      "lastActive": ServerValue.timestamp,
    });
    _userRef?.onDisconnect().cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setupPresence();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      disconnect();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
  //
  // Future<void> migrateAllUsersSoldItems() async {
  //   try {
  //     final usersSnapshot = await _firestore.collection('Users').get();
  //
  //     for (var userDoc in usersSnapshot.docs) {
  //       final userId = userDoc.id;
  //       final userSellingRef = _firestore.collection('Users').doc(userId).collection('userSelling');
  //       final soldAdsRef = _firestore.collection('Users').doc(userId).collection('soldAds');
  //
  //       final sellingSnapshot = await userSellingRef.get();
  //       final batch = _firestore.batch();
  //
  //       for (var itemDoc in sellingSnapshot.docs) {
  //         final data = itemDoc.data();
  //         final status = data['status'];
  //
  //         if (status == 'Sold') {
  //           // Delete from userSelling
  //           batch.delete(userSellingRef.doc(itemDoc.id));
  //
  //           // Add to soldAds
  //           final Map<String, dynamic> cleanedData = Map<String, dynamic>.from(data);
  //           cleanedData['updatedAt'] = FieldValue.serverTimestamp();
  //
  //           batch.set(soldAdsRef.doc(itemDoc.id), cleanedData);
  //         }
  //       }
  //
  //       if (batch != null) {
  //         await batch.commit();
  //         print('Migrated sold items for user: $userId');
  //       }
  //     }
  //
  //     print('✅ Migration of all users sold items completed.');
  //   } catch (e) {
  //     print('Error migrating all users sold items: $e');
  //     throw Exception('Failed migration: $e');
  //   }
  // }
}
