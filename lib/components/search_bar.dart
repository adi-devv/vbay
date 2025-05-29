import 'package:flutter/material.dart';

class MySearchBar extends StatefulWidget {
  final dynamic adsProvider;
  final String hintText;

  const MySearchBar({
    super.key,
    required this.adsProvider,
    required this.hintText,
  });

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                widget.adsProvider.setSearch(_searchController.text);
              },
            ),
          ),
          const Icon(Icons.search, color: Colors.grey),
        ],
      ),
    );
  }
}
