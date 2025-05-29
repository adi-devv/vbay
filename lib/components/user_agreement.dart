import 'package:flutter/material.dart';

void showUserAgreement(BuildContext context, {bool toAccept = false, VoidCallback? onAccept}) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    barrierDismissible: !toAccept,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.secondary,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: theme.brightness == Brightness.dark
              ? BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            textAlign: TextAlign.center,
            "User Agreement",
            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 15,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text:
                  "VBay is a free platform that connects buyers and sellers in the college community but does not facilitate payments, guarantee transactions, or take responsibility for any disputes.\n\n",
                ),
                TextSpan(
                  text: "Note:\n",
                  style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                ),
                TextSpan(
                  text:
                  "Any amount charged above MRP is a seller-set convenience fee for product availability or delivery.",
                ),
              ],
            ),
          ),
        ),

        actions: [
          if (toAccept)
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onAccept?.call();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  child: Text(
                    "Accept",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            )
        ],
      );
    },
  );
}
