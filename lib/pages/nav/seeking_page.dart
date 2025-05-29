import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/bouncing_text.dart';
import 'package:vbay/components/search_bar.dart';
import 'package:vbay/components/seek_tile.dart';
import 'package:vbay/providers/active_seeks_provider.dart';
import 'package:vbay/services/auth/auth_service.dart';

class SeekingPage extends StatefulWidget {
  const SeekingPage({super.key});

  @override
  _SeekingPageState createState() => _SeekingPageState();
}

class _SeekingPageState extends State<SeekingPage> {
  bool _isRefreshing = false;
  bool status = false;

  @override
  void initState() {
    super.initState();
    _getStatus();
  }

  Future<bool> _getStatus() async {
    status = await AuthService().getStatus();
    return status;
  }

  Future<void> _refreshSeeks() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    await Future.delayed(Duration(seconds: 1));

    await Provider.of<ActiveSeeksProvider>(context, listen: false).getActiveSeeks();
    print('Refreshed seeks');
    Future.delayed(Duration(seconds: 10), () {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: Column(
        children: [
          SizedBox(height: 50),
          MySearchBar(
            adsProvider: Provider.of<ActiveSeeksProvider>(context, listen: false),
            hintText: 'Search all seeks',
          ),
          SizedBox(height: 20),
          Expanded(
            child: Consumer<ActiveSeeksProvider>(
              builder: (context, activeSeeksProvider, child) {
                final seeks = activeSeeksProvider.visibleSeeks;
                return RefreshIndicator(
                  onRefresh: _refreshSeeks,
                  color: Theme.of(context).colorScheme.secondary,
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  child: seeks.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                'No Seeks Yet!!',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: seeks.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            bool isLastItem = index == seeks.length - 1;
                            return Padding(
                              padding: isLastItem ? const EdgeInsets.only(bottom: 16.0) : EdgeInsets.zero,
                              child: SeekTile(seek: seeks[index], isCreator: status),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
