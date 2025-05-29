import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/providers/active_ads_provider.dart';

class BookmarksProvider with ChangeNotifier {
  final List<Product> _userBookmarks = [];
  List<Product> _filteredBookmarks = [];

  List<Product> get userBookmarks => _filteredBookmarks.isEmpty ? _userBookmarks : _filteredBookmarks;

  Future<void> getBookmarks(BuildContext context) async {
    final userData = await UserDataService().fetchUserData();
    final String? bookmarksString = userData?['bookmarks'];
    if (bookmarksString == null || bookmarksString.isEmpty) {
      return;
    }
    final List<String> bookmarkItemIDs = bookmarksString.split('_');
    final List<Product> fetchedBookmarks = [];

    final activeAds = context.read<ActiveAdsProvider>().activeAds;

    // Add active ads
    final activeProducts = activeAds.where((ad) => bookmarkItemIDs.contains(ad.itemID)).toList();
    fetchedBookmarks.addAll(activeProducts);

    // Add inactive ads
    final inactiveBookmarkIDs = bookmarkItemIDs.where((itemID) => !activeAds.any((ad) => ad.itemID == itemID)).toList();
    final inactiveProducts = await _fetchInactiveAds(inactiveBookmarkIDs);
    fetchedBookmarks.addAll(inactiveProducts);
    fetchedBookmarks.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    _userBookmarks.clear();
    _userBookmarks.addAll(fetchedBookmarks);
    _filteredBookmarks.clear();
    notifyListeners();
  }

  Future<List<Product>> _fetchInactiveAds(List<String> itemIDs) async {
    final userBookmarksSnapshot = await UserDataService().fetchInactiveUserBookmarks();
    final List<Product> inactiveProducts = [];

    if (userBookmarksSnapshot != null) {
      for (var itemID in itemIDs) {
        final productDoc = userBookmarksSnapshot.docs.firstWhere(
          (doc) => doc.id == itemID,
        );
        inactiveProducts.add(Product.fromMap(productDoc.data() as Map<String, dynamic>, itemID));
      }
    }
    return inactiveProducts;
  }

  void toggleBookmark(Product bookmark) {
    if (_userBookmarks.contains(bookmark)) {
      _userBookmarks.remove(bookmark);
    } else {
      _userBookmarks.add(bookmark);
    }
    _filteredBookmarks.clear();
    notifyListeners();
  }

  Future<void> saveBookmarks() async {
    await UserDataService().saveBookmarks(_userBookmarks);
  }

  void setSearch(String query) {
    if (query.isEmpty) {
      _filteredBookmarks.clear();
    } else {
      _filteredBookmarks = _userBookmarks
          .where((bookmark) =>
              bookmark.itemName.toLowerCase().contains(query.toLowerCase()) ||
              bookmark.itemDescription.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void reset() {
    _userBookmarks.clear();
    _filteredBookmarks.clear();
    notifyListeners();
  }
}
