import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vbay/components/smooth_toggle.dart';
import 'package:vbay/pages/creator/approve_ads_page.dart';
import 'package:vbay/pages/creator/approve_seeks_page.dart';
import 'package:vbay/pages/creator/stats_page.dart';
import 'package:vbay/pages/nav/home/bookmarks_page.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Center(child: Text('Approve Ad', style: TextStyle(fontWeight: FontWeight.bold))),
        leading: IconButton(
          icon: const Icon(Icons.home, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph_outlined, size: 34,color:  Color(0xFF00C1A2),),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatsPage(),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            children: const [
              ApproveAdsPage(),
              ApproveSeeksPage(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmoothToggle(
                onTabChange: _onTabChange,
                tabs: const [
                  GButton(
                    icon: Icons.ad_units,
                    text: 'Ads',
                  ),
                  GButton(
                    icon: Icons.search,
                    text: 'Seeks',
                  ),
                ],
                initialIndex: _currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
