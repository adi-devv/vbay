import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/globals.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/services/data/user_data_service.dart';

class FilterSort extends StatefulWidget {
  const FilterSort({super.key});

  @override
  _FilterSortState createState() => _FilterSortState();
}

class _FilterSortState extends State<FilterSort> {
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedHostel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              _showFilterOptions(context);
            },
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 6),
                Text(
                  "Filter",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: (_selectedCategory != null || _selectedCondition != null || _selectedHostel != null)
                      ? GestureDetector(
                          key: ValueKey("clearButton"),
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedCondition = null;
                              _selectedHostel = null;
                            });
                            Provider.of<ActiveAdsProvider>(context, listen: false).setFilter({});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00C1A2),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Clear",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              _showSortOptions(context);
            },
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Consumer<ActiveAdsProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.selectedSortOption.isEmpty ? "Sort By" : "Sort By: ${provider.selectedSortOption}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.swap_vert,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);

    showMenu(
      color: Theme.of(context).colorScheme.secondary,
      context: context,
      position: RelativeRect.fromLTRB(0, position.dy + box.size.height, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'filterCategory',
          child: _buildDropdown(context, "Category", categoryList, _selectedCategory),
        ),
        PopupMenuItem<String>(
          value: 'filterCondition',
          child: _buildDropdown(context, "Condition", conditionList, _selectedCondition),
        ),
        PopupMenuItem<String>(
          value: 'filterHostel',
          child: FutureBuilder<Map<String, dynamic>?>(
            future: UserDataService().fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text("Error fetching hostels");
              }

              final userProfile = snapshot.data!;
              final college = userProfile['college'];

              return _buildDropdown(
                context,
                'Hostel',
                hostelData[college] ?? ['Hostel 1', 'Hostel 2', 'Hostel 3'],
                _selectedHostel,
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'Apply',
          child: Center(
            child: TextButton(
              onPressed: () {
                if (_selectedCategory != null || _selectedCondition != null || _selectedHostel != null) {
                  setState(() {});
                  Provider.of<ActiveAdsProvider>(context, listen: false).setFilter({
                    'filterCategory': _selectedCategory,
                    'filterCondition': _selectedCondition,
                    'filterHostel': _selectedHostel,
                  });
                }
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF00C1A2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Center(
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String? selectedValue) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
      dropdownColor: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(8),
      items: items
          .map((item) => DropdownMenuItem(
              value: item,
              child: Center(
                  child: Text(item,
                      style: TextStyle(
                        color: item == "Fresh" ? Colors.lightGreen : Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      )))))
          .toList(),
      onChanged: (value) {
        if (label == "Category") {
          _selectedCategory = value;
        } else if (label == "Condition") {
          _selectedCondition = value;
        } else if (label == "Hostel") {
          _selectedHostel = value;
        }
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);

    showMenu(
      color: Theme.of(context).colorScheme.secondary,
      context: context,
      position: RelativeRect.fromLTRB(position.dx + box.size.width, position.dy + box.size.height, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'Low',
          child: Text('Price: Low to High', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ),
        PopupMenuItem<String>(
          value: 'High',
          child: Text('Price: High to Low', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ),
        PopupMenuItem<String>(
          value: 'Recent',
          child: Text('Posted recently', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ),
        if (Provider.of<ActiveAdsProvider>(context, listen: false).selectedSortOption.isNotEmpty)
          PopupMenuItem<String>(
            value: 'Clear',
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {});

                  Provider.of<ActiveAdsProvider>(context, listen: false).setSortOption('');
                  Navigator.pop(context);
                  return;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Center(
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).then((selectedOption) {
      if (selectedOption != null) {
        Provider.of<ActiveAdsProvider>(context, listen: false).setSortOption(selectedOption);
      }
    });
  }
}
