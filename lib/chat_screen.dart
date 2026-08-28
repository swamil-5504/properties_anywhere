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

  @override
  void initState() {
    super.initState();

    // Load the conversation first.
    // Then mark incoming messages as read.
    initializeChat();
  }

  // ------------------------------------------------------------
  // INITIALIZE CHAT
  // ------------------------------------------------------------

  Future<void> initializeChat() async {
    await loadMessages();

    // IMPORTANT:
    // Once the user has opened this chat, all unread messages
    // sent by the other user for this property are marked read.
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
        'http://10.0.2.2:8080/api/messages/conversation'
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
        'http://10.0.2.2:8080/api/messages/read'
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
        'http://10.0.2.2:8080/api/messages'
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

    return Align(
      alignment: isMyMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
                  0.75,
        ),
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMyMessage
              ? Theme.of(context)
                  .colorScheme
                  .primary
              : Colors.grey.shade300,
          borderRadius:
              BorderRadius.circular(18),
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
                  fontSize: 16,
                  color: isMyMessage
                      ? Colors.white
                      : Colors.black,
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
                      : Colors.black54,
                ),
              ),
            ],
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.ownerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            Text(
              widget.propertyTitle,
              style: const TextStyle(
                fontSize: 12,
              ),
              overflow:
                  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\n'
                          'Start the conversation.',
                          textAlign:
                              TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller:
                            scrollController,
                        padding:
                            const EdgeInsets.all(
                                16),
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

          // ----------------------------------------------------
          // MESSAGE INPUT
          // ----------------------------------------------------

          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8,
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
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(24),
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) {
                        sendMessage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: IconButton(
                      onPressed: isSending
                          ? null
                          : sendMessage,
                      icon: isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
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