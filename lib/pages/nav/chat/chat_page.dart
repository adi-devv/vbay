import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/chat_bubble.dart';
import 'package:vbay/pages/view/view_profile_page.dart';
import 'package:vbay/providers/chat_provider.dart';
import 'package:vbay/services/data/chat_service.dart';
import 'package:vbay/services/data/user_data_service.dart';
import 'package:vbay/models/product.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> receiverData;
  final Product? product;
  final String? chatText;

  const ChatPage({
    super.key,
    required this.receiverData,
    this.product,
    this.chatText,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, BuildContext> messageContexts = {};
  FocusNode myFocusNode = FocusNode();

  ValueNotifier<dynamic> replyToNotifier = ValueNotifier<dynamic>(null);

  @override
  void initState() {
    super.initState();
    if (widget.product != null) replyToNotifier.value = widget.product;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setChatData(chatWithID: widget.receiverData['uid']);
    });
  }

  late var _myProvider;

  @override
  void didChangeDependencies() {
    _myProvider = context.read<ChatProvider>(); // Cache the provider before disposal
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _myProvider.setChatData();
    myFocusNode.dispose();
    _messageController.dispose();
    replyToNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  bool _chatRoomChecked = false;

  void sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _messageController.clear();

      final replyValue = replyToNotifier.value;
      replyToNotifier.value = null;

      if (widget.chatText != null && !_chatRoomChecked) {
        _chatRoomChecked = true;
        await _chatService.checkChatRoom(widget.receiverData['uid']);
      }

      await _chatService.sendMessage(
        widget.receiverData['uid'],
        message,
        replyAdID: replyValue is Product ? replyValue.itemID : null,
        replyToID: replyValue is Map<String, dynamic> ? replyValue['msgID'] : null,
      );

      if (mounted) scrollDown();
    }
  }

  void cancelReply() {
    replyToNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/default33.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 80),
              Expanded(
                child: MessagesList(
                  chatService: _chatService,
                  receiverData: widget.receiverData,
                  scrollController: _scrollController,
                  messageContexts: messageContexts,
                ),
              ),
              _buildUserInput(context),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: 36, bottom: 8),
              color: Theme.of(context).colorScheme.secondary,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.arrow_left),
                    onPressed: () => Navigator.pop(context),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ViewProfilePage(profileID: widget.receiverData['uid'])),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 20,
                      child: ClipOval(
                          child: widget.receiverData['profile']['avatarUrl'] != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.receiverData['profile']['avatarUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Transform.translate(
                                    offset: Offset(0, 5),
                                    child: Icon(
                                      CupertinoIcons.person_alt,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Transform.translate(
                                  offset: Offset(0, 5),
                                  child: Icon(
                                    CupertinoIcons.person_alt,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewProfilePage(profileID: widget.receiverData['uid'])),
                      ),
                      child: Text(
                        widget.receiverData['profile']['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'end_conversation') {
                          ChatService().endConversation(widget.receiverData['uid']);
                          Navigator.pop(context);
                        }
                      },
                      offset: Offset(0, 40),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'end_conversation',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'End Conversation',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput(BuildContext context) {
    if (widget.chatText != null) _messageController.text = widget.chatText!;
    return ValueListenableBuilder<dynamic>(
      valueListenable: replyToNotifier,
      builder: (context, replyTo, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(replyTo != null ? 16 : 24),
                      topRight: Radius.circular(replyTo != null ? 16 : 24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF111111)
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: replyTo is Product
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6, right: 6, top: 6, bottom: 4),
                                child: Container(
                                    padding: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          height: 80,
                                          width: 80,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: widget.product!.imagePath,
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
                                                widget.product!.itemName,
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
                                                  widget.product!.itemDescription,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary
                                                          .withValues(alpha: 0.5),
                                                      fontSize: 13),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: cancelReply,
                                          child: Icon(
                                            Icons.clear,
                                            color: Colors.grey[700],
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    )),
                              )
                            : replyTo != null
                                ? Padding(
                                    key: ValueKey(replyTo),
                                    padding: const EdgeInsets.all(4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border(
                                          left: BorderSide(
                                            color: const Color(0xFF00C1A2),
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Replying to: ${replyTo['message']}",
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.surface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: cancelReply,
                                            child: Icon(Icons.clear,
                                                color: Theme.of(context).colorScheme.surface, size: 18),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                      TextField(
                        controller: _messageController,
                        focusNode: myFocusNode,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C1A2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class MessagesList extends StatefulWidget {
  final ChatService chatService;
  final Map<String, dynamic> receiverData;
  final ScrollController scrollController;
  Map<String, BuildContext> messageContexts = {};

  MessagesList({
    super.key,
    required this.chatService,
    required this.receiverData,
    required this.scrollController,
    required this.messageContexts,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, dynamic> _productCache = {};
  StreamSubscription? _messagesSubscription;
  List<StreamSubscription> _productStreamSubscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.animateTo(
        widget.scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    var msgStream = widget.receiverData['msgStream'];
    var earlierMsgs = widget.receiverData['earlierMsgs'] ?? [];

    if (mounted) {
      setState(() {
        for (var msg in earlierMsgs) {
          if (!_messages.any((m) => m['msgID'] == msg['msgID'])) {
            _messages.insert(0, msg);
            _listKey.currentState?.insertItem(0);

            if (msg['replyAdID'] != null) {
              _fetchAndCacheProduct(msg);
            }
          }
        }
      });
      ChatService().markAsRead(earlierMsgs, receiverID: widget.receiverData['uid']);
    }

    _messagesSubscription =
        (msgStream ?? widget.chatService.getMessages(widget.receiverData['uid'])).listen((snapshot) {
      ChatService().markAsRead(snapshot);

      if (msgStream != null) {
        print("Using msgStream");
      } else {
        print("Using getMessages");
      }

      for (var change in snapshot.docChanges) {
        final updatedMessage = change.doc.data() as Map<String, dynamic>;
        updatedMessage['msgID'] = change.doc.id;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (change.type == DocumentChangeType.added) {
                _messages.insert(0, updatedMessage);
                _listKey.currentState?.insertItem(0);

                if (updatedMessage['replyAdID'] != null) {
                  _fetchAndCacheProduct(updatedMessage);
                }
              } else if (change.type == DocumentChangeType.modified) {
                int index = _messages.indexWhere((msg) => msg['msgID'] == updatedMessage['msgID']);
                if (index != -1) {
                  _messages[index] = updatedMessage;
                }
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    for (var subscription in _productStreamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchAndCacheProduct(Map<String, dynamic> msg) async {
    if (_productCache.containsKey(msg['replyAdID'])) return;
    _productCache[msg['replyAdID']] = true;

    String sellerName, sellerHostel;
    if (msg['receiverID'] == widget.receiverData['uid']) {
      sellerName = widget.receiverData['profile']['name'];
      sellerHostel = widget.receiverData['profile']['hostel'];
    } else {
      var profile = await UserDataService().fetchUserProfile();
      sellerName = profile!['name'];
      sellerHostel = profile['hostel'];
    }

    Stream<Map<String, dynamic>?> productStream = UserDataService().fetchAdStream(msg['receiverID'], msg['replyAdID']);

    StreamSubscription subscription = productStream.listen((updatedData) {
      if (updatedData != null && mounted) {
        Product updatedProduct =
            Product.fromMap(updatedData, msg['replyAdID'], sellerName, sellerHostel, null, msg['receiverID']);

        setState(() {
          _productCache[msg['replyAdID']] = updatedProduct;
        });
      }
    });
    _productStreamSubscriptions.add(subscription);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_messages.length < 4)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF00C1A2),
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade900.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.7),
                        0.7,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Remember to keep the conversation polite and respectful.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AnimatedList(
          reverse: true,
          key: _listKey,
          controller: widget.scrollController,
          initialItemCount: _messages.length,
          itemBuilder: (context, index, animation) {
            final data = _messages[index];
            String? replyText;

            if (data.containsKey('replyToID')) {
              final replyToMessage = _messages.firstWhere(
                (msg) => msg['msgID'] == data['replyToID'],
                orElse: () => {},
              );
              replyText = replyToMessage['message'];
            }

            bool isNextSameSender = index != 0 && _messages[index - 1]['senderID'] == data['senderID'];
            double bottomPadding = index == 0 || isNextSameSender ? 0 : 12;

            // Extract and format the timestamp
            DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
            String dateLabel = _getDateLabel(messageTime, index);

            return Column(
              children: [
                if (dateLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                  ),
                SizeTransition(
                  sizeFactor: animation,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Builder(
                      builder: (messageContext) {
                        widget.messageContexts[data['msgID']] = messageContext;
                        return MessageItem(
                          data: data,
                          isCurrentUser: data['senderID'] == UserDataService.getCurrentUser()!.uid,
                          replyText: replyText,
                          replyProduct: data['replyAdID'] != null && _productCache[data['replyAdID']] != true
                              ? _productCache[data['replyAdID']]
                              : null,
                          onReplyTap: () async {
                            final replyToID = data['replyToID'];
                            if (replyToID != null && widget.messageContexts[replyToID] != null && mounted) {
                              Scrollable.ensureVisible(
                                widget.messageContexts[replyToID]!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

// Function to get date labels
  String _getDateLabel(DateTime messageTime, int index) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));
    DateTime startOfWeek = today.subtract(Duration(days: now.weekday - 1));

    if (index == _messages.length - 1 ||
        DateTime.fromMillisecondsSinceEpoch(_messages[index + 1]['timestamp']).day != messageTime.day) {
      if (messageTime.isAfter(today)) {
        return "Today";
      } else if (messageTime.isAfter(yesterday)) {
        return "Yesterday";
      } else if (messageTime.isAfter(startOfWeek)) {
        return DateFormat.EEEE().format(messageTime);
      } else {
        return DateFormat.yMMMd().format(messageTime);
      }
    }
    return "";
  }
}

class MessageItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isCurrentUser;
  final String? replyText;
  final Product? replyProduct;
  final VoidCallback? onReplyTap;

  const MessageItem({
    super.key,
    required this.data,
    required this.isCurrentUser,
    required this.replyText,
    required this.replyProduct,
    required this.onReplyTap,
  });

  @override
  _MessageItemState createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<MessageItem> {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ValueNotifier<double> dragOffset;

  final double replyThreshold = 70;
  late double screenWidth;
  late double maxDragOffset;

  @override
  void initState() {
    super.initState();
    dragOffset = ValueNotifier(0.0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
  }

  @override
  void dispose() {
    dragOffset.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    maxDragOffset = MediaQuery.of(context).size.width * 0.3;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.isCurrentUser) {
          dragOffset.value = (dragOffset.value + details.primaryDelta!).clamp(-maxDragOffset, 0.0);
        } else {
          dragOffset.value = (dragOffset.value + details.primaryDelta!).clamp(0.0, maxDragOffset);
        }
      },
      onHorizontalDragEnd: (details) {
        final chatPageState = context.findAncestorStateOfType<_ChatPageState>();

        if (chatPageState != null &&
            ((widget.isCurrentUser && dragOffset.value <= -replyThreshold) ||
                (!widget.isCurrentUser && dragOffset.value >= replyThreshold))) {
          chatPageState.replyToNotifier.value = widget.data;
        }

        _animation = Tween<double>(begin: dragOffset.value, end: 0.0).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.fastOutSlowIn,
        ));

        _animationController.forward(from: 0.0);
        dragOffset.value = 0.0;
      },
      child: ValueListenableBuilder<double>(
        valueListenable: dragOffset,
        builder: (context, offset, child) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(offset + _animation.value, 0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
                  child: Container(
                    alignment: widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ChatBubble(
                      key: ValueKey(widget.data['msgID']),
                      msgData: widget.data,
                      isCurrentUser: widget.isCurrentUser,
                      replyText: widget.replyText,
                      replyProduct: widget.replyProduct,
                      onReplyTap: widget.onReplyTap,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
