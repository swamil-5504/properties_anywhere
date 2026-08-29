import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int ownerId;
  final String ownerName;
  final int propertyId;
  final String propertyTitle;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.ownerId,
    required this.ownerName,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  List<Map<String, dynamic>> messages = [];

  bool isLoading = true;
  bool isSending = false;

  // PropertiesAnywhere UI colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color textColor = Color(0xFF171717);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();

    initializeChat();
  }

  // ------------------------------------------------------------
  // INITIALIZE CHAT
  // ------------------------------------------------------------

  Future<void> initializeChat() async {
    await loadMessages();
    await markConversationAsRead();
  }

  // ------------------------------------------------------------
  // GET ID FROM USER OBJECT
  // ------------------------------------------------------------

  int? getUserId(dynamic user) {
    if (user is Map) {
      final dynamic id = user['id'];

      if (id is int) {
        return id;
      }

      return int.tryParse(
        id?.toString() ?? '',
      );
    }

    return null;
  }

  // ------------------------------------------------------------
  // GET SENDER ID
  // ------------------------------------------------------------

  int? getSenderId(
    Map<String, dynamic> message,
  ) {
    return getUserId(message['sender']);
  }

  // ------------------------------------------------------------
  // GET RECEIVER ID
  // ------------------------------------------------------------

  int? getReceiverId(
    Map<String, dynamic> message,
  ) {
    return getUserId(message['receiver']);
  }

  // ------------------------------------------------------------
  // GET PROPERTY ID
  // ------------------------------------------------------------

  int? getMessagePropertyId(
    Map<String, dynamic> message,
  ) {
    final dynamic property = message['property'];

    if (property is Map) {
      final dynamic id = property['id'];

      if (id is int) {
        return id;
      }

      return int.tryParse(
        id?.toString() ?? '',
      );
    }

    final dynamic id = message['propertyId'];

    if (id is int) {
      return id;
    }

    return int.tryParse(
      id?.toString() ?? '',
    );
  }

  // ------------------------------------------------------------
  // CHECK WHETHER MESSAGE BELONGS TO THIS CONVERSATION
  // ------------------------------------------------------------

  bool belongsToConversation(
    Map<String, dynamic> message,
  ) {
    final int? senderId =
        getSenderId(message);

    final int? receiverId =
        getReceiverId(message);

    final int? messagePropertyId =
        getMessagePropertyId(message);

    if (senderId == null ||
        receiverId == null ||
        messagePropertyId == null) {
      return false;
    }

    final bool usersMatch =
        (senderId == widget.currentUserId &&
                receiverId == widget.ownerId) ||
            (senderId == widget.ownerId &&
                receiverId == widget.currentUserId);

    final bool propertyMatches =
        messagePropertyId == widget.propertyId;

    return usersMatch && propertyMatches;
  }

  // ------------------------------------------------------------
  // LOAD CONVERSATION
  // ------------------------------------------------------------

  Future<void> loadMessages() async {
    try {
      final Uri url = Uri.parse(
        'https://properties-anywhere-backend.onrender.com/api/messages/conversation'
        '?user1Id=${widget.currentUserId}'
        '&user2Id=${widget.ownerId}'
        '&propertyId=${widget.propertyId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        final List<Map<String, dynamic>>
            filteredMessages = [];

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final Map<String, dynamic> message =
                  Map<String, dynamic>.from(item);

              if (belongsToConversation(message)) {
                filteredMessages.add(message);
              }
            }
          }
        }

        // Oldest -> newest.
        filteredMessages.sort((a, b) {
          final String dateA =
              a['sentAt']?.toString() ?? '';

          final String dateB =
              b['sentAt']?.toString() ?? '';

          return dateA.compareTo(dateB);
        });

        if (mounted) {
          setState(() {
            messages = filteredMessages;
            isLoading = false;
          });

          scrollToBottom();
        }
      } else {
        debugPrint(
          'Error loading conversation: '
          '${response.statusCode}',
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Error loading conversation: $error',
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MARK CONVERSATION AS READ
  // ------------------------------------------------------------

  Future<void> markConversationAsRead() async {
    try {
      final Uri url = Uri.parse(
        'https://properties-anywhere-backend.onrender.com/api/messages/read'
        '?receiverId=${widget.currentUserId}'
        '&senderId=${widget.ownerId}'
        '&propertyId=${widget.propertyId}',
      );

      final response = await http.put(url);

      debugPrint(
        'Mark conversation as read: '
        '${response.statusCode}',
      );

      debugPrint(
        'Messages marked as read: ${response.body}',
      );
    } catch (error) {
      debugPrint(
        'Error marking conversation as read: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // SEND MESSAGE
  // ------------------------------------------------------------

  Future<void> sendMessage() async {
    final String content =
        messageController.text.trim();

    if (content.isEmpty || isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final Uri url = Uri.parse(
        'https://properties-anywhere-backend.onrender.com/api/messages'
        '?senderId=${widget.currentUserId}'
        '&receiverId=${widget.ownerId}'
        '&propertyId=${widget.propertyId}',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          final Map<String, dynamic> newMessage =
              Map<String, dynamic>.from(decoded);

          if (belongsToConversation(newMessage)) {
            messageController.clear();

            if (mounted) {
              setState(() {
                messages.add(newMessage);
              });

              scrollToBottom();
            }
          }
        }
      } else {
        debugPrint(
          'Send message failed: '
          '${response.statusCode} ${response.body}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not send message.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint(
        'Error sending message: $error',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not connect to the server.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // SCROLL TO BOTTOM
  // ------------------------------------------------------------

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // ------------------------------------------------------------
  // FORMAT MESSAGE TIME
  // ------------------------------------------------------------

  String formatTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text = value.toString();

    if (text.contains('T')) {
      final List<String> parts =
          text.split('T');

      if (parts.length > 1) {
        final String time = parts[1];

        if (time.length >= 5) {
          return time.substring(0, 5);
        }
      }
    }

    return '';
  }

  // ------------------------------------------------------------
  // AVATAR
  // ------------------------------------------------------------

  Widget buildAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFDCE9FF),
        ),
      ),
      child: const Icon(
        Icons.person_outline,
        color: primaryBlue,
        size: 23,
      ),
    );
  }

  // ------------------------------------------------------------
  // MESSAGE BUBBLE
  // ------------------------------------------------------------

  Widget buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
  ) {
    final int? senderId =
        getSenderId(message);

    final bool isMyMessage =
        senderId == widget.currentUserId;

    final String content =
        message['content']?.toString() ?? '';

    final String time =
        formatTime(message['sentAt']);

    return Padding(
      padding: EdgeInsets.only(
        left: isMyMessage ? 55 : 0,
        right: isMyMessage ? 0 : 55,
        bottom: 10,
      ),
      child: Align(
        alignment: isMyMessage
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            15,
            11,
            12,
            8,
          ),
          decoration: BoxDecoration(
            color: isMyMessage
                ? primaryBlue
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(
                isMyMessage ? 18 : 5,
              ),
              bottomRight: Radius.circular(
                isMyMessage ? 5 : 18,
              ),
            ),
            border: isMyMessage
                ? null
                : Border.all(
                    color: borderColor,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.35,
                    color: isMyMessage
                        ? Colors.white
                        : textColor,
                  ),
                ),
              ),

              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),

                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMyMessage
                        ? Colors.white70
                        : secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY CHAT
  // ------------------------------------------------------------

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 34,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Start a conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Send ${widget.ownerName} a message '
              'about this property.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // --------------------------------------------------------
      // HEADER
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: textColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            buildAvatar(),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ownerName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    widget.propertyTitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --------------------------------------------------------
      // CHAT BODY + INPUT
      // --------------------------------------------------------

      body: Column(
        children: [
          // Property context strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 17,
                  color: primaryBlue,
                ),

                const SizedBox(width: 7),

                const Text(
                  'Regarding:',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    widget.propertyTitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryBlue,
                    ),
                  )
                : messages.isEmpty
                    ? buildEmptyState()
                    : ListView.builder(
                        controller:
                            scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          18,
                        ),
                        itemCount:
                            messages.length,
                        itemBuilder:
                            (context, index) {
                          return buildMessageBubble(
                            context,
                            messages[index],
                          );
                        },
                      ),
          ),

          // ------------------------------------------------------
          // MESSAGE INPUT
          // ------------------------------------------------------

          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(
                    color: borderColor,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.04),
                    blurRadius: 10,
                    offset:
                        const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          messageController,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      minLines: 1,
                      maxLines: 5,

                      decoration:
                          InputDecoration(
                        hintText:
                            'Write a message...',
                        hintStyle:
                            const TextStyle(
                          color:
                              Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),

                        filled: true,
                        fillColor:
                            backgroundColor,

                        prefixIcon: const Icon(
                          Icons
                              .chat_outlined,
                          color:
                              secondaryTextColor,
                          size: 21,
                        ),

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),

                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),

                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                primaryBlue,
                            width: 1,
                          ),
                        ),
                      ),

                      onSubmitted: (_) {
                        sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 48,
                    height: 48,

                    decoration:
                        const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      onPressed: isSending
                          ? null
                          : sendMessage,

                      icon: isSending
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
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
}