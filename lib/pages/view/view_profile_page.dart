import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/seek_tile.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/services/data/user_data_service.dart';

class ViewProfilePage extends StatefulWidget {
  final String profileID;
  final int index;

  const ViewProfilePage({
    super.key,
    required this.profileID,
    this.index = 0,
  });

  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: UserDataService().getAnotherUserData(widget.profileID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No user data found"));
            }

            final userData = snapshot.data![0] ?? {};
            final userSellingList = snapshot.data![1] as List<Product>;
            final userSeekingList = snapshot.data![2] as List<Seek>;
            userSellingList.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
            userSeekingList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: ClipOval(
                                  child: userData['profile']['avatarUrl'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: userData['profile']['avatarUrl'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Transform.translate(
                                            offset: Offset(0, 11),
                                            child: Icon(
                                              CupertinoIcons.person_alt,
                                              color: Colors.grey,
                                              size: 80,
                                            ),
                                          ),
                                        )
                                      : Transform.translate(
                                          offset: Offset(0, 11),
                                          child: Icon(
                                            CupertinoIcons.person_alt,
                                            color: Colors.grey,
                                            size: 80,
                                          ),
                                        ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${userSellingList.length}',
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .8),
                                        ),
                                      ),
                                      Text(
                                        'Ads',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 32),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${userSeekingList.length}',
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .8),
                                        ),
                                      ),
                                      Text(
                                        'Seeks',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          userData['profile']['name'] ?? 'Name',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          userData['profile']['bio'] ?? 'Bio',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${userData['profile']['college'] ?? 'College'}\nBatch of ${userData['profile']['batch'] ?? '20XX'}\n${userData['profile']['hostel'] ?? 'Hostel'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  floating: true,
                  pinned: true,
                  delegate: _FloatingHeaderDelegate(
                    child: Container(
                      color: Theme.of(context).colorScheme.secondary,
                      child: TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sell, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Selling',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Seeking',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onTap: (index) {
                          _tabController.animateTo(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        dividerColor: Colors.transparent,
                        labelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .8),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .8),
                        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                ),
              ],
              body: Container(
                color: Theme.of(context).colorScheme.tertiary,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    userSellingList.isEmpty
                        ? _buildEmptyTab(Icons.sell, "This user isn't selling anything!")
                        : buildItemTiles(userSellingList),
                    userSeekingList.isEmpty
                        ? _buildEmptyTab(Icons.search, "This user isn't seeking anything!")
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: userSeekingList.length,
                            itemBuilder: (context, index) {
                              bool isLastItem = index == userSeekingList.length - 1;

                              return Padding(
                                padding: index == 0
                                    ? EdgeInsets.only(top: 8)
                                    : isLastItem
                                        ? const EdgeInsets.only(bottom: 16.0)
                                        : EdgeInsets.zero,
                                child: SeekTile(seek: userSeekingList[index], isAnotherProfile: true),
                              );
                            },
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildItemTiles(List<Product> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1, bottom: 1),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return GestureDetector(
            onTap: () {
              Utils.showProductPopup(context, item);
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: item.imagePath,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) {
                            debugPrint('Error loading image from Network: $error');
                            return Opacity(
                              opacity: 0.3,
                              child: Image.asset('assets/default.png'),
                            );
                          },
                        )
                      : Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading image from Assets: $error');
                            return Opacity(
                              opacity: 0.3,
                              child: Image.asset('assets/default.png'),
                            );
                          },
                        ),
                  if (item.status == 'Sold')
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          "SOLD",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FloatingHeaderDelegate({required this.child});

  @override
  double get minExtent => 49;

  @override
  double get maxExtent => 49;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
