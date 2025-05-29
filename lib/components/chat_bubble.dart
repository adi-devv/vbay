import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vbay/components/explore_tile.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/pages/nav/profile/view_ad_page.dart';
import 'package:vbay/models/product.dart';
import 'package:vbay/pages/sell/preview_page.dart';

class ChatBubble extends StatefulWidget {
  final Map<String, dynamic> msgData;
  final bool isCurrentUser;
  final String? replyText;
  final Product? replyProduct;
  final VoidCallback? onReplyTap;

  const ChatBubble({
    super.key,
    required this.msgData,
    required this.isCurrentUser,
    this.replyText,
    this.replyProduct,
    this.onReplyTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.isCurrentUser ? const EdgeInsets.only(left: 40) : const EdgeInsets.only(right: 40),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isCurrentUser
              ? Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF007E6A)
                  : const Color(0xFF00C1A2)
              : Theme.of(context).brightness == Brightness.dark
                  ? Color(0xFF111111)
                  : Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: widget.isCurrentUser ? const Radius.circular(8) : Radius.zero,
            bottomRight: widget.isCurrentUser ? Radius.zero : const Radius.circular(8),
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            children: [
              if (widget.replyText != null)
                GestureDetector(
                  onTap: widget.onReplyTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF202020)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: !widget.isCurrentUser
                            ? Border(
                                left: BorderSide(
                                  color: Color(0xFF00C1A2),
                                  width: 4,
                                ),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                widget.replyText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (widget.replyProduct != null)
                GestureDetector(
                  onTap: () {
                    Utils.showProductPopup(context, widget.replyProduct!);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 6, top: 6, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF202020)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 81,
                            width: 81,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: widget.replyProduct!.imagePath,
                                placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Opacity(
                                  opacity: 0.3,
                                  child: Image.asset('assets/default.png'),
                                ),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Text(
                                  widget.replyProduct!.itemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                  height: 50,
                                  child: Text(
                                    widget.replyProduct!.itemDescription,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onInverseSurface,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12, right: 12),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.msgData["message"]} ',
                        style: TextStyle(
                          color: widget.isCurrentUser ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                          fontSize: 15,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(width: 8),
                            Text(
                              Utils().formatTimestamp(widget.msgData['timestamp']),
                              style: TextStyle(
                                color: widget.isCurrentUser ? Colors.grey.shade300 : Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            if (widget.isCurrentUser)
                              Icon(
                                Icons.done_all,
                                color: widget.msgData['unread'] == false ? Colors.blueAccent : Colors.grey.shade300,
                                size: 18,
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
