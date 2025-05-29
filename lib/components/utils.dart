import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/models/product.dart';

class Utils {
  static String formatCurrency(int value) {
    final format = NumberFormat.currency(locale: 'en_US', symbol: '₹', decimalDigits: 0);
    return "${format.format(value)}/-";
  }

  String formatTimestamp(int ts) => DateTime.fromMillisecondsSinceEpoch(ts).toLocal().toString().substring(11, 16);

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }
  }

  static void showDialogBox({
    required BuildContext context,
    required String message,
    String confirmText = "Confirm",
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.only(top: 20),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: Theme.of(context).brightness == Brightness.dark
              ? BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MaterialButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Skip", style: TextStyle(fontSize: 15)),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(confirmText, style: TextStyle(fontSize: 15, color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void setStatusBarIconBrightness(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarIconBrightness: brightness),
    );
  }

  static void resetStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  static void showSnackBar(BuildContext context, String message, [bool isError = false]) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        backgroundColor: isError ? Colors.red.shade300 : null,
      ),
    );
  }

  static Widget buildEmptyIcon() {
    return IgnorePointer(
      child: IconButton(
        icon: const Icon(Icons.clear, size: 27, color: Colors.transparent),
        onPressed: () {},
      ),
    );
  }

  static OverlayEntry? _currentOverlayEntry;
  static bool _isShowing = false;

  static void showLoading(BuildContext context, {int? offset}) {
    if (_isShowing || _currentOverlayEntry != null) return;

    OverlayState? overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) return;

    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height / 2 + (offset ?? 0) - 100,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: Lottie.asset(
                'assets/loading.json',
                width: 200,
                height: 200,
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(overlayEntry);
    _currentOverlayEntry = overlayEntry;
    _isShowing = true;
  }

  static void hideLoading() {
    if (_currentOverlayEntry == null) return;

    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
    _isShowing = false;
  }

  static void showProductPopup(BuildContext context, Product? item, {bool? isCreator = false}) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  item != null
                      ? ExploreTile(product: item, isCreator: isCreator)
                      : Text(
                          "Ad is inactive",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey.shade800,
                          ),
                        ),
                  if (item?.status != 'Active')
                    Text(
                      textAlign: TextAlign.center,
                      "Uh-oh!\nThis item is unavailable.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
