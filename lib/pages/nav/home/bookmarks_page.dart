import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/product_grid_view.dart';
import 'package:vbay/components/search_bar.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/main.dart';
import 'package:vbay/providers/bookmarks_provider.dart';

class BookmarksPage extends StatefulWidget {
  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        leading: IconButton(
          icon: const Icon(Icons.home, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Text(
            "My Bookmarks",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          MySearchBar(
            adsProvider: Provider.of<BookmarksProvider>(context, listen: false),
            hintText: 'Search your bookmarks',
          ),
          SizedBox(height: 20),
          Expanded(
            child: Consumer<BookmarksProvider>(
              builder: (context, bookmarksProvider, child) {
                final bookmarks = bookmarksProvider.userBookmarks;
                if (bookmarks.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 200),
                        Icon(
                          Icons.bookmarks_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Your bookmarks will appear here',
                          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return Consumer<BookmarksProvider>(
                  builder: (context, bookmarksProvider, child) {
                    return ProductGridView(
                      itemList: bookmarksProvider.userBookmarks,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
