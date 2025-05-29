import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/components/smooth_toggle.dart';
import 'package:vbay/main.dart';
import 'package:vbay/providers/active_ads_provider.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/pages/sell/item_details_page.dart';
import 'package:vbay/components/utils.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vbay/services/data/user_data_service.dart';

class ViewAdPage extends StatefulWidget {
  final Product item;

  const ViewAdPage({super.key, required this.item});

  @override
  State<ViewAdPage> createState() => _ViewAdPageState();
}

class _ViewAdPageState extends State<ViewAdPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    final newStatus = index == 0 ? 'Inactive' : 'Active';

    final adsProvider = Provider.of<UserDataProvider>(context, listen: false);
    adsProvider.updateAdStatus(widget.item, newStatus, Provider.of<ActiveAdsProvider>(context, listen: false));

    setState(() {}); // To update static UI

    Utils.showSnackBar(context, "Ad status changed to $newStatus.");
  }

  @override
  Widget build(BuildContext context) {
    final Product item = widget.item;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_left, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              Center(
                child: Text('Your Ad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              item.status == 'Pending' || item.status == 'Sold'
                  ? Utils.buildEmptyIcon()
                  : IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailsPage(item: item),
                          ),
                        );
                      },
                    )
            ],
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 48,
                  right: 48,
                  top: item.status == 'Pending' || item.status == 'Rejected' || item.status == 'Sold' ? 80 : 40),
              child: Column(
                children: [
                  ExploreTile(product: item),
                  if (item.status == 'Active' || item.status == 'Inactive')
                    GestureDetector(
                      onTap: () => showMarkAsSoldDialog(context, item),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mark this item as Sold?',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  if (item.status == 'Active')
                    Center(
                      child: Text(
                        'Get noticed, share your Ad! 🚀',
                        style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (item.status == 'Active' || item.status == 'Inactive')
            Center(
              child: SmoothToggle(
                initialIndex: item.status == 'Active' ? 1 : 0,
                onTabChange: _onTabChange,
                tabs: const [
                  GButton(
                    icon: Icons.visibility_off,
                    text: 'Inactive',
                  ),
                  GButton(
                    icon: Icons.visibility,
                    text: 'Active',
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade700.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                textAlign: TextAlign.center,
                item.status == 'Rejected'
                    ? 'Ad Rejected due to:\n- ${widget.item.reasons!.join('\n- ')}'
                    : item.status == 'Sold'
                        ? 'This item has been sold!'
                        : 'Your Ad is pending for approval!',
                style: TextStyle(
                  color: item.status == 'Rejected'
                      ? Colors.redAccent
                      : item.status == 'Sold'
                          ? Colors.green
                          : Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void showMarkAsSoldDialog(BuildContext context, Product item) {
    bool didVBayHelp = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.only(top: 20),
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Mark as sold?\nThis action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: didVBayHelp,
                          onChanged: (value) {
                            setState(() {
                              didVBayHelp = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: Text("Did VBay help you sell this item?"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: Theme.of(context).brightness == Brightness.dark
                  ? BorderSide(color: Colors.white, width: 2)
                  : BorderSide.none,
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  MaterialButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Skip", style: TextStyle(fontSize: 15)),
                  ),
                  MaterialButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      await UserDataService().markAsSold(navigatorKey.currentContext!, item, didVBayHelp);
                    },
                    child: Text("Confirm", style: TextStyle(fontSize: 15, color: Colors.blue)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
