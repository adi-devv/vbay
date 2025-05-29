import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/models/product.dart';

class PreviewPage extends StatelessWidget {
  final Product item;

  const PreviewPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        title: const Text('Preview Your Ad', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
                  child: ExploreTile(product: item),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Your Ad will look like this!',
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
