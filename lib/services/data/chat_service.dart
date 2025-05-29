import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vbay/services/data/notification_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:rxdart/rxdart.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() => _instance;

  ChatService._internal();

  final _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    String currentUserUid = UserDataService.getCurrentUser()!.uid;

    return _firestore
        .collection('Users')
        .doc(currentUserUid)
        .collection('chattedWith')
        .snapshots()
        .switchMap((subCollectionSnapshot) {
      try {
        List<String> chattedWithIDs = subCollectionSnapshot.docs
            .where((doc) => !(doc.data()['endedConversation'] ?? false))
            .map((doc) => doc.id)
            .toList();

        print("Updated chattedWith: $chattedWithIDs");

        if (chattedWithIDs.isEmpty) {
          return Stream.value(<Map<String, dynamic>>[]);
        }

        return _firestore
            .collection('Users')
            .where(FieldPath.documentId, whereIn: chattedWithIDs)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
      } catch (e) {
        print('Error occurred while processing the users stream: $e');
        return Stream.value(<Map<String, dynamic>>[]); // Return an empty list on error
      }
    });
  }

  Future<void> updateChattedWithLists(String sellerID) async {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    final currentUserRef = _firestore.collection('Users').doc(currentUserID);
    final sellerRef = _firestore.collection('Users').doc(sellerID);

    try {
      final docs = await Future.wait([currentUserRef.get(), sellerRef.get()]);

      final currentUserData = docs[0].data();
      final sellerData = docs[1].data();

      if (currentUserData == null || sellerData == null) return;

      final batch = _firestore.batch();
      batch.set(currentUserRef.collection('chattedWith').doc(sellerID), {
        'timestamp': FieldValue.serverTimestamp(),
        'endedConversation': false,
      });

      batch.set(sellerRef.collection('chattedWith').doc(currentUserID), {
        'timestamp': FieldValue.serverTimestamp(),
        'endedConversation': false,
      });

      List<String> ids = [currentUserID, sellerID]..sort();
      String chatRoomID = ids.join('_');

      final chatRoomRef = _firestore.collection('ChatRooms').doc(chatRoomID);

      final chatRoomDoc = await chatRoomRef.get();
      if (!chatRoomDoc.exists) {
        batch.set(chatRoomRef, {
          'u0': currentUserData['profile']['name'],
          'u1': sellerData['profile']['name'],
          'u0ID': currentUserID,
          'u1ID': sellerID,
          'u0Email': currentUserData['email'],
          'u1Email': sellerData['email'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print("Erroraaaaaaaa: $e");
      rethrow;
    }
  }

  Future<void> checkChatRoom(String receiverID) async {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    List<String> ids = [receiverID, currentUserID]..sort();
    String chatRoomID = ids.join('_');

    final chatRoomDoc = await _firestore.collection('ChatRooms').doc(chatRoomID).get();

    if (chatRoomDoc.exists) {
      DocumentReference currentUserChatRef =
          _firestore.collection('Users').doc(currentUserID).collection('chattedWith').doc(receiverID);

      DocumentReference receiverChatRef =
          _firestore.collection('Users').doc(receiverID).collection('chattedWith').doc(currentUserID);

      final currentUserChatDoc = await currentUserChatRef.get();

      if (currentUserChatDoc.exists && (currentUserChatDoc['endedConversation'] ?? false)) {
        WriteBatch batch = _firestore.batch();
        batch.update(currentUserChatRef, {'endedConversation': false});
        batch.update(receiverChatRef, {'endedConversation': false});
        await batch.commit();
      }
    } else {
      ChatService().updateChattedWithLists(receiverID);
    }
  }

  Stream<QuerySnapshot> getLatest(String receiverID) {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    List<String> ids = [receiverID, currentUserID]..sort();
    String chatRoomID = ids.join('_');

    Query messagesQuery = _firestore
        .collection('ChatRooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return messagesQuery.snapshots().asBroadcastStream();
  }

  Stream<QuerySnapshot> getMessages(String receiverID) {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    List<String> ids = [receiverID, currentUserID]..sort();
    String chatRoomID = ids.join('_');

    var stream = FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return stream;
  }

  void markAsRead(dynamic messages, {String? receiverID}) {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Get ChatRoomID (if receiverID is provided)
    String? chatRoomID;
    if (receiverID != null) {
      List<String> sortedIDs = [currentUserID, receiverID]..sort();
      chatRoomID = sortedIDs.join("_");
    }

    if (messages is QuerySnapshot) {
      for (var doc in messages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['unread'] == true && data['senderID'] != currentUserID) {
          batch.update(doc.reference, {'unread': false});
        }
      }
    } else if (messages is List<Map<String, dynamic>>) {
      for (var msg in messages) {
        if (msg['unread'] == true && msg['senderID'] != currentUserID && msg.containsKey('msgID')) {
          try {
            if (chatRoomID == null) {
              print('Skipping message, missing receiverID for chatRoomID');
              continue;
            }

            DocumentReference docRef = FirebaseFirestore.instance
                .collection('ChatRooms')
                .doc(chatRoomID)
                .collection('messages')
                .doc(msg['msgID']);

            batch.update(docRef, {'unread': false});
          } catch (e) {
            print('Skipping invalid msgID: ${msg['msgID']} - Error: $e');
          }
        }
      }
    }

    batch.commit().catchError((error) {
      print('Batch update failed: $error');
    });
  }

  Future<void> sendMessage(String receiverID, String message, {String? replyToID, String? replyAdID}) async {
    try {
      final String currentUserID = UserDataService.getCurrentUser()!.uid;
      List<String> ids = [currentUserID, receiverID];

      if (replyToID != null && replyAdID != null) {
        print('Found both replyAd & replyMsg!!');
        return;
      }
      if (currentUserID == receiverID) {
        return;
      }

      ids.sort();
      String chatRoomID = ids.join('_');

      final messageData = {
        'senderID': currentUserID,
        'receiverID': receiverID,
        'message': message,
        'unread': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (replyToID != null) {
        messageData['replyToID'] = replyToID;
      } else if (replyAdID != null) {
        messageData['replyAdID'] = replyAdID;
      }

      await _firestore.collection('ChatRooms').doc(chatRoomID).collection('messages').add(messageData);

      final userProfile = await UserDataService().fetchUserData(receiverID);

      final currentUserProfile = await UserDataService().fetchUserProfile();
      final senderName = currentUserProfile?['name']?.toString().split(' ')[0] ?? 'Someone';

      NotificationService().sendNotification(
        userProfile!['fcmToken'],
        '$senderName sent you a chat',
        'Tap to reply',
        msgData: {
          'type': 'chat',
          'msg': message,
          'name': currentUserProfile!['name'],
          'senderID': currentUserID,
          'receiverID': receiverID,
          'avatarUrl': currentUserProfile['avatarUrl'],
        },
      );
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      throw Exception('Failed to send message due to a Firestore error.');
    } on Exception catch (e) {
      print('Error: ${e.toString()}');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> endConversation(String receiverID) async {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    List<String> ids = [receiverID, currentUserID]..sort();
    String chatRoomID = ids.join('_');

    final chatRoomRef = _firestore.collection('ChatRooms').doc(chatRoomID);
    final messagesRef = chatRoomRef.collection('messages');
    final currentUserRef = _firestore.collection('Users').doc(currentUserID).collection('chattedWith').doc(receiverID);
    final otherUserRef = _firestore.collection('Users').doc(receiverID).collection('chattedWith').doc(currentUserID);

    try {
      final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
      final messagesSnapshot = await messagesRef.get();

      final batch = _firestore.batch();
      final archivedChatRef = chatRoomRef.collection('ArchivedChats').doc(dateStr);

      final List<Map<String, dynamic>> filteredMessages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        data.remove('unread');
        data.remove('timestamp');
        data.remove('receiverID');
        return data;
      }).toList();

      batch.update(currentUserRef, {'endedConversation': true});
      batch.update(otherUserRef, {'endedConversation': true});
      batch.set(
          archivedChatRef,
          {
            'chat': FieldValue.arrayUnion(filteredMessages),
          },
          SetOptions(merge: true));

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print("Error ending conversation: $e");
      rethrow;
    }
  }
}
