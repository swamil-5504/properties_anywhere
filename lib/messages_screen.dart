import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final int userId;

  const MessagesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> conversations = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  // ------------------------------------------------------------
  // LOAD ALL MESSAGES
  // ------------------------------------------------------------

  Future<void> loadMessages() async {
    try {
      final Uri url = Uri.parse(
        'https://properties-anywhere-backend.onrender.com/api/messages/user/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          final List<Map<String, dynamic>> allMessages = [];

          for (final item in decoded) {
            if (item is Map) {
              allMessages.add(
                Map<String, dynamic>.from(item),
              );
            }
          }

          final List<Map<String, dynamic>> grouped =
              groupConversations(allMessages);

          if (mounted) {
            setState(() {
              conversations = grouped;
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              conversations = [];
              isLoading = false;
            });
          }
        }
      } else {
        debugPrint(
          'Error loading messages: ${response.statusCode}',
        );

        if (mounted) {
          setState(() {
            conversations = [];
            isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Error loading messages: $error',
      );

      if (mounted) {
        setState(() {
          conversations = [];
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // GROUP MESSAGES
  //
  // One conversation =
  //
  // other user + property
  //
  // The newest message becomes the preview.
  //
  // IMPORTANT:
  // _hasUnread remains true if ANY message in the
  // conversation is unread.
  // ------------------------------------------------------------

  List<Map<String, dynamic>> groupConversations(
    List<Map<String, dynamic>> allMessages,
  ) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final message in allMessages) {
      final int? otherUserId = getOtherUserId(message);
      final int? propertyId = getPropertyId(message);

      if (otherUserId == null || propertyId == null) {
        continue;
      }

      final String key = '${otherUserId}_$propertyId';

      final bool messageUnread = isMessageUnread(message);

      if (!grouped.containsKey(key)) {
        final Map<String, dynamic> conversation =
            Map<String, dynamic>.from(message);

        conversation['_hasUnread'] = messageUnread;

        grouped[key] = conversation;
      } else {
        final Map<String, dynamic> existing =
            grouped[key]!;

        // If ANY message in this conversation is unread,
        // keep the conversation marked unread.
        if (messageUnread) {
          existing['_hasUnread'] = true;
        }

        final DateTime? existingDate =
            parseDate(existing['sentAt']);

        final DateTime? currentDate =
            parseDate(message['sentAt']);

        // Keep newest message as preview.
        if (currentDate != null &&
            (existingDate == null ||
                currentDate.isAfter(existingDate))) {
          final bool hadUnread =
              existing['_hasUnread'] == true;

          final Map<String, dynamic> newest =
              Map<String, dynamic>.from(message);

          newest['_hasUnread'] =
              hadUnread || messageUnread;

          grouped[key] = newest;
        }
      }
    }

    final List<Map<String, dynamic>> result =
        grouped.values.toList();

    // Newest conversations first.
    result.sort((a, b) {
      final DateTime? dateA =
          parseDate(a['sentAt']);

      final DateTime? dateB =
          parseDate(b['sentAt']);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    return result;
  }

  // ------------------------------------------------------------
  // CHECK ONE MESSAGE
  //
  // A message is unread ONLY when:
  //
  // receiver == current user
  // AND
  // isRead == false
  //
  // Sending your own message does NOT make it unread.
  // ------------------------------------------------------------

  bool isMessageUnread(
    Map<String, dynamic> message,
  ) {
    final dynamic receiver =
        message['receiver'];

    if (receiver is! Map) {
      return false;
    }

    final String receiverId =
        receiver['id']?.toString() ?? '';

    final bool belongsToCurrentUser =
        receiverId == widget.userId.toString();

    final dynamic readValue =
        message['isRead'];

    final bool isRead =
        readValue == true ||
        readValue?.toString().toLowerCase() == 'true';

    return belongsToCurrentUser && !isRead;
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ------------------------------------------------------------
  // OTHER USER NAME
  // ------------------------------------------------------------

  String getOtherUserName(
    Map<String, dynamic> message,
  ) {
    final dynamic sender =
        message['sender'];

    final dynamic receiver =
        message['receiver'];

    if (sender is Map &&
        sender['id']?.toString() !=
            widget.userId.toString()) {
      return sender['name']?.toString() ?? '';
    }

    if (receiver is Map &&
        receiver['id']?.toString() !=
            widget.userId.toString()) {
      return receiver['name']?.toString() ?? '';
    }

    return '';
  }

  // ------------------------------------------------------------
  // OTHER USER ID
  // ------------------------------------------------------------

  int? getOtherUserId(
    Map<String, dynamic> message,
  ) {
    final dynamic sender =
        message['sender'];

    final dynamic receiver =
        message['receiver'];

    if (sender is Map &&
        sender['id']?.toString() !=
            widget.userId.toString()) {
      return int.tryParse(
        sender['id']?.toString() ?? '',
      );
    }

    if (receiver is Map &&
        receiver['id']?.toString() !=
            widget.userId.toString()) {
      return int.tryParse(
        receiver['id']?.toString() ?? '',
      );
    }

    return null;
  }

  // ------------------------------------------------------------
  // PROPERTY ID
  // ------------------------------------------------------------

  int? getPropertyId(
    Map<String, dynamic> message,
  ) {
    final dynamic property =
        message['property'];

    if (property is Map) {
      return int.tryParse(
        property['id']?.toString() ?? '',
      );
    }

    return int.tryParse(
      message['propertyId']?.toString() ?? '',
    );
  }

  // ------------------------------------------------------------
  // PROPERTY TITLE
  // ------------------------------------------------------------

  String getPropertyTitle(
    Map<String, dynamic> message,
  ) {
    final dynamic property =
        message['property'];

    if (property is Map) {
      return property['title']?.toString() ?? '';
    }

    return '';
  }

  // ------------------------------------------------------------
  // FORMAT TIME
  // ------------------------------------------------------------

  String getLatestMessageTime(
    Map<String, dynamic> message,
  ) {
    final DateTime? date =
        parseDate(message['sentAt']);

    if (date == null) {
      return '';
    }

    final DateTime localDate =
        date.toLocal();

    final String hour =
        localDate.hour.toString().padLeft(2, '0');

    final String minute =
        localDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ------------------------------------------------------------
  // OPEN SPECIFIC CHAT
  //
  // IMPORTANT:
  //
  // MessagesScreen itself DOES NOT mark messages as read.
  //
  // ChatScreen does that only after the user opens
  // the specific conversation.
  // ------------------------------------------------------------

  void openChat(
    Map<String, dynamic> message,
  ) {
    final int? otherUserId =
        getOtherUserId(message);

    final int? propertyId =
        getPropertyId(message);

    final String otherUserName =
        getOtherUserName(message);

    final String propertyTitle =
        getPropertyTitle(message);

    if (otherUserId == null ||
        propertyId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId:
              widget.userId,
          ownerId:
              otherUserId,
          ownerName:
              otherUserName.isNotEmpty
                  ? otherUserName
                  : 'User',
          propertyId:
              propertyId,
          propertyTitle:
              propertyTitle,
        ),
      ),
    ).then((_) {
      // ChatScreen has now returned.
      //
      // Reload the messages so the red dot disappears
      // ONLY if ChatScreen actually marked them as read.
      loadMessages();
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No messages yet.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your conversations will appear here.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadMessages,
                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    itemCount:
                        conversations.length,

                    separatorBuilder:
                        (context, index) {
                      return const Divider(
                        height: 1,
                        indent: 76,
                      );
                    },

                    itemBuilder:
                        (context, index) {
                      final Map<String, dynamic>
                          message =
                          conversations[index];

                      final String
                          otherUserName =
                          getOtherUserName(
                        message,
                      );

                      final String messageText =
                          message['content']
                                  ?.toString() ??
                              '';

                      final String
                          propertyTitle =
                          getPropertyTitle(
                        message,
                      );

                      final bool unread =
                          message['_hasUnread'] ==
                              true;

                      final String time =
                          getLatestMessageTime(
                        message,
                      );

                      return ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        // ------------------------------------------------
                        // PROFILE + RED DOT
                        // ------------------------------------------------

                        leading: Stack(
                          clipBehavior:
                              Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 27,
                              child: Text(
                                otherUserName
                                        .isNotEmpty
                                    ? otherUserName[0]
                                        .toUpperCase()
                                    : '?',
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            if (unread)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.red,
                                    shape:
                                        BoxShape.circle,
                                    border:
                                        Border.all(
                                      color:
                                          Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // ------------------------------------------------
                        // USER + TIME
                        // ------------------------------------------------

                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherUserName
                                        .isNotEmpty
                                    ? otherUserName
                                    : 'User',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      unread
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                ),
                              ),
                            ),

                            if (time.isNotEmpty)
                              Text(
                                time,
                                style:
                                    TextStyle(
                                  fontSize: 11,
                                  color: unread
                                      ? Theme.of(
                                          context,
                                        )
                                          .colorScheme
                                          .primary
                                      : Colors.grey,
                                  fontWeight:
                                      unread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),

                        // ------------------------------------------------
                        // PROPERTY + MESSAGE
                        // ------------------------------------------------

                        subtitle:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              if (propertyTitle
                                  .isNotEmpty)
                                Text(
                                  propertyTitle,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade600,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                messageText,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      unread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color: unread
                                      ? Colors.black87
                                      : Colors.grey
                                          .shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        trailing:
                            const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),

                        onTap: () {
                          openChat(message);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}