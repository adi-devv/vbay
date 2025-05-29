import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showUpdateRequired(BuildContext context, String updateText, bool updateRequired) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    barrierDismissible: !updateRequired,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.secondary,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: theme.brightness == Brightness.dark ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
        title: Text(
          textAlign: TextAlign.center,
          updateRequired ? "Update Required" : "Optional Update",
          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            textAlign: TextAlign.center,
            updateText,
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
        ),
        actions: [
          Center(
            child: InkWell(
              onTap: () {
                launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.adidevv.vbay"));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: Text(
                  "Update Now",
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
