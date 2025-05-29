import 'package:flutter/material.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/services/data/user_data_service.dart';

class UserDataProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  List<Product> _userSellingList = [];
  List<Seek> _userSeekingList = [];

  Map<String, dynamic>? get userData => _userData;

  List<Product> get userSellingList => _userSellingList;

  List<Seek> get userSeekingList => _userSeekingList;

  String? userID;

  Future<void> fetchUserProfile() async {
    _userData = await UserDataService().fetchUserProfile();
    notifyListeners();
  }

  void updateUserData(Map<String, dynamic> newUserData) {
    String newName = newUserData['name'];
    String newHostel = newUserData['hostel'];

    bool hasChanged = _userData!['name'] != newName || _userData!['hostel'] != newHostel;

    _userData = newUserData;

    if (hasChanged) {
      for (Product product in _userSellingList) {
        product.sellerName = newName;
        product.sellerHostel = newHostel;
      }

      for (Seek seek in _userSeekingList) {
        seek.seekerName = newName;
        seek.seekerHostel = newHostel;
      }
    }

    notifyListeners();
  }

  Future<void> fetchUserAds() async {
    String currentUserID = UserDataService.getCurrentUser()!.uid;
    if (userID == null || userID != currentUserID) {
      userID = currentUserID;
      try {
        final fetchedList = await UserDataService().fetchUserAds();
        _userSellingList = fetchedList[0].cast<Product>();
        _userSeekingList = fetchedList[1].cast<Seek>();

        _userSellingList.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        _userSeekingList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        notifyListeners();
      } catch (e) {
        print('Error fetching user ads: $e');
        rethrow;
      }
    }
  }

  void insertItem(dynamic item) {
    if (item is Product) {
      _userSellingList.insert(0, item);
    } else if (item is Seek) {
      _userSeekingList.insert(0, item);
    } else {
      throw ArgumentError("Invalid item type. Must be Product or Seek.");
    }
    notifyListeners();
  }

  void deleteItem(dynamic item) {
    try {
      if (item is Seek) {
        _userSeekingList.removeWhere((seek) => seek.itemID == item.itemID);
      } else if (item is Product) {
        _userSellingList.removeWhere((product) => product.itemID == item.itemID);
      } else {
        throw ArgumentError("Invalid item type. Must be Product or Seek.");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting item: $e");
      throw Exception("Failed to delete item: $e");
    }
  }

  void updateItem(dynamic item) {
    if (item is Product) {
      final index = _userSellingList.indexWhere((i) => i.itemID == item.itemID);
      if (index != -1) {
        _userSellingList[index] = item;
      }
    } else if (item is Seek) {
      final index = _userSeekingList.indexWhere((i) => i.itemID == item.itemID);
      if (index != -1) {
        _userSeekingList.removeAt(index);
        _userSeekingList.insert(0, item);
      }
    } else {
      throw ArgumentError("Invalid item type. Must be Product or Seek.");
    }
    notifyListeners();
  }

  void updateAdStatus(dynamic ad, String newStatus, dynamic provider) {
    if (ad is Product) {
      final index = _userSellingList.indexWhere((i) => i.itemID == ad.itemID);
      if (index != -1) {
        _userSellingList[index].status = newStatus;
        UserDataService().toggleItemActiveStatus(ad.itemID!, newStatus);
        provider.toggleStatus(newStatus, ad);
      }
    } else if (ad is Seek) {
      final index = _userSeekingList.indexWhere((i) => i.itemID == ad.itemID);
      if (index != -1) {
        _userSeekingList[index].status = newStatus;
        UserDataService().toggleItemActiveStatus(ad.itemID, newStatus, isSeek: true);
        provider.toggleStatus(newStatus, ad);
      }
    } else {
      throw ArgumentError("Invalid ad type. Must be Product or Seek.");
    }
    notifyListeners();
  }

  void toggleUrgentStatus(Seek seek, bool isUrgent, dynamic provider) {
    final index = _userSeekingList.indexWhere((i) => i.itemID == seek.itemID);
    if (index != -1) {
      _userSeekingList[index].isUrgent = isUrgent;
      UserDataService().toggleUrgentStatus(seek);
      provider.toggleUrgentStatus(seek);
    } else {
      throw ArgumentError("Invalid ad itemID.");
    }
    notifyListeners();
  }

  void markAsSold(String itemID) {
    var ad = _userSellingList.firstWhere((ad) => ad.itemID == itemID);
    ad.status = 'Sold';
    notifyListeners();
  }

  void updatePostNotification(String itemID, String status, String? itemURL, List<String>? selectedReasons) {
    try {
      if (itemID.isEmpty || status.isEmpty) {
        throw ArgumentError("ItemID and Status cannot be empty");
      }
      final sellingIndex = _userSellingList.indexWhere((item) => item.itemID == itemID);
      if (sellingIndex != -1) {
        _userSellingList[sellingIndex].status = status;
        _userSellingList[sellingIndex].itemURL = itemURL;
        _userSellingList[sellingIndex].reasons = selectedReasons?.toList();
      } else {
        final seekingIndex = _userSeekingList.indexWhere((item) => item.itemID == itemID);
        if (seekingIndex != -1) {
          _userSeekingList[seekingIndex].status = status;
          _userSeekingList[seekingIndex].reasons = selectedReasons;
        } else {
          throw ArgumentError("Item not found in either selling or seeking lists.");
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error in updatePostNotification: $e");
    }
  }

  void reset() {
    _userSellingList.clear();
    _userSeekingList.clear();
    userID = null;
    notifyListeners();

    // Debugging logs
    print("UserSellingList is empty: ${_userSellingList.isEmpty}");
    print("UserSeekingList is empty: ${_userSeekingList.isEmpty}");
  }
}
