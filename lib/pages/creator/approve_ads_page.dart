import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/services/data/creator_service.dart';
import 'package:vbay/components/utils.dart';

class ApproveAdsPage extends StatefulWidget {
  const ApproveAdsPage({super.key});

  @override
  State<ApproveAdsPage> createState() => _ApproveAdsPageState();
}

class _ApproveAdsPageState extends State<ApproveAdsPage> {
  late final PageController _pageController;
  bool _isPageViewBuilt = false;
  List<Product> products = [];
  Map<String, Map<String, dynamic>> rawPendingAdData = {};
  final CreatorService _approvalService = CreatorService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
    fetchPendingAds();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingAds() async {
    final fetchedList = await _approvalService.fetchPendingAds();
    if (mounted) {
      setState(() {
        rawPendingAdData = fetchedList[0];
        products = fetchedList[1];
      });
    }
  }

  void _showRejectionPopup(String itemID, String sellerID) {
    List<String> reasons = [
      'Poor Product',
      'Incorrect Pricing',
      'Inappropriate Content',
      'Low-Quality Image',
      'Misleading',
      'Detected Spam',
      'Promotional Material',
      'Restricted Product',
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
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      await _approvalService.rejectAd(itemID, sellerID, selectedReasons);
                      setState(() {
                        products.removeWhere((product) => product.itemID == itemID);
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
      body: products.isEmpty
          ? const Center(
              child: Text(
                'All done for today!',
                style: TextStyle(fontSize: 20),
              ),
            )
          : Column(
              children: [
                SizedBox(height: 20),
                Flexible(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isPageViewBuilt = true;
                            });
                          }
                        });
                      }
                      final product = products[index];
                      final itemID = product.itemID;

                      return Column(
                        children: [
                          _buildProductTile(product, index),
                          Text(
                            product.college!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          product.reasons != null
                              ? Text(
                                  'Ad Rejected Earlier',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                )
                              : SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.question_square_fill,
                                  size: 72,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  if (itemID != null && rawPendingAdData.containsKey(itemID)) {
                                    _showRejectionPopup(itemID, rawPendingAdData[itemID]!['sellerID']);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.checkmark_square_fill,
                                  size: 72,
                                  color: Colors.lightGreen.shade400,
                                ),
                                onPressed: () async {
                                  if (itemID != null && rawPendingAdData.containsKey(itemID) && mounted) {
                                    final dataToMove = rawPendingAdData[itemID]!;
                                    await _approvalService.approveAd(itemID, dataToMove);
                                    setState(() {
                                      products.removeAt(index);
                                    });
                                  }
                                },
                              )
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 40)
              ],
            ),
    );
  }

  Widget _buildProductTile(Product product, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double page = _isPageViewBuilt ? _pageController.page ?? index.toDouble() : index.toDouble();
        double scale = (1 - (index - page).abs() * 0.3).clamp(0.9, 1.0);
        double opacity = (1 - (index - page).abs() * 0.5).clamp(0.9, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: ExploreTile(product: product),
          ),
        );
      },
    );
  }
}
