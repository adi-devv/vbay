import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/bouncing_text.dart';
import 'package:vbay/components/filter_sort.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/components/my_logo.dart';
import 'package:vbay/components/product_grid_view.dart';
import 'package:vbay/components/search_bar.dart';
import 'package:vbay/pages/nav/home/bookmarks_page.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/pages/creator/approval_page.dart';
import 'package:vbay/services/auth/auth_service.dart';
import 'package:vbay/services/data/link_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/components/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late AnimationController _refreshController;
  final ValueNotifier<double> _scrollExtent = ValueNotifier<double>(0.0);
  bool _reachedThreshold = false;
  bool _isPageViewBuilt = false;
  bool _isRefreshing = false;
  bool _isOnCooldown = false;
  bool status = false;

  @override
  void initState() {
    super.initState();
    print("HOME PAGE INIT");
    _pageController = PageController(
      viewportFraction: 0.75,
      keepPage: true,
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    LinkkService.handleDynamicLinks();
  }

  @override
  void dispose() {
    _scrollExtent.dispose();
    _pageController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<bool> _getStatus() async {
    status = await AuthService().getStatus();
    return status;
  }

  Future<void> _refreshAds() async {
    setState(() {
      _isRefreshing = true;
    });
    _refreshController.repeat();

    await Future.delayed(Duration(seconds: 1));
    _scrollExtent.value = 0.0;

    await Provider.of<ActiveAdsProvider>(context, listen: false).getActiveAds();
    print('Refreshed ads');

    _refreshController.stop();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 30),
          _buildHeader(),
          const SizedBox(height: 20),
          MySearchBar(
            adsProvider: Provider.of<ActiveAdsProvider>(context, listen: false),
            hintText: 'Search for anything',
          ),
          SizedBox(height: 20),
          FilterSort(),
          Consumer<ActiveAdsProvider>(
            builder: (context, activeAdsProvider, child) {
              final products = activeAdsProvider.visibleAds;
              return Flexible(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollUpdateNotification && !_isOnCooldown) {
                      _scrollExtent.value = notification.metrics.pixels;
                      print("Scroll Extent: $_scrollExtent");
                      if (_scrollExtent.value < -80) {
                        _reachedThreshold = true;
                        Future.delayed(Duration(seconds: 1), () => _reachedThreshold = false);
                      }
                    }
                    if (notification is ScrollEndNotification && _reachedThreshold == true && !_isRefreshing) {
                      _refreshAds();
                      _isOnCooldown = true;
                      Future.delayed(Duration(seconds: 10), () => _isOnCooldown = false);
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                      products.isEmpty
                          ? BouncingText(parentContext: context)
                          : activeAdsProvider.selectedFilters.isNotEmpty ||
                                  activeAdsProvider.selectedSortOption.isNotEmpty ||
                                  activeAdsProvider.searchQuery.isNotEmpty
                              ? ProductGridView(
                                  itemList: products,
                                  loadMoreAds: activeAdsProvider.loadMoreAds,
                                  isCreator: status,
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: products.length,
                                  physics: BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    if (index == 0 && !_isPageViewBuilt) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        setState(() {
                                          _isPageViewBuilt = true;
                                        });
                                      });
                                    }
                                    if (index >= products.length - 3) {
                                      activeAdsProvider.loadMoreAds();
                                    }

                                    final product = products[index];
                                    return _buildProductTiles(product, index);
                                  },
                                ),
                      ValueListenableBuilder<double>(
                        valueListenable: _scrollExtent,
                        builder: (context, value, child) {
                          final pullProgress = (-value / 100).clamp(0.0, 1.0);
                          return value < -30 || _isRefreshing
                              ? Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    transform: Matrix4.translationValues(0, 0, 0),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.inversePrimary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _isRefreshing
                                          ? RotationTransition(
                                              turns: _refreshController,
                                              child: Icon(
                                                Icons.refresh,
                                                size: 28,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            )
                                          : Transform.rotate(
                                              angle: pullProgress * 2 * 3.1416,
                                              child: Icon(
                                                Icons.refresh,
                                                size: 28,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                              : SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FutureBuilder<bool>(
            future: _getStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Utils.buildEmptyIcon();
              }
              if (snapshot.hasData && snapshot.data!) {
                return _buildApprovalButton();
              } else {
                return Utils.buildEmptyIcon();
              }
            },
          ),
          const MyLogo(fontSize: 28),
          Transform.translate(
            offset: Offset(0, 2),
            child: IconButton(
              icon: Icon(
                Icons.bookmark_outline,
                size: 28,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarksPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalButton() {
    return IconButton(
      icon: Icon(
        CupertinoIcons.app_badge_fill,
        size: 30,
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ApprovalPage(),
        ),
      ),
    );
  }

  Widget _buildProductTiles(Product product, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        try {
          double page = _isPageViewBuilt ? _pageController.page ?? index.toDouble() : index.toDouble();
          double scale = (1 - (index - page).abs() * 0.1).clamp(0.9, 1.0);
          double opacity = (1 - (index - page).abs() * 0.5).clamp(0.9, 1.0);

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: ExploreTile(product: product, isCreator: status),
            ),
          );
        } catch (e) {
          print("Error in page view builder: $e");
          return ExploreTile(product: product, isCreator: status);
        }
      },
    );
  }
}
