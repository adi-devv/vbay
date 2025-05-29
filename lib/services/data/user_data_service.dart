import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/update_required.dart';
import 'package:vbay/components/user_agreement.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/globals.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/pages/nav/profile/user_details_page.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/services/data/notification_service.dart';
import 'package:pub_semver/pub_semver.dart';

String formatName(String? name) {
  if (name == null || name.isEmpty) return '';

  return name
      .split(' ')
      .where((word) => !word.contains(RegExp(r'\d'))) // Filter out words with digits
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  UserDataService._internal();

  static final UserDataService _instance = UserDataService._internal();

  factory UserDataService() => _instance;

  Map<String, dynamic>? _cachedUserData;

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  StreamSubscription<DocumentSnapshot>? _updateSubscription;

  void checkForUpdates(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    _updateSubscription = firestore.collection("AppData").doc("version").snapshots().listen((snapshot) async {
      try {
        if (!snapshot.exists) return;

        var data = snapshot.data() as Map<String, dynamic>;
        String latestVersion = data["latestVersion"];
        bool updateRequired = data["updateRequired"];
        bool showUpdate = data["showUpdate"];
        String updateMessage = data["updateMessage"] ?? "A new version is available!";

        if (!showUpdate) return;
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = "${packageInfo.version}+${packageInfo.buildNumber}";

        print("Current Version: $currentVersion");
        print("Latest Version: $latestVersion");

        List<String> currentParts = currentVersion.split('+');
        List<String> latestParts = latestVersion.split('+');

        int currentBuild = currentParts.length > 1 ? int.parse(currentParts[1]) : 0;
        int latestBuild = latestParts.length > 1 ? int.parse(latestParts[1]) : 0;

        bool needsUpdate = latestBuild > currentBuild;

        if (needsUpdate) {
          print("Showing update dialog...");
          if (context.mounted) {
            showUpdateRequired(context, updateMessage, updateRequired);
          }
        } else {
          print("Latest version installed!");
        }
      } catch (e) {
        print("Error checking update: $e");
      }
    });
  }

  String getName() {
    final profile = _cachedUserData?['profile'];
    if (profile != null && profile['name'] != null) {
      return profile['name'].split(' ').first;
    }
    return 'Guest';
  }

  Future<void> initializeUserData(User user) async {
    final docRef = _firestore.collection('Users').doc(user.uid);

    try {
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print(navigatorKey.currentContext == null);
        showUserAgreement(navigatorKey.currentContext!, toAccept: true, onAccept: () async {
          await _createUserDocument(docRef, user);
          Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(builder: (context) => const UserDetailsPage()),
          );
        });
      } else {
        _cachedUserData = docSnapshot.data();
        String? fcmToken = await NotificationService().getFCMToken();

        if (docSnapshot.data()!['fcmToken'] == null || fcmToken != docSnapshot.data()!['fcmToken']) {
          await docRef.update({'fcmToken': fcmToken});
          _cachedUserData!['fcmToken'] = fcmToken;
        }
      }
    } catch (e) {
      print("Error initializing user data: $e");
    }
  }

  // Helper to create user document
  Future<void> _createUserDocument(DocumentReference docRef, User user) async {
    final String college = colleges[user.email!.split('@').last]!;
    final Map<String, dynamic> initialData = {
      'uid': user.uid,
      'email': user.email,
      'fcmToken': await NotificationService().getFCMToken(),
      'profile': {
        'name': formatName(user.displayName),
        'avatarUrl': null,
        'college': college,
        'batch': null,
        'hostel': null,
        'phone': null,
        'bio': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    _cachedUserData = initialData;
    WriteBatch batch = _firestore.batch();
    batch.set(docRef, initialData);

    await batch.commit();
  }

  Future<Map<String, dynamic>?> fetchUserData([String? uid]) async {
    if (uid != null) {
      try {
        var userSnapshot = await _firestore.collection('Users').doc(uid).get();
        if (userSnapshot.exists) {
          return userSnapshot.data();
        } else {
          return null;
        }
      } catch (e) {
        print('Error fetching user profile: $e');
        return null;
      }
    } else {
      while (_cachedUserData == null && getCurrentUser() != null) {
        print('Waiting for cached user data...');
        await Future.delayed(Duration(milliseconds: 1000));
      }
      return _cachedUserData;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    while (_cachedUserData == null) {
      print('Waiting for cached user data...');
      await Future.delayed(Duration(milliseconds: 1000));
    }
    return _cachedUserData?['profile'];
  }

  Future<void> saveUserProfile(BuildContext context, Map<String, dynamic> profileData) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      await _firestore.collection('Users').doc(user.uid).set({'profile': profileData}, SetOptions(merge: true));
      _updateCachedUserData({'profile': profileData});
      context.read<UserDataProvider>().updateUserData(profileData);

      final userName = profileData['name'] ?? _cachedUserData?['profile']['name'];
      final userHostel = profileData['hostel'] ?? _cachedUserData?['profile']['hostel'];

      await _updateAdsAndSeeksForUser(user.uid, userName, userHostel);
    } catch (e) {
      print("Error saving user profile: $e");
      throw Exception("Failed to save user profile");
    }
  }

  Future<void> _updateAdsAndSeeksForUser(String userId, String? userName, String? userHostel) async {
    try {
      final snapshots = await Future.wait([
        _firestore.collection('Users').doc(userId).collection('userSelling').get(),
        _firestore.collection('Users').doc(userId).collection('userSeeking').get(),
      ]);

      final targetCollections = {
        'Active': {
          true: 'ActiveSeeks',
          false: 'ActiveAds',
        },
        'Pending': {
          true: 'PendingSeeks',
          false: 'PendingAds',
        },
      };

      for (var snapshot in snapshots) {
        for (var doc in snapshot.docs) {
          final itemId = doc.id;
          final itemStatus = doc['status'];
          final isSeeking = snapshot == snapshots[1];

          final targetCollection = targetCollections[itemStatus]?[isSeeking ? true : false];

          if (targetCollection != null) {
            final docRef = _firestore.collection(targetCollection).doc(itemId);
            await docRef.get().then((docSnapshot) {
              if (docSnapshot.exists) {
                docRef.update({
                  // if (!isSeeking && userName != null) 'sellerName': userName,
                  if (!isSeeking && userHostel != null) 'sellerHostel': userHostel,
                  // if (isSeeking && userName != null) 'seekerName': userName,
                  if (isSeeking && userHostel != null) 'seekerHostel': userHostel,
                });
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error updating Ads/Seeks: $e");
    }
  }

  Future<List<Product>> fetchActiveAds() async {
    final List<Product> activeAdsList = [];
    try {
      Map<String, dynamic>? userData = await fetchUserProfile();
      final querySnapshot =
          await _firestore.collectionGroup('ActiveAds').where('college', isEqualTo: userData!['college']).get();
      for (var doc in querySnapshot.docs) {
        final itemID = doc.id;
        activeAdsList.add(Product.fromMap(doc.data(), itemID, null, null, 'Active'));
      }
    } catch (error) {
      print('Error fetching active ads: $error');
    }
    return activeAdsList;
  }

  Future<List<Seek>> fetchActiveSeeks() async {
    final List<Seek> activeSeeksList = [];

    try {
      Map<String, dynamic>? userData = await fetchUserProfile();

      final querySnapshot =
          await _firestore.collectionGroup('ActiveSeeks').where('college', isEqualTo: userData!['college']).get();
      for (var doc in querySnapshot.docs) {
        final itemID = doc.id;
        activeSeeksList.add(Seek.fromMap(doc.data(), itemID));
      }
    } catch (error) {
      print('Error fetching active seeks: $error');
    }

    return activeSeeksList;
  }

  Future<List<List<dynamic>>> fetchUserAds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No authenticated user found. Please log in.");
    }

    if (_cachedUserData == null) {
      await fetchUserProfile();
    }

    final List<Product> userSelling = [];
    final List<Seek> userSeeking = [];

    try {
      // Fetch selling items
      final sellingSnapshot = await _firestore.collection('Users').doc(user.uid).collection('userSelling').get();

      if (sellingSnapshot.docs.isEmpty) {
        print('No selling items found.');
      } else {
        for (var doc in sellingSnapshot.docs) {
          final itemID = doc.id;
          final name = _cachedUserData?['profile']?['name'] ?? 'No Name Available';
          final hostel = _cachedUserData?['profile']?['hostel'] ?? 'No Hostel Information';

          userSelling.add(
            Product.fromMap(doc.data(), itemID, name, hostel),
          );
        }
      }

      // Fetch seeking items
      final seekingSnapshot = await _firestore.collection('Users').doc(user.uid).collection('userSeeking').get();

      if (seekingSnapshot.docs.isEmpty) {
        print('No seeking items found.');
      } else {
        for (var doc in seekingSnapshot.docs) {
          final itemID = doc.id;
          final name = _cachedUserData?['profile']?['name'] ?? 'No Name Available';
          final hostel = _cachedUserData?['profile']?['hostel'] ?? 'No Hostel Information';

          userSeeking.add(
            Seek.fromMap(doc.data(), itemID, name, hostel),
          );
        }
      }
    } catch (error) {
      print('Error fetching user ads: $error');
    }

    return [userSelling, userSeeking];
  }

  Future<void> saveBookmarks(List<Product> products) async {
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference userRef = _firestore.collection('Users').doc(getCurrentUser()!.uid);
      CollectionReference bookmarksRef = userRef.collection('userBookmarks');

      List<String> itemIDs = [];

      for (var product in products) {
        DocumentReference productRef = bookmarksRef.doc(product.itemID);
        batch.set(productRef, product.toMap());

        itemIDs.add(product.itemID!);
      }

      batch.update(userRef, {
        'bookmarks': itemIDs.join('_'),
      });

      await batch.commit();
      print('Bookmarks saved successfully.');
    } catch (error) {
      print('Error saving bookmarks: $error');
    }
  }

  Future<QuerySnapshot?> fetchInactiveUserBookmarks() async {
    try {
      return await FirebaseFirestore.instance
          .collection('Users')
          .doc(getCurrentUser()!.uid)
          .collection('userBookmarks')
          .get();
    } catch (e) {
      print('Error fetching user bookmarks: $e');
      return null;
    }
  }

  Future<List<dynamic>> getAnotherUserData(String userId) async {
    try {
      final userRef = _firestore.collection('Users').doc(userId);
      final userData = await fetchUserData(userId);

      final userAds = await userRef
          .collection('userSelling')
          .where('status', whereIn: ['Active', 'Sold'])
          .get()
          .then((querySnapshot) {
            return querySnapshot.docs
                .map((doc) => Product.fromMap(
                      doc.data(),
                      doc.id,
                      userData!['profile']['name'],
                      userData['profile']['hostel'],
                      null,
                      userData['uid'],
                    ))
                .toList();
          })
          .catchError((e) {
            print('Error fetching selling data: $e');
            return <Product>[];
          });

      final userSeeks =
          await userRef.collection('userSeeking').where('status', isEqualTo: 'Active').get().then((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => Seek.fromMap(
                  doc.data(),
                  doc.id,
                  userData!['profile']['name'],
                  userData['profile']['hostel'],
                  userData['uid'],
                ))
            .toList();
      }).catchError((e) {
        print('Error fetching seeking data: $e');
        return <Seek>[];
      });

      final results = [userData, userAds, userSeeks];

      return results;
    } catch (e) {
      print('Error in getAnotherUserData: $e');
      return [null, [], []];
    }
  }

  Stream<Map<String, dynamic>?> fetchAdStream(String userID, String itemID) {
    return _firestore
        .collection('Users')
        .doc(userID)
        .collection('userSelling')
        .doc(itemID)
        .snapshots()
        .map((adSnapshot) {
      try {
        if (adSnapshot.exists) {
          return adSnapshot.data();
        } else {
          return null;
        }
      } catch (e) {
        print("Error fetching ad data: $e");
        return null;
      }
    });
  }

  Future<Product?> fetchAd(String itemID) async {
    try {
      var adSnapshot = await _firestore.collection('ActiveAds').doc(itemID).get();

      if (adSnapshot.exists) {
        var product = Product.fromMap(adSnapshot.data()!, itemID);
        return product;
      }
    } catch (e) {
      print("Error fetching ad: $e");
    }
    return null;
  }

  // Create Sell/Seek
  Future<void> createAd(BuildContext context, Map<String, dynamic> data, {bool isSeek = false}) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      if (!isSeek) {
        String? imageUrl = await _uploadImage(data['imagePath'], user);
        if (imageUrl != null) data['imagePath'] = imageUrl;
      }

      final collectionName = isSeek ? 'userSeeking' : 'userSelling';
      final pendingCollectionName = isSeek ? 'PendingSeeks' : 'PendingAds';

      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['createdAt'] = FieldValue.serverTimestamp();

      final docRef = _firestore.collection('Users').doc(user.uid).collection(collectionName).doc();

      WriteBatch batch = _firestore.batch();
      batch.set(docRef, dataWithTimestamp);

      final adData = _prepareAdData(data, user.uid, isSeek);
      batch.set(_firestore.collection(pendingCollectionName).doc(docRef.id), adData);

      await batch.commit();
      final userAdsProvider = Provider.of<UserDataProvider>(context, listen: false);
      if (isSeek) {
        userAdsProvider.insertItem(
          Seek.fromMap(data, docRef.id, _cachedUserData?['profile']['name'], _cachedUserData?['profile']['hostel']),
        );
      } else {
        userAdsProvider.insertItem(
          Product.fromMap(data, docRef.id, _cachedUserData?['profile']['name'], _cachedUserData?['profile']['hostel']),
        );
      }
    } catch (e) {
      throw Exception("Failed to create ${isSeek ? 'seek' : 'item'}: $e");
    }
  }

  Future<void> updateAdDirectly(BuildContext context, String itemID, Map<String, dynamic> itemData) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      await _firestore.collection('Users').doc(user.uid).collection('userSelling').doc(itemID).update(itemData);
      await _firestore.collection('ActiveAds').doc(itemID).update(itemData);
      Provider.of<UserDataProvider>(context, listen: false).updateItem(
        Product.fromMap(itemData, itemID, _cachedUserData?['profile']['name'], _cachedUserData?['profile']['hostel']),
      );
    } catch (e) {
      throw Exception("Failed to update item: $e");
    }
  }

  // Update Sell/Seek
  Future<void> updateAd(BuildContext context, String itemID, Map<String, dynamic> itemData,
      {bool isSeek = false}) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      final collectionName = isSeek ? 'userSeeking' : 'userSelling';
      final activeCollectionName = isSeek ? 'ActiveSeeks' : 'ActiveAds';
      final pendingCollectionName = isSeek ? 'PendingSeeks' : 'PendingAds';

      final userItemRef = _firestore.collection('Users').doc(user.uid).collection(collectionName).doc(itemID);
      final activeItemRef = _firestore.collection(activeCollectionName).doc(itemID);
      final pendingItemRef = _firestore.collection(pendingCollectionName).doc(itemID);

      final userItemSnapshot = await userItemRef.get();
      if (!userItemSnapshot.exists) {
        throw Exception("Item not found");
      }

      final batch = _firestore.batch();

      final currentItemData = userItemSnapshot.data();
      if (currentItemData != null && currentItemData['status'] == 'Active') {
        batch.delete(activeItemRef);
      }

      batch.update(userItemRef, itemData);

      final pendingData = _prepareAdData(itemData, user.uid, isSeek);
      batch.set(pendingItemRef, pendingData);

      await batch.commit();
      final userAdsProvider = Provider.of<UserDataProvider>(context, listen: false);
      itemData.remove('reasons');

      if (isSeek) {
        userAdsProvider.updateItem(
          Seek.fromMap(itemData, itemID, _cachedUserData?['profile']['name'], _cachedUserData?['profile']['hostel']),
        );
      } else {
        userAdsProvider.updateItem(
          Product.fromMap(itemData, itemID, _cachedUserData?['profile']['name'], _cachedUserData?['profile']['hostel']),
        );
      }
    } catch (e) {
      throw Exception("Failed to update ${isSeek ? 'seek' : 'item'}: $e");
    }
  }

  // Toggle Ad Status
  Future<void> toggleItemActiveStatus(String itemID, String statusTo, {bool isSeek = false}) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      final collectionName = isSeek ? 'userSeeking' : 'userSelling';
      final activeCollectionName = isSeek ? 'ActiveSeeks' : 'ActiveAds';
      final userItemRef = _firestore.collection('Users').doc(user.uid).collection(collectionName).doc(itemID);

      final userItemSnapshot = await userItemRef.get();
      if (!userItemSnapshot.exists) {
        throw Exception("Item not found");
      }

      final batch = _firestore.batch();

      if (statusTo == 'Inactive') {
        batch.update(userItemRef, {'status': 'Inactive'});
        batch.delete(_firestore.collection(activeCollectionName).doc(itemID));
      } else if (statusTo == 'Active') {
        batch.update(userItemRef, {'status': 'Active'});

        final data = userItemSnapshot.data() ?? {};
        data.removeWhere((key, value) => key == 'status' || key == 'createdAt'); // Maintains data consistency
        final activeData = _prepareAdData(data, user.uid, isSeek);
        batch.set(_firestore.collection(activeCollectionName).doc(itemID), activeData);
      }

      await batch.commit();
    } catch (e) {
      print("Error toggling status: $e");
      throw Exception("Failed to toggle item status: $e");
    }
  }

  Future<void> toggleUrgentStatus(Seek seek) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference userSeekingDoc = FirebaseFirestore.instance
          .collection('Users')
          .doc(getCurrentUser()!.uid)
          .collection('userSeeking')
          .doc(seek.itemID);
      batch.update(userSeekingDoc, {'isUrgent': seek.isUrgent});

      if (seek.status == 'Active') {
        DocumentReference activeSeekDoc = FirebaseFirestore.instance.collection('ActiveSeeks').doc(seek.itemID);
        batch.update(activeSeekDoc, {'isUrgent': seek.isUrgent});
      }
      await batch.commit();
      Utils.showSnackBar(navigatorKey.currentContext!, 'Seek updated successfully.');
    } catch (e) {
      print("Error updating urgency status: $e");
    }
  }

  Future<void> deleteAdOrSeek(BuildContext context, dynamic item) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      final bool isSeek = item is Seek;
      final String itemID = item.itemID;

      final collectionName = isSeek ? 'userSeeking' : 'userSelling';
      final activeCollectionName = isSeek ? 'ActiveSeeks' : 'ActiveAds';
      final archivedCollectionName = isSeek ? 'archivedSeeks' : 'archivedAds';

      final batch = _firestore.batch();

      if (item.status == 'Active') {
        batch.delete(_firestore.collection(activeCollectionName).doc(itemID));
      }

      batch.delete(_firestore.collection('Users').doc(user.uid).collection(collectionName).doc(itemID));
      batch.set(
        _firestore.collection('Users').doc(user.uid).collection(archivedCollectionName).doc(itemID),
        {
          ...(item.toMap() as Map<String, dynamic>),
          'college': _cachedUserData!['profile']['college'],
          'sellerID': _cachedUserData!['uid'],
        },
      );

      await batch.commit();
      print("Item successfully deleted and archived.");
      context.read<UserDataProvider>().deleteItem(item);
      Utils.showSnackBar(
          navigatorKey.currentContext!, isSeek ? 'Seek deleted successfully.' : 'Ad deleted successfully.');
    } catch (e) {
      print("Error deleting item: $e");
      throw Exception("Failed to delete item: $e");
    }
  }

  Future<void> markAsSold(BuildContext context, dynamic item, bool didVBayHelp) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No authenticated user found");

    try {
      if (item is Seek) {
        // If it's a Seek, leave it as TODO
        print("Seek item marked as TODO. No further action taken.");
        return;
      } else if (item is Product) {
        final batch = _firestore.batch();

        if (item.status == 'Active') {
          final activeAdRef = _firestore.collection('ActiveAds').doc(item.itemID);
          batch.update(activeAdRef, {
            'status': 'Sold',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final soldItemRef = _firestore.collection('SoldItems').doc(item.itemID);
        item.sellerID = user.uid;
        batch.set(soldItemRef, {
          ...item.toMap(),
          'college': _cachedUserData!['profile']['college'],
          'didVBayHelp': didVBayHelp,
        });

        final userSellingRef = _firestore.collection('Users').doc(user.uid).collection('userSelling').doc(item.itemID);
        final userSoldRef = _firestore.collection('Users').doc(user.uid).collection('soldAds').doc(item.itemID);

        batch.delete(userSellingRef);

        batch.set(userSoldRef, {
          ...item.toMap(),
          'status': 'Sold',
          'college': _cachedUserData!['profile']['college'],
          'didVBayHelp': didVBayHelp,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        Provider.of<UserDataProvider>(context, listen: false).markAsSold(item.itemID!);
        if (item.status == 'Active') Provider.of<ActiveAdsProvider>(context, listen: false).markAsSold(item.itemID!);

        print("Product marked as sold successfully.");
      } else {
        print("Product is not active. No action taken.");
      }
    } catch (e) {
      print("Error marking item as sold: $e");
      throw Exception("Failed to mark item as sold: $e");
    }
  }

  // Upload Image
  Future<String?> _uploadImage(String? imagePath, User user) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final file = File(imagePath);
      final fileName = 'Users/product_images/${user.uid}_${user.email}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Add necessary info
  Map<String, dynamic> _prepareAdData(Map<String, dynamic> itemData, String userID, [bool isSeek = false]) {
    return {
      ...Map.from(itemData)..remove('status'),
      if (isSeek) ...{
        'seekerID': userID,
        'seekerName': _cachedUserData?['profile']?['name'] ?? '',
        'seekerHostel': _cachedUserData?['profile']?['hostel'] ?? '',
        'college': _cachedUserData?['profile']['college'],
        'updatedAt': FieldValue.serverTimestamp(),
      } else ...{
        'sellerID': userID,
        'sellerName': _cachedUserData?['profile']?['name'] ?? '',
        'sellerHostel': _cachedUserData?['profile']?['hostel'] ?? '',
        'college': _cachedUserData?['profile']['college'],
        'updatedAt': FieldValue.serverTimestamp(),
      }
    };
  }

  Future<void> postFeedback(String message) async {
    final user = getCurrentUser();
    if (user == null) return;

    final feedbackData = {
      'userId': user.uid,
      'userEmail': user.email,
      'username': _cachedUserData!['profile']['name'] ?? "Anonymous",
      'message': message,
      'college': _cachedUserData!['profile']['college'],
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('Feedback').add(feedbackData);
  }

  void _updateCachedUserData(Map<String, dynamic> updatedData) {
    _cachedUserData = updatedData;
  }

  void resetCachedUserData() {
    _updateSubscription?.cancel();
    _cachedUserData = null;
  }
}
