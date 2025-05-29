import 'package:flutter/material.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductGridView extends StatelessWidget {
  final List<Product> itemList;
  final VoidCallback? loadMoreAds;
  final bool? isCreator;

  const ProductGridView({
    required this.itemList,
    this.loadMoreAds,
    this.isCreator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      padding: EdgeInsets.all(16),
      itemCount: itemList.length,
      itemBuilder: (context, index) {
        if (index == itemList.length - 2) {
          loadMoreAds?.call();
        }
        final product = itemList[index];
        return GestureDetector(
          onTap: () {
            Utils.showProductPopup(context, product, isCreator: isCreator);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(fit: StackFit.expand, children: [
                        product.imagePath.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: product.imagePath,
                                placeholder: (context, url) => Opacity(
                                  opacity: 0.3,
                                  child: Image.asset('assets/default.png'),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Image.asset('assets/default.png'),
                                ),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                product.imagePath,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        if (product.status == 'Sold')
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
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
                      ])),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                  child: Text(
                    product.itemName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      Utils.formatCurrency(product.price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
