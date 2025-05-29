import 'package:flutter/material.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/pages/nav/chat/chat_page.dart';
import 'package:vbay/pages/view/view_profile_page.dart';
import 'package:vbay/services/data/creator_service.dart';
import 'package:vbay/services/data/user_data_service.dart';

class SeekTile extends StatelessWidget {
  final Seek seek;
  final bool isAnotherProfile;
  final bool? isCreator;

  const SeekTile({
    super.key,
    required this.seek,
    this.isAnotherProfile = false,
    this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (seek.seekerID != null && seek.seekerID != UserDataService.getCurrentUser()!.uid && !isAnotherProfile) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewProfilePage(profileID: seek.seekerID!, index: 1)),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${seek.seekerName.toString().split(' ')[0]} is seeking...',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onInverseSurface),
                        ),
                        SizedBox(height: 4),
                        Text(
                          seek.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hostel: ${seek.seekerHostel}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Posted ${Utils.timeAgo(seek.updatedAt)}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onInverseSurface),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.back_hand_outlined,
                            color: Color(0xFF4DB6AC),
                            size: 25,
                          ),
                          onPressed: () async {
                            if (seek.seekerID != null && seek.seekerID != UserDataService.getCurrentUser()!.uid) {
                              var receiverData = await UserDataService().fetchUserData(seek.seekerID!);
                              if (receiverData != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      receiverData: receiverData,
                                      chatText: 'Hey, I have the ${seek.itemName} you’re looking for!',
                                    ),
                                  ),
                                );
                              } else {
                                debugPrint('Failed to load receiver profile.');
                                Utils.showSnackBar(context, 'Unknown error. Please try again');
                              }
                            } else {
                              Utils.showSnackBar(context, 'Ad posted by you!');
                            }
                          }),
                    ],
                  )
                ],
              ),
            ),
            if (seek.isUrgent)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ),
            if (isCreator == true)
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 43,
                  height: 43,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'hide') {
                          CreatorService().makeAdPending(seek);
                        }
                      },
                      offset: Offset(0, 40),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Mark Pending',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
