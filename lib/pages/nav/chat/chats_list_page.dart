import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/pages/view/view_profile_page.dart';
import 'package:vbay/services/data/chat_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'chat_page.dart';

class ChatsListPage extends StatelessWidget {
  ChatsListPage({super.key});

  final _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        children: [
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Chats",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _combineUserAndMessageStreams(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error loading chats'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wechat_sharp,
                color: Colors.grey,
                size: 80,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Your chats will appear here!",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ));
        }

        var sortedUsers = List<Map<String, dynamic>>.from(snapshot.data!);
        sortedUsers.sort((a, b) {
          var aTimestamp = a['timestamp'] ?? DateTime.fromMillisecondsSinceEpoch(0);
          var bTimestamp = b['timestamp'] ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTimestamp.compareTo(aTimestamp);
        });

        return ListView(
          children: sortedUsers.map((userData) => _buildUserListItem(context, userData)).toList(),
        );
      },
    );
  }
  Stream<List<Map<String, dynamic>>> _combineUserAndMessageStreams() {
    return _chatService.getUsersStream().asyncMap((users) async {
      try {
        if (users.isEmpty) return Stream.value(<Map<String, dynamic>>[]);

        List<Stream<Map<String, dynamic>>> userStreams = users.map((user) {
          Stream<QuerySnapshot<Object?>> msgStream = _chatService.getLatest(user['uid']).asBroadcastStream();

          return msgStream.map((querySnapshot) {
            var docs = querySnapshot.docs;
            int unreadCount = docs.where((d) {
              var data = d.data() as Map<String, dynamic>;
              return data['unread'] == true && data['senderID'] != UserDataService.getCurrentUser()!.uid;
            }).length;

            return {
              ...user,
              'latestMessage': docs.isNotEmpty ? docs.last.data() : null,
              'unreadCount': unreadCount,
              'msgStream': msgStream,
              'earlierMsgs': docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                data['msgID'] = doc.id;
                return data;
              }).toList(),
            };
          });
        }).toList();

        return Rx.combineLatest(userStreams, (data) {
          List<Map<String, dynamic>> mutableData = List.from(data);

          mutableData.sort((a, b) {
            var timestampA = a['latestMessage']?['timestamp'] ?? 0;
            var timestampB = b['latestMessage']?['timestamp'] ?? 0;
            return timestampB.compareTo(timestampA);
          });

          bool hasUnread = mutableData.any((userData) => userData['unreadCount'] != 0);
          BottomNavbarKey.instance.key.currentState?.toggleUnread(hasUnread);

          return mutableData;
        });
      } catch (e) {
        print('Error occurred while processing the streams: $e');
        return Stream.value(<Map<String, dynamic>>[]); // Return an empty list on error
      }
    }).switchMap((stream) => stream);
  }

  String formatTimestamp(int ts) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(ts).toLocal();
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));

    if (DateFormat('yMd').format(time) == DateFormat('yMd').format(now)) {
      return DateFormat.Hm().format(time);
    } else if (DateFormat('yMd').format(time) == DateFormat('yMd').format(yesterday)) {
      return "Yesterday";
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.EEEE().format(time);
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }

  Widget _buildUserListItem(BuildContext context, Map<String, dynamic> userData) {
    var senderID = userData['latestMessage']?['senderID'] ?? '';
    var timestamp = userData['latestMessage']?['timestamp'];
    var timeStr = timestamp != null ? formatTimestamp(timestamp) : '';
    var unreadCount = userData['unreadCount'] ?? 0;

    return ListTile(
      leading: GestureDetector(
        onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ViewProfilePage(profileID: userData['uid'])),
    ),child: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: ClipOval(
            child: userData['profile']['avatarUrl'] != null
                ? CachedNetworkImage(
                    imageUrl: userData['profile']['avatarUrl']!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Transform.translate(
                      offset: Offset(0, 7),
                      child: Icon(
                        CupertinoIcons.person_alt,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  )
                : Transform.translate(
                    offset: Offset(0, 7),
                    child: Icon(
                      CupertinoIcons.person_alt,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
          )),),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            userData['profile']['name'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: [
              Text(
                timeStr,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (senderID == UserDataService.getCurrentUser()!.uid)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.done_all,
                        size: 20,
                        color: userData['latestMessage']['unread'] == false ? Colors.blueAccent : Colors.grey),
                  ),
                Expanded(
                  child: Text(
                    userData['latestMessage']?['message'] ?? '',
                    style: TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          if (unreadCount > 0)
              Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Color(0xFF00C1A2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14),
                    ),
                  ),
                )
              ],
      ),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(receiverData: userData),
          )),
    );
  }
}
