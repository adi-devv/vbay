import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/providers/bookmarks_provider.dart';
import 'package:vbay/services/data/user_data_service.dart';

class ActiveAdsProvider with ChangeNotifier {
  // Private fields
  List<Product> _activeAds = [];
  List<Product> _visibleAds = [];
  List<Product> _filteredAds = [];
  Map<String, dynamic> _selectedFilters = {};
  String _selectedSortOption = '';
  String _searchQuery = '';

  // Public getters
  List<Product> get activeAds => List.unmodifiable(_activeAds);

  List<Product> get visibleAds => List.unmodifiable(_visibleAds);

  Map<String, dynamic> get selectedFilters => Map.unmodifiable(_selectedFilters);

  String get selectedSortOption => _selectedSortOption;

  String get searchQuery => _searchQuery;

  Future<void> getActiveAds({BuildContext? context}) async {
    _visibleAds.clear();
    notifyListeners();

    _activeAds = await UserDataService().fetchActiveAds();
    _activeAds.shuffle();
    _filteredAds = List.from(_activeAds);
    _applyFiltersAndSort();
    await preloadImages(_visibleAds);
    notifyListeners();
    if (context != null) context.read<BookmarksProvider>().getBookmarks(context);
  }

  Future<void> preloadImages(List<Product> products) async {
    for (var product in products) {
      try {
        CachedNetworkImageProvider(product.imagePath).resolve(const ImageConfiguration());
      } catch (e) {
        debugPrint("Failed to preload image: ${product.imagePath}, Error: $e");
      }
    }
  }

  Future<void> loadMoreAds() async {
    int remaining = _filteredAds.length - _visibleAds.length;
    int adsToLoad = remaining >= 2 ? 2 : remaining;

    for (int i = 0; i < adsToLoad; i++) {
      _visibleAds.add(_filteredAds[_visibleAds.length]);
      print("LOADED ${_visibleAds.length}");
    }

    if (adsToLoad > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      debugPrint("No more ads to load");
    }
  }

  void setFilter(Map<String, dynamic> filters) {
    _selectedFilters = Map.from(filters);
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(String sortOption) {
    _selectedSortOption = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSearch(String searchQuery) {
    _searchQuery = searchQuery.toLowerCase();
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredAds = List.from(_activeAds);

    // Apply filters
    _selectedFilters.forEach((filterType, filterValue) {
      if (filterValue != null && filterValue.isNotEmpty) {
        switch (filterType) {
          case 'filterCategory':
            _filteredAds = _filteredAds.where((ad) => ad.category == filterValue).toList();
            break;
          case 'filterCondition':
            _filteredAds = _filteredAds.where((ad) => ad.condition == filterValue).toList();
            break;
          case 'filterHostel':
            _filteredAds = _filteredAds.where((ad) => filterValue.contains(ad.sellerHostel)).toList();
            break;
        }
      }
    });

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredAds = _filteredAds
          .where((ad) =>
              ad.itemName.toLowerCase().contains(_searchQuery) ||
              ad.itemDescription.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Recent':
        _filteredAds.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
        break;
      case 'Low':
        _filteredAds.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'High':
        _filteredAds.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    _visibleAds = _filteredAds.take(5).toList();
  }

  void toggleStatus(String status, Product ad) {
    if (status == 'Active') {
      if (!_activeAds.any((item) => item.itemID == ad.itemID)) {
        _activeAds.add(ad);
        notifyListeners();
      }
    } else {
      _activeAds.remove(ad);
      _filteredAds.remove(ad);
      _visibleAds.remove(ad);
      notifyListeners();
    }
  }

  void markAsSold(String itemID) async {
    var ad = _activeAds.firstWhere((ad) => ad.itemID == itemID);
    ad.status = 'Sold';
    notifyListeners();
  }

  void reset() {
    _activeAds.clear();
    _visibleAds.clear();
    _filteredAds.clear();
    _selectedFilters.clear();
    _selectedSortOption = '';
    _searchQuery = '';
    notifyListeners();
  }
}
