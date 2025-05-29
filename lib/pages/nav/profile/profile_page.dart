import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/my_drawer.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/models/seek.dart';
import 'package:vbay/pages/nav/profile/user_details_page.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/pages/nav/profile/view_ad_page.dart';
import 'package:vbay/providers/active_seeks_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Provider.of<UserDataProvider>(context, listen: false).fetchUserProfile();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserAds();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserAds() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    await Future.delayed(Duration(seconds: 1));

    await Provider.of<UserDataProvider>(context, listen: false).fetchUserAds();
    print('Fetched');
    Future.delayed(Duration(seconds: 10), () {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserDetailsPage()),
              );
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Consumer<UserDataProvider>(
          builder: (context, userProvider, child) {
            final userData = userProvider.userData ?? {};

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: RefreshIndicator(
                    onRefresh: fetchUserAds,
                    color: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
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
                                        child: userData['avatarUrl'] != null
                                            ? CachedNetworkImage(
                                                imageUrl: userData['avatarUrl'],
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
                                              )),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${userProvider.userSellingList.where((ad) => ad.status == "Active" || ad.status == "Sold").length}',
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
                                            '${userProvider.userSeekingList.where((ad) => ad.status == "Active").length}',
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
                              userData['name'] ?? 'Name',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              userData['bio'] ?? 'Bio',
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
                                    '${userData['college'] ?? 'College'}\nBatch of ${userData['batch'] ?? '20XX'}\n${userData['hostel'] ?? 'Hostel'}',
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
                    userProvider.userSellingList.isEmpty
                        ? _buildEmptyTab(Icons.sell, 'Your Ads will appear here!')
                        : buildItemTiles(userProvider.userSellingList),
                    userProvider.userSeekingList.isEmpty
                        ? _buildEmptyTab(Icons.search, 'Your Ads will appear here!')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: userProvider.userSeekingList.length,
                            itemBuilder: (context, index) {
                              bool isLastItem = index == userProvider.userSeekingList.length - 1;

                              return Padding(
                                padding: index == 0
                                    ? EdgeInsets.only(top: 8)
                                    : isLastItem
                                        ? const EdgeInsets.only(bottom: 16.0)
                                        : EdgeInsets.zero,
                                child: buildSeekTile(context, userProvider.userSeekingList[index]),
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

          Color overlayColor = Colors.transparent;
          if (item.status == 'Rejected') {
            overlayColor = Colors.red.withValues(alpha: 0.4);
          } else if (item.status == 'Inactive') {
            overlayColor = Colors.black.withValues(alpha: 0.5);
          } else if (item.status == 'Sold') {
            overlayColor = Colors.black.withValues(alpha: 0.5);
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewAdPage(item: item),
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image widget (unchanged)
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
                  Container(
                    color: overlayColor,
                  ),
                  // Overlay for Rejected, Inactive, Pending, or Sold status
                  if (item.status == 'Rejected' || item.status == 'Inactive' || item.status == 'Pending')
                    Positioned(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.only(left: 6, right: 8, top: 4, bottom: 2),
                          decoration: BoxDecoration(
                            color: item.status == 'Rejected'
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            item.status ?? 'Unknown',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: item.status == 'Rejected'
                                  ? Colors.red // Custom text color for Sold status
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (item.status == 'Sold')
                    Center(
                      child: Text(
                        "SOLD",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget buildSeekTile(BuildContext context, Seek seek) {
    return GestureDetector(
      onTap: () {
        if (seek.status != 'Pending') {
          BottomNavbarKey.instance.key.currentState?.showSeekDialog(context, seek);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          seek.itemName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${Utils.timeAgo(seek.updatedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  seek.status == 'Rejected' || seek.status == 'Pending'
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            textAlign: TextAlign.center,
                            seek.status == 'Rejected'
                                ? 'Ad Rejected\n${seek.reasons!.join('\n')}'
                                : 'Pending Approval!',
                            style: TextStyle(
                              color: seek.status == 'Rejected' ? Colors.redAccent : Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ))
                      : Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final newStatus = seek.status == 'Active' ? 'Inactive' : 'Active';

                                Provider.of<UserDataProvider>(context, listen: false).updateAdStatus(
                                    seek, newStatus, Provider.of<ActiveSeeksProvider>(context, listen: false));
                                Utils.showSnackBar(context, "Seek status changed to $newStatus.");
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) => ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                      child: Icon(
                                        seek.status == 'Active' ? Icons.visibility : Icons.visibility_off,
                                        key: ValueKey(seek.status),
                                        color: seek.status == 'Active' ? Color(0xFF00C1A2) : Colors.grey.shade600,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                ],
              ),
            ),
            Consumer<UserDataProvider>(builder: (context, provider, child) {
              Seek item = provider.userSeekingList.firstWhere((item) => item.itemID == seek.itemID);

              return item.isUrgent
                  ? Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Urgent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    )
                  : Container();
            })
          ],
        ),
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
