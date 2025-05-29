import 'package:flutter/material.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/services/data/user_data_service.dart';

class ActiveSeeksProvider with ChangeNotifier {
  List<Seek> _activeSeeks = [];
  List<Seek> _visibleSeeks = [];
  String _searchQuery = '';

  List<Seek> get activeSeeks => _activeSeeks;

  List<Seek> get visibleSeeks => _visibleSeeks;

  String get searchQuery => _searchQuery;

  Future<void> getActiveSeeks() async {
    _activeSeeks = await UserDataService().fetchActiveSeeks();
    _activeSeeks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isNotEmpty) {
      _visibleSeeks = _activeSeeks.where((seek) {
        return seek.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    } else {
      _visibleSeeks = List.from(_activeSeeks);
    }
  }

  void toggleStatus(String status, Seek seek) {
    if (status == 'Active') {
      if (!_activeSeeks.any((item) => item.itemID == seek.itemID)) {
        _activeSeeks.add(seek);
        _activeSeeks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _applySearchFilter();
        notifyListeners();
      }
    } else {
      _activeSeeks.removeWhere((item) => item.itemID == seek.itemID);
      _visibleSeeks.removeWhere((item) => item.itemID == seek.itemID);
      notifyListeners();
    }
  }

  void toggleUrgentStatus(Seek seek) {
    for (List<Seek> list in [_activeSeeks, _visibleSeeks]) {
      int index = list.indexWhere((item) => item.itemID == seek.itemID);
      if (index != -1) list[index].isUrgent = seek.isUrgent;
    }

    notifyListeners();
  }


  void reset() {
    _activeSeeks.clear();
    _visibleSeeks.clear();
    _searchQuery = '';
    notifyListeners();
  }
}
