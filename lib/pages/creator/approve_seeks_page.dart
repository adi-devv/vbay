import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/services/data/creator_service.dart';

class ApproveSeeksPage extends StatefulWidget {
  const ApproveSeeksPage({super.key});

  @override
  State<ApproveSeeksPage> createState() => _ApproveSeeksPageState();
}

class _ApproveSeeksPageState extends State<ApproveSeeksPage> {
  List<Seek> seeks = [];
  Map<String, Map<String, dynamic>> rawPendingSeekData = {};
  final CreatorService _approvalService = CreatorService();

  @override
  void initState() {
    super.initState();
    fetchPendingSeeks();
  }

  Future<void> fetchPendingSeeks() async {
    final fetchedList = await _approvalService.fetchPendingSeeks();
    if (mounted) {
      setState(() {
        rawPendingSeekData = fetchedList[0];
        seeks = fetchedList[1];
      });
    }
  }

  void _showRejectionPopup(String itemID, String sellerID) {
    List<String> reasons = [
      'Inappropriate Content',
      'Detected Spam',
      'Promotional Material',
      'Restricted Product',
      'Be More Specific',
    ];

    List<String> selectedReasons = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Select Reasons',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reasons.map((reason) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      bool isSelected = selectedReasons.contains(reason);

                      return GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              if (isSelected) {
                                selectedReasons.remove(reason);
                              } else {
                                selectedReasons.add(reason);
                              }
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                if (mounted) {
                                  setState(() {
                                    if (value != null && value) {
                                      selectedReasons.add(reason);
                                    } else {
                                      selectedReasons.remove(reason);
                                    }
                                  });
                                }
                              },
                              side: BorderSide(color: Colors.blueGrey.shade300, width: 2),
                            ),
                            Text(reason, style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _approvalService.rejectSeek(itemID, sellerID, selectedReasons);
                    if (mounted) {
                      setState(() {
                        seeks.removeWhere((seek) => seek.itemID == itemID);
                      });
                    }
                  },
                  child: Text('Reject', style: TextStyle(color: Colors.red, fontSize: 18)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: seeks.isEmpty
          ? const Center(
              child: Text(
                'All done for today!',
                style: TextStyle(fontSize: 20),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: seeks.length,
                itemBuilder: (context, index) {
                  return _buildSeekTile(seeks[index]);
                },
              ),
            ),
    );
  }

  Widget _buildSeekTile(Seek seek) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${seek.seekerName.toString().split(' ')[0]} is seeking...',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seek.itemName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'College: ${seek.college}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hostel: ${seek.seekerHostel}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted ${Utils.timeAgo(seek.updatedAt)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.question_square_fill,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      onPressed: () {
                        _showRejectionPopup(seek.itemID, seek.seekerID!);
                      },
                    ),
                    IconButton(
                        icon: Icon(
                          CupertinoIcons.checkmark_square_fill,
                          color: Colors.lightGreen.shade400,
                          size: 50,
                        ),
                        onPressed: () async {
                          final dataToMove = rawPendingSeekData[seek.itemID]!;
                          await _approvalService.approveSeek(seek.itemID, dataToMove);
                          if (mounted) {
                            setState(() {
                              seeks.removeWhere((obj) => obj.itemID == seek.itemID);
                            });
                          }
                        }),
                  ],
                )
              ],
            ),
          ),
          if (seek.reasons != null)
            Positioned(
              bottom: 4,
              right: 80,
              child: Text(
                'Rejected Earlier',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (seek.isUrgent)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: const BorderRadius.only(
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
        ],
      ),
    );
  }
}
