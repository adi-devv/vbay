import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/my_logo.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/components/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vbay/pages/nav/chat/chat_page.dart';
import 'package:vbay/pages/view/view_profile_page.dart';
import 'package:vbay/providers/bookmarks_provider.dart';
import 'package:vbay/services/data/creator_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:share_plus/share_plus.dart';

class ExploreTile extends StatefulWidget {
  final Product product;
  final bool? isCreator;

  const ExploreTile({
    super.key,
    required this.product,
    this.isCreator,
  });

  @override
  State<ExploreTile> createState() => _ExploreTileState();
}

class _ExploreTileState extends State<ExploreTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          // Pastel pink-orange
          if ((widget.product.quantity ?? 5) > 1 && (widget.product.quantity ?? 5) < 5)
            Positioned(
              bottom: 7,
              left: 48,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFAB91),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hurry! Only ${widget.product.quantity} left!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Container(
            margin: EdgeInsets.only(top: 16, bottom: 30, left: 8, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                  blurRadius: Theme.of(context).brightness == Brightness.light ? 15 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageSection(context),
                _buildDetailsSection(context),
                _buildActionsSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image widget (unchanged)
                widget.product.imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: widget.product.imagePath,
                        placeholder: (context, url) => Opacity(
                          opacity: 0.3,
                          child: Image.asset('assets/default.png'),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Error loading image from Network: $error');
                          return Opacity(
                            opacity: 0.3,
                            child: Image.asset('assets/default.png'),
                          );
                        },
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        widget.product.imagePath,
                        errorBuilder: (context, assetError, assetStackTrace) {
                          debugPrint('Error loading image from Asset: ${assetError.toString()}');
                          return Image(
                            image: FileImage(File(widget.product.imagePath)),
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image from File: ${error.toString()}');
                              return Opacity(
                                opacity: 0.3,
                                child: Image.asset('assets/default.png'),
                              );
                            },
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                // Sold Overlay (conditionally shown)
                if (widget.product.status == 'Sold')
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "SOLD",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .5),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Consumer<BookmarksProvider>(
                builder: (context, bookmarksProvider, child) {
                  bool isBookmarked =
                      bookmarksProvider.userBookmarks.any((bookmark) => bookmark.itemID == widget.product.itemID);

                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      size: 25,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (widget.product.sellerID != null &&
                          widget.product.sellerID != UserDataService.getCurrentUser()!.uid) {
                        if (widget.product.status == 'Active') {
                          bookmarksProvider.toggleBookmark(widget.product);
                          Utils.showSnackBar(
                            context,
                            isBookmarked ? 'Removed from bookmarks!' : 'Added to bookmarks!',
                          );
                        } else {
                          Utils.showSnackBar(context, 'Ad Inactive!');
                        }
                      } else {
                        Utils.showSnackBar(context, 'Ad posted by you!');
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.isCreator == true)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
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
                        CreatorService().makeAdPending(widget.product);
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
                    icon: Icon(Icons.more_vert, color: Colors.white),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.itemName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.itemDescription,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _buildMetadataRow(context),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 12,
            ),
            constraints: BoxConstraints(
              minWidth: 80,
              maxWidth: 110,
            ),
            child: Column(children: [
              Text(
                widget.product.condition,
                style: TextStyle(
                  color: widget.product.condition == "Fresh" ? Colors.lightGreen : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.product.category,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 14),
                textAlign: TextAlign.center,
              ),
              widget.product.quantity != null && (widget.product.quantity ?? 1) > 4
                  ? Text(
                      'Qty: ${widget.product.quantity.toString()}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          fontSize: 13),
                      textAlign: TextAlign.center,
                    )
                  : SizedBox()
            ])),
        GestureDetector(
          onTap: () {
            if (widget.product.sellerID != null && widget.product.sellerID != UserDataService.getCurrentUser()!.uid) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewProfilePage(profileID: widget.product.sellerID!)),
              );
            }
          },
          child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 100,
                maxWidth: 120,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 12,
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Seller:\n",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    TextSpan(
                      text: "${widget.product.sellerName.toString().split(' ')[0]}\n",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: widget.product.sellerHostel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              Utils.formatCurrency(widget.product.price),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.only(top: 19, bottom: 16, right: 8, left: 8),
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  if (widget.product.status == 'Sold') {
                    Utils.showSnackBar(context, 'This item has been sold!');
                  } else if (widget.product.sellerID != null &&
                      widget.product.sellerID != UserDataService.getCurrentUser()!.uid) {
                    var receiverData = await UserDataService().fetchUserData(widget.product.sellerID!);
                    if (receiverData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverData: receiverData,
                            product: widget.product,
                            chatText: "Hi, I'm interested in buying this item. Is it still available?",
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
                },
                icon: const Icon(Icons.chat),
                iconSize: 28,
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
              IconButton(
                padding: EdgeInsets.only(top: 16, bottom: 16, right: 12, left: 8),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  if (widget.product.status == 'Sold') {
                    Utils.showSnackBar(context, 'This item has been sold!');
                    return;
                  } else if (widget.product.status != 'Active') {
                    Utils.showSnackBar(context, 'Ad not active yet');
                    return;
                  }
                  _showShareModal(context, widget.product);
                },
                icon: Icon(CupertinoIcons.paperplane_fill),
                iconSize: 28,
                color: Color(0xFF00C1A2),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showShareModal(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Share", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade700.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    padding: EdgeInsets.only(left: 13, right: 13, top: 13, bottom: 8),
                    width: 240,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: AssetImage('assets/default.png'),
                        opacity: .1,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: widget.product.imagePath,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Opacity(
                                opacity: 0.3,
                                child: Image.asset('assets/default.png'),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.itemName,
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            SizedBox(height: 2),
                            Text(
                              product.itemDescription,
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(width: 4),
                                MyLogo(fontSize: 18, bold: true),
                                Spacer(),
                                Transform.translate(
                                  offset: Offset(0, 2),
                                  child: Text(
                                    Utils.formatCurrency(product.price),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _shareInstagramStory(context, product),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage('assets/insta.png'),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text("Stories", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(width: 16),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => Share.share(
                            'VBay - Your Campus Marketplace! Swipe, Buy & Sell!\n\nCheck out this item: ${product.itemName}\nHostel: ${product.sellerHostel}\n\n${product.itemURL!}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: .2),
                                blurRadius: 5,
                                offset: const Offset(2, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.transparent,
                            child: Icon(
                              CupertinoIcons.paperplane_fill,
                              color: Color(0xFF00C1A2),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text("Share", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  final GlobalKey _globalKey = GlobalKey();

  Future<void> _shareInstagramStory(BuildContext context, Product product) async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      _shareImage(pngBytes, product.itemURL!);
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  final List<List<String>> _colorCombinations = [
    // White as one of the colors
    ["#FFFFFF", "#00D2FF"], // White & Blue
    ["#FFFFFF", "#FF5733"], // White & Red-Orange
    ["#FFFFFF", "#FFD700"], // White & Gold
    ["#FFFFFF", "#33FF57"], // White & Bright Green
    ["#FFFFFF", "#3357FF"], // White & Blue
    ["#FFFFFF", "#FF33A8"], // White & Pink
    ["#FFFFFF", "#FFBD33"], // White & Yellow-Orange
    ["#FFFFFF", "#8D33FF"], // White & Purple
    ["#FFFFFF", "#FF4500"], // White & Orange-Red
    ["#FFFFFF", "#33FFBD"], // White & Cyan-Green

    // Original combinations
    ["#FF5733", "#FFD700"], // Red-Orange & Gold
    ["#33FF57", "#3357FF"], // Green & Blue
    ["#FF33A8", "#FFBD33"], // Pink & Yellow-Orange
    ["#00D2FF", "#8D33FF"], // Cyan-Blue & Purple
    ["#FFD700", "#33FF57"], // Gold & Bright Green
    ["#8D33FF", "#FF5733"], // Purple & Red-Orange
    ["#33FFBD", "#3357FF"], // Cyan-Green & Blue

    // Reversed versions
    ["#FFD700", "#FF5733"], // Gold & Red-Orange
    ["#3357FF", "#33FF57"], // Blue & Green
    ["#FFBD33", "#FF33A8"], // Yellow-Orange & Pink
    ["#8D33FF", "#00D2FF"], // Purple & Cyan-Blue
    ["#33FF57", "#FFD700"], // Bright Green & Gold
    ["#FF5733", "#8D33FF"], // Red-Orange & Purple
    ["#3357FF", "#33FFBD"], // Blue & Cyan-Green
  ];

  List<String> _randomColorCombination() {
    final Random random = Random();
    final shuffledCombinations = List.of(_colorCombinations)..shuffle(random);
    return shuffledCombinations[random.nextInt(shuffledCombinations.length)];
  }

  Future<void> _shareImage(Uint8List pngBytes, String linkUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final stickerFile = File('${tempDir.path}/share_tile.png');
      await stickerFile.writeAsBytes(pngBytes);

      const platform = MethodChannel("com.example.share_to_instagram");
      testWhiteSelection();
      final colors = _randomColorCombination();
      print('Combination: $colors');
      await platform.invokeMethod("shareInstagramStory", {
        "stickerPath": stickerFile.path,
        "linkUrl": linkUrl,
        "topBackgroundColor": colors[0],
        "bottomBackgroundColor": colors[1],
      });
    } catch (e) {
      debugPrint("Error sharing image: $e");
    }
  }

  void testWhiteSelection() {
    int whiteCount = 0, total = 1000;
    for (int i = 0; i < total; i++) {
      List<String> combo = _randomColorCombination();
      if (combo.contains("#FFFFFF")) {
        whiteCount++;
      }
    }
    print("White selected ${whiteCount / total * 100}% of the time");
  }
}
