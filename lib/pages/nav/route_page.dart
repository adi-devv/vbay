import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/my_bottom_navbar.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/pages/nav/chat/chats_list_page.dart';
import 'package:vbay/pages/nav/seeking_page.dart';
import 'package:vbay/pages/nav/profile/profile_page.dart';
import 'package:vbay/pages/nav/home/home_page.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/providers/active_seeks_provider.dart';
import 'package:vbay/services/data/user_data_service.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => RoutePageState();
}

class RoutePageState extends State<RoutePage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ActiveAdsProvider>().getActiveAds(context: context);
        context.read<ActiveSeeksProvider>().getActiveSeeks();
        UserDataService().checkForUpdates(context);
      }
    });

    pages = [
      HomePage(),
      SeekingPage(),
      Container(),
      ChatsListPage(),
      ProfilePage(),
    ];
  }

  void navigateBottomBar(int index) {
    _selectedIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex.value != 0) {
          BottomNavbarKey.instance.key.currentState?.changeTab(0);
          return false;
        }
        return true;
      },
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (context, selectedIndex, child) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            body: IndexedStack(
              index: selectedIndex,
              children: pages,
            ),
            bottomNavigationBar: MyBottomNavbar(
              key: BottomNavbarKey.instance.key,
              onTabChange: navigateBottomBar,
            ),
          );
        },
      ),
    );
  }
}
