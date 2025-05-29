import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vbay/globals.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/services/data/link_service.dart';
import 'package:vbay/services/data/notification_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';

class CreatorService {
  static final CreatorService _instance = CreatorService._internal();

  factory CreatorService() => _instance;

  CreatorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCreatorID() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('Creator').doc('userID').get();
      if (docSnapshot.exists) {
        final Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        String? uid = data['aaditsingal7859@gmail.com'];
        return uid;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching UID from Firestore: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchPendingAds() async {
    Map<String, Map<String, dynamic>> rawPendingAdData = {};
    final List<Product> loadedProducts = [];
    try {
      final querySnapshot = await _firestore.collectionGroup('PendingAds').get();
      for (var doc in querySnapshot.docs) {
        final itemID = doc.id;
        final docData = doc.data();
        rawPendingAdData[itemID] = docData;
        loadedProducts.add(Product.fromMap(docData, itemID));
      }
    } catch (error) {
      print('Error fetching pending ads: $error');
    }
    return [rawPendingAdData, loadedProducts];
  }

  Future<void> approveAd(String itemID, Map<String, dynamic> dataToMove) async {
    try {
      WriteBatch batch = _firestore.batch();
      Map<String, dynamic>? userData = await UserDataService().fetchUserData(dataToMove['sellerID']);

      if (userData == null) return;

      if (!dataToMove.containsKey('itemURL')) {
        String itemURL = await LinkkService.createDynamicLink(Product.fromMap(
          dataToMove,
          itemID,
          userData['profile']['name'],
          userData['profile']['hostel'],
        ));
        print(itemURL);
        dataToMove['itemURL'] = itemURL;
      }

      dataToMove['updatedAt'] = FieldValue.serverTimestamp();
      dataToMove.remove('reasons');

      DocumentReference userSellingRef =
          _firestore.collection('Users').doc(dataToMove['sellerID']).collection('userSelling').doc(itemID);
      batch.update(userSellingRef, {
        'status': 'Active',
        'reasons': FieldValue.delete(),
        'itemURL': dataToMove['itemURL'],
        'updatedAt': dataToMove['updatedAt'],
      });

      DocumentReference activeAdsRef = _firestore.collection('ActiveAds').doc(itemID);
      batch.set(activeAdsRef, dataToMove);

      DocumentReference pendingAdsRef = _firestore.collection('PendingAds').doc(itemID);
      batch.delete(pendingAdsRef);

      await batch.commit();

      NotificationService().sendNotification(
        userData['fcmToken'],
        'Ad Approved!',
        'Your ad is live 🎉 Share it in your hostel!',
        msgData: {
          'type': 'approval',
          'itemID': itemID,
          'status': 'Active',
          'itemURL': dataToMove['itemURL'],
          'receiverID': dataToMove['sellerID'],
        },
      );

      QuerySnapshot usersWithHostelSnapshot;

      if (dataToMove['category'] == 'Food') {
        usersWithHostelSnapshot = await _firestore
            .collection('Users')
            .where('profile.college', isEqualTo: userData['profile']['college'])
            .where('profile.hostel', isEqualTo: userData['profile']['hostel'])
            .get();
      } else {
        usersWithHostelSnapshot = await _firestore
            .collection('Users')
            .where('profile.college', isEqualTo: userData['profile']['college'])
            .get();
      }

      WriteBatch notificationBatch = _firestore.batch();
      List<Future<void>> notificationFutures = [];
      final itemText = dataToMove['itemName'].split(' ').take(4).join(' ');

      for (var doc in usersWithHostelSnapshot.docs) {
        Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
        if (user['fcmToken'] != null && doc.id != dataToMove['sellerID']) {
          DateTime? lastNotification = (user['lastNotification'] as Timestamp?)?.toDate();
          DateTime now = DateTime.now();

          if (lastNotification == null || now.difference(lastNotification).inMinutes >= 1) {
            notificationFutures.add(NotificationService().sendNotification(
              user['fcmToken'],
              '🔍 ${userData['profile']['name'].split(' ')[0]} is selling $itemText!',
              'Tap to see!',
              msgData: {
                'type': 'new_sell',
                'itemID': itemID,
                'status': 'Active',
                'receiverID': doc.id,
              },
            ));

            notificationBatch.update(_firestore.collection('Users').doc(doc.id), {
              'lastNotification': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await Future.wait(notificationFutures);
      await notificationBatch.commit();
      Utils.showSnackBar(navigatorKey.currentContext!, 'Ad Approved');
    } catch (error) {
      print('Error approving ad: $error');
      Utils.showSnackBar(navigatorKey.currentContext!, 'Error approving ad: $error', true);
      rethrow;
    }
  }

  Future<void> rejectAd(String itemID, String userID, List<String> selectedReasons) async {
    final firestore = FirebaseFirestore.instance;

    try {
      Map<String, dynamic>? userData = await UserDataService().fetchUserData(userID);
      if (userData == null) return;

      WriteBatch batch = firestore.batch();

      DocumentReference pendingAdsRef = firestore.collection('PendingAds').doc(itemID);
      batch.delete(pendingAdsRef);

      DocumentReference userSellingRef =
          firestore.collection('Users').doc(userID).collection('userSelling').doc(itemID);
      batch.update(userSellingRef, {
        'status': 'Rejected',
        'reasons': selectedReasons,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      Utils.showSnackBar(navigatorKey.currentContext!, 'Ad Rejected!!', true);

      NotificationService().sendNotification(
        userData['fcmToken'],
        'Ad Rejected!',
        'Tap here to review why your ad was not approved',
        msgData: {
          'type': 'approval',
          'itemID': itemID,
          'status': 'Rejected',
          'reasons': selectedReasons.join(','),
          'receiverID': userID,
        },
      );
    } catch (error) {
      print('Error rejecting ad: $error');
      Utils.showSnackBar(navigatorKey.currentContext!, 'Error rejecting ad: $error', true);
      rethrow;
    }
  }

  Future<List<dynamic>> fetchPendingSeeks() async {
    Map<String, Map<String, dynamic>> rawPendingSeekData = {};
    final List<Seek> loadedSeeks = [];
    try {
      final querySnapshot = await _firestore.collectionGroup('PendingSeeks').get();
      for (var doc in querySnapshot.docs) {
        final itemID = doc.id;
        rawPendingSeekData[itemID] = doc.data();
        loadedSeeks.add(Seek.fromMap(doc.data(), itemID));
      }
    } catch (error) {
      print('Error fetching pending seeks: $error');
    }
    return [rawPendingSeekData, loadedSeeks];
  }

  Future<void> approveSeek(String itemID, Map<String, dynamic> dataToMove) async {
    try {
      Map<String, dynamic>? userData = await UserDataService().fetchUserData(dataToMove['seekerID']);
      if (userData == null) return;

      dataToMove['updatedAt'] = FieldValue.serverTimestamp();
      dataToMove.remove('reasons');

      WriteBatch batch = _firestore.batch();

      batch.update(
        _firestore.collection('Users').doc(dataToMove['seekerID']).collection('userSeeking').doc(itemID),
        {
          'status': 'Active',
          'updatedAt': FieldValue.serverTimestamp(),
          'reasons': FieldValue.delete(),
        },
      );
      batch.set(_firestore.collection('ActiveSeeks').doc(itemID), dataToMove);
      batch.delete(_firestore.collection('PendingSeeks').doc(itemID));

      await batch.commit();

      NotificationService().sendNotification(
        userData['fcmToken'],
        'Seek Approved!',
        'Your seek is live 🎉',
        msgData: {
          'type': 'approval',
          'itemID': itemID,
          'status': 'Active',
          'receiverID': dataToMove['seekerID'],
        },
      );

      QuerySnapshot usersWithHostelSnapshot = await _firestore
          .collection('Users')
          .where('profile.college', isEqualTo: userData['profile']['college'])
          .get();

      WriteBatch notificationBatch = _firestore.batch();
      List<Future<void>> notificationFutures = [];
      final itemText = dataToMove['itemName'].split(' ').take(4).join(' ');

      for (var doc in usersWithHostelSnapshot.docs) {
        Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
        if (user['fcmToken'] != null && doc.id != dataToMove['seekerID']) {
          DateTime? lastNotification = (user['lastNotification'] as Timestamp?)?.toDate();
          DateTime now = DateTime.now();

          if (lastNotification == null || now.difference(lastNotification).inMinutes >= 30) {
            notificationFutures.add(NotificationService().sendNotification(
              user['fcmToken'],
              '🔍 ${userData['profile']['name'].split(' ')[0]} is seeking $itemText!',
              'Have it? Reach out',
              msgData: {
                'type': 'new_seek',
                'itemID': itemID,
                'status': 'Active',
                'receiverID': doc.id,
              },
            ));

            notificationBatch.update(_firestore.collection('Users').doc(doc.id), {
              'lastNotification': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await Future.wait(notificationFutures);
      await notificationBatch.commit();
      Utils.showSnackBar(navigatorKey.currentContext!, 'Seek Approved');
    } catch (error) {
      print('Error approving seek: $error');
      Utils.showSnackBar(navigatorKey.currentContext!, 'Error approving seek: $error', true);
    }
  }

  Future<void> rejectSeek(String itemID, String userID, List<String> selectedReasons) async {
    try {
      Map<String, dynamic>? userData = await UserDataService().fetchUserData(userID);
      if (userData == null) return;
      WriteBatch batch = _firestore.batch();

      batch.delete(_firestore.collection('PendingSeeks').doc(itemID));
      batch.update(
        _firestore.collection('Users').doc(userID).collection('userSeeking').doc(itemID),
        {
          'status': 'Rejected',
          'reasons': selectedReasons,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      Utils.showSnackBar(navigatorKey.currentContext!, 'Seek Rejected!!', true);

      NotificationService().sendNotification(
        userData['fcmToken'],
        'Seek Rejected!',
        'Tap here to review why your ad was not approved',
        msgData: {
          'type': 'approval',
          'itemID': itemID,
          'status': 'Rejected',
          'reasons': selectedReasons.join(','),
          'receiverID': userID,
        },
      );
    } catch (error) {
      print('Error rejecting seek: $error');
      Utils.showSnackBar(navigatorKey.currentContext!, 'Error rejecting seek: $error', true);
      rethrow;
    }
  }

  Future<void> makeAdPending(dynamic item) async {
    try {
      WriteBatch batch = _firestore.batch();
      bool isProduct = item is Product;

      String userCollection = isProduct ? 'userSelling' : 'userSeeking';
      String activeCollection = isProduct ? 'ActiveAds' : 'ActiveSeeks';
      String pendingCollection = isProduct ? 'PendingAds' : 'PendingSeeks';

      String userId = isProduct ? item.sellerID : item.seekerID;

      DocumentReference userRef =
          _firestore.collection('Users').doc(userId).collection(userCollection).doc(item.itemID);

      batch.update(userRef, {
        'status': 'Pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      DocumentReference activeRef = _firestore.collection(activeCollection).doc(item.itemID);
      DocumentReference pendingRef = _firestore.collection(pendingCollection).doc(item.itemID);

      batch.set(pendingRef, item.toMap());
      batch.delete(activeRef);

      await batch.commit();

      Utils.showSnackBar(navigatorKey.currentContext!, 'Item moved to Pending');
    } catch (error) {
      print('Error moving item to pending: $error');
      Utils.showSnackBar(navigatorKey.currentContext!, 'Error moving item to pending', true);
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> fetchStatsStream() {
    final DateTime last24Hours = DateTime.now().subtract(Duration(days: 1));

    final usersStream = _firestore.collection('Users').snapshots();
    final activeAdsStream = _firestore.collection('ActiveAds').snapshots();
    final activeSeeksStream = _firestore.collection('ActiveSeeks').snapshots();
    final pendingAdsStream = _firestore.collection('PendingAds').snapshots();
    final pendingSeeksStream = _firestore.collection('PendingSeeks').snapshots();
    final liveStatsStream = fetchLiveStats();
    final soldItemsStream = _firestore.collection('SoldItems').snapshots();
    final feedbackStream = _firestore.collection('Feedback').snapshots();
    final chatRoomsStream = _firestore.collection('ChatRooms').snapshots();

    return CombineLatestStream.list([
      usersStream,
      activeAdsStream,
      activeSeeksStream,
      pendingAdsStream,
      pendingSeeksStream,
      liveStatsStream,
      soldItemsStream,
      feedbackStream,
      chatRoomsStream,
    ]).asyncMap((snapshots) async {
      try {
        final usersSnapshot = snapshots[0] as QuerySnapshot;
        final activeAdsSnapshot = snapshots[1] as QuerySnapshot;
        final activeSeeksSnapshot = snapshots[2] as QuerySnapshot;
        final pendingAdsSnapshot = snapshots[3] as QuerySnapshot;
        final pendingSeeksSnapshot = snapshots[4] as QuerySnapshot;
        final liveStats = snapshots[5] as Map<String, dynamic>;
        final soldItemsSnapshot = snapshots[6] as QuerySnapshot;
        final feedbackSnapshot = snapshots[7] as QuerySnapshot;
        final chatRoomsSnapshot = snapshots[8] as QuerySnapshot;

        Map<String, List<Map<String, dynamic>>> totalUsers = {};
        Map<String, List<Map<String, dynamic>>> newUsers24H = {};

        for (var college in colleges.values) {
          totalUsers[college] = [];
          newUsers24H[college] = [];
        }

        for (var doc in usersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('profile')) {
            var profile = data['profile'] as Map<String, dynamic>?;
            String? userCollege = profile?['college']?.toString();
            if (userCollege != null && colleges.values.contains(userCollege)) {
              totalUsers[userCollege]!.add(data);

              var createdAt = data['createdAt'];
              if (createdAt is Timestamp && createdAt.toDate().isAfter(last24Hours)) {
                newUsers24H[userCollege]!.add(data);
              }
            }
          }
        }

        int totalSold = soldItemsSnapshot.size;
        int helpedSold = soldItemsSnapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>?;
          return data?['didVBayHelp'] == true;
        }).length;

        int totalFeedback = feedbackSnapshot.size;
        int solvedFeedback = feedbackSnapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>?;
          return data?['solved'] == true;
        }).length;

        return {
          'total_users': totalUsers,
          'new_users_24H': newUsers24H,
          'live_users': liveStats['live_users'] ?? {},
          'active_users_24H': liveStats['active_users_24H'] ?? {},
          'active_ads': activeAdsSnapshot.size,
          'active_seeks': activeSeeksSnapshot.size,
          'pending_ads': pendingAdsSnapshot.size,
          'pending_seeks': pendingSeeksSnapshot.size,
          'sold_items': '$helpedSold/$totalSold',
          'feedbacks': '$solvedFeedback/$totalFeedback',
          'chat_rooms': chatRoomsSnapshot.size,
        };
      } catch (e) {
        print('Error fetching stats: $e');
        Utils.showSnackBar(navigatorKey.currentContext!, 'Error fetching stats: $e', true);

        return {
          'total_users': {},
          'new_users_24H': {},
          'live_users': {},
          'active_users_24H': {},
          'active_ads': 0,
          'active_seeks': 0,
          'pending_ads': 0,
          'pending_seeks': 0,
          'sold_items': '0/0',
          'feedbacks': '0/0',
          'chat_rooms': 0,
        };
      }
    });
  }

  Stream<Map<String, dynamic>> fetchLiveStats() {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final DateTime last24Hours = DateTime.now().subtract(Duration(days: 1));

    return CombineLatestStream.list([
      dbRef.child("status").onValue,
    ]).map((events) {
      final statusEvent = events[0];
      final data = statusEvent.snapshot.value as Map<dynamic, dynamic>? ?? {};

      Map<String, List<String>> liveUsersByCollege = {};
      Map<String, int> activeUsers24HByCollege = {};

      for (var college in colleges.values) {
        liveUsersByCollege[college] = [];
      }

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final userId = key.toString();
          final userCollege = value['college']?.toString();

          if (userCollege != null && colleges.values.contains(userCollege)) {
            if (value['isActive'] == true) {
              liveUsersByCollege[userCollege]?.add(userId);
            }

            if (value['lastActive'] != null) {
              DateTime lastActiveTime = DateTime.fromMillisecondsSinceEpoch(value['lastActive']);
              if (lastActiveTime.isAfter(last24Hours)) {
                activeUsers24HByCollege[userCollege] = (activeUsers24HByCollege[userCollege] ?? 0) + 1;
              }
            }
          }
        }
      });

      return {
        'live_users': liveUsersByCollege,
        'active_users_24H': activeUsers24HByCollege,
      };
    });
  }
}
