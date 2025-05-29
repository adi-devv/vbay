import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/services/data/user_data_service.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareToInstagramStory {
  static const platform = MethodChannel('com.example.share_to_instagram');

  // Function to check if Instagram is installed
  static Future<bool> isInstagramInstalled() async {
    const instagramUrl = 'instagram://';
    const fallbackUrl = 'https://www.instagram.com';
    try {
      bool isAvailable = await canLaunchUrl(Uri.parse(instagramUrl));

      if (!isAvailable) {
        isAvailable = await canLaunchUrl(Uri.parse(fallbackUrl));
      }

      return isAvailable;
    } catch (e) {
      print('Error checking if Instagram is installed: $e');
      return false;
    }
  }

  // Function to share the image to Instagram story
  static Future<void> shareInstagramStory(String imagePath) async {
    try {
      // Check if Instagram is installed
      final isInstalled = await isInstagramInstalled();
      if (isInstalled) {
        if (Platform.isAndroid) {
          await platform.invokeMethod('shareInstagramStory', {'imagePath': imagePath});
        }
      } else {
        print('Instagram is not installed');
        // Optionally, open the Play Store or App Store for the user to install Instagram
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.instagram.android';
        await launch(playStoreUrl);
      }
    } on PlatformException catch (e) {
      print("Failed to share Instagram story: '${e.message}'");
    }
  }
}

class LinkkService {
  static final LinkkService _instance = LinkkService._internal();

  factory LinkkService() => _instance;

  LinkkService._internal();

  static Uri? pendingLink;

  static Future<String> createDynamicLink(Product item) async {
    try {
      final deepLink = Uri.parse(
          'https://vbay.page.link/?link=https://vbay.page.link/product/${item.itemID}/${Uri.encodeComponent(item.itemName.replaceAll(RegExp(r'[^\w\s-]'), ''))}&ofl=https://sites.google.com/view/vbay');
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://vbay.page.link',
        link: deepLink,
        androidParameters: AndroidParameters(
          packageName: 'com.adidevv.vbay',
        ),
        iosParameters: IOSParameters(
          bundleId: 'com.adidevv.vbay',
          fallbackUrl: Uri.parse('https://sites.google.com/view/vbay'),
        ),
        navigationInfoParameters: const NavigationInfoParameters(
          forcedRedirectEnabled: true,
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: '${item.itemName} - Available on VBay!',
          description: item.itemDescription,
          imageUrl: item.imagePath.startsWith('http') ? Uri.parse(item.imagePath) : null,
        ),
      );

      final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
        parameters,
        shortLinkType: ShortDynamicLinkType.short,
      );

      return shortLink.shortUrl.toString();
    } catch (e, stackTrace) {
      debugPrint('🔥 Error creating dynamic link: $e');
      debugPrint('🪵 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Uri? lastLink;

  static String? extractItemIDFromDynamicLink(Uri dynamicLink) {
    final innerLink = Uri.tryParse(dynamicLink.queryParameters['link'] ?? '');
    if (innerLink == null || innerLink.pathSegments.length < 2) return null;
    print(innerLink.pathSegments[1]);
    return innerLink.pathSegments[1];
  }

  static void handleDynamicLinks({bool isPending = false}) async {
    if (isPending) {
      if (pendingLink != null) {
        if (pendingLink == lastLink) return;
        print("Processing pending link: $pendingLink");
        lastLink = pendingLink;
        Future.delayed(Duration(seconds: 5), () => lastLink = null);

        final itemID = extractItemIDFromDynamicLink(pendingLink!);
        if (itemID != null) {
          await _fetchAndShowProduct(itemID);
        } else {
          await _fetchAndShowProduct(pendingLink!.pathSegments[1]);
        }
        pendingLink = null;
      }
      return;
    }

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      Uri deepLink = dynamicLinkData.link;

      if (deepLink == lastLink) return;
      lastLink = deepLink;

      if (UserDataService.getCurrentUser() == null) {
        print("Link moved to pending");
        pendingLink = deepLink;
      } else {
        print("Received deep link: $deepLink");
        Future.delayed(Duration(seconds: 5), () => lastLink = null);

        final itemID = extractItemIDFromDynamicLink(deepLink);
        if (itemID != null) {
          await _fetchAndShowProduct(itemID);
        } else {
          await _fetchAndShowProduct(deepLink.pathSegments[1]);
        }
      }
    });

    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data?.link != null) {
      if (data!.link == lastLink) return;
      lastLink = data.link;
      Future.delayed(Duration(seconds: 5), () => lastLink = null);
      final itemID = extractItemIDFromDynamicLink(data.link);
      if (itemID != null) {
        await _fetchAndShowProduct(itemID);
      } else {
        await _fetchAndShowProduct(data.link.pathSegments[1]);
      }
    }
  }

  static void handlePendingLink() {
    if (pendingLink != null) {
      handleDynamicLinks(isPending: true);
    }
  }

  static Future<void> _fetchAndShowProduct(String itemID) async {
    Product? item = await UserDataService().fetchAd(itemID);
    if (navigatorKey.currentContext == null) return;

    if (item != null) {
      item.status = 'Active';
      Utils.showProductPopup(navigatorKey.currentContext!, item);
    } else {
      print("Ad from deeplink is inactive!");
      final theme = Theme.of(navigatorKey.currentContext!);

      showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: theme.brightness == Brightness.dark
                    ? BorderSide(
                        color: Colors.white,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              title: Text(
                textAlign: TextAlign.center,
                "Oops!\nThis item is unavailable!",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          });
    }
  }
}
