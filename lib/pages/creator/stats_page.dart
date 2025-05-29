import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/globals.dart';
import 'package:vbay/services/data/creator_service.dart';
import 'package:vbay/services/data/user_data_service.dart';

class StatsPage extends StatefulWidget {
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.app_badge_fill, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: CreatorService().fetchStatsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;

          return Column(
            children: [
              const Text(
                "Creator Stats",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Grid Tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildStatTile(
                          "Total Users",
                          stats['total_users'].values.fold(0, (total, userList) => total + userList.length).toString(),
                          Icons.people,
                          Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                          "New Users 24H",
                          stats['new_users_24H']
                              .values
                              .fold(0, (total, userList) => total + userList.length)
                              .toString(),
                          Icons.person_add,
                          Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        "Active Users",
                        stats['live_users'].values.fold(0, (total, userList) => total + userList.length).toString(),
                        Icons.wifi_tethering,
                        Colors.orange,
                        onTap: () => showActiveUsersDialog(
                          context,
                          (stats['live_users'] as Map<String, List<String>>).values.expand((uids) => uids).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // List Details
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDetailItem(
                        "Active Users 24H",
                        (stats['active_users_24H'] as Map<String, int>)
                            .values
                            .fold(0, (sum, value) => sum + value)
                            .toString()),
                    _buildDetailItem("Active Ads", stats['active_ads'].toString()),
                    _buildDetailItem("Active Seeks", stats['active_seeks'].toString()),
                    _buildDetailItem("Chat Rooms", stats['chat_rooms'].toString()),
                    _buildDetailItem("Pending Ads", stats['pending_ads'].toString()),
                    _buildDetailItem("Pending Seeks", stats['pending_seeks'].toString()),
                    _buildDetailItem("Sell Assists", stats['sold_items'].toString()),
                    _buildDetailItem("Feedbacks", stats['feedbacks'].toString()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 200,
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colleges.values.length,
                    itemBuilder: (context, index) {
                      final college = colleges.values.elementAt(index);
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  college,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatTile(
                                      "Total",
                                      (stats['total_users'][college]?.length ?? 0).toString(),
                                      Icons.people,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatTile(
                                      "New 24H",
                                      (stats['new_users_24H'][college]?.length ?? 0).toString(),
                                      Icons.person_add,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatTile(
                                      "Active",
                                      (stats['live_users'][college]?.length ?? 0).toString(),
                                      Icons.whatshot,
                                      Colors.orange,
                                      onTap: () => showActiveUsersDialog(
                                        context,
                                        stats['live_users'][college] ?? [],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildDetailItem(
                                "Active Users 24H",
                                stats['active_users_24H'][college].toString(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Text(
                value,
                key: ValueKey<String>(value),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    Color textColor = Colors.white;
    if (title.contains("Pending")) {
      textColor = Colors.purpleAccent.shade700;
    } else if (title == 'Sell Assists' || title == 'Feedbacks') {
      textColor = Color(0xFF00C1A2);
    } else {
      textColor = Theme.of(context).colorScheme.onPrimary;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void showActiveUsersDialog(BuildContext context, List<String> activeUserIDs) async {
    List<String> names = [];

    for (String uid in activeUserIDs) {
      final doc = await UserDataService().fetchUserData(uid);
      if (doc != null) {
        names.add(doc['profile']['name'] ?? 'Unknown');
      }
    }

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.secondary,
        title: const Text(
          "Active Users",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: theme.brightness == Brightness.dark ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
        content: names.isEmpty
            ? const Text("No names found.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: names
                    .map((name) => Text(
                          name,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}
