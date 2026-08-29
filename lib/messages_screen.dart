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
  State<MessagesScreen> createState() =>
      _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> conversations = [];

  bool isLoading = true;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

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
        'http://10.0.2.2:8080/api/messages/user/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is List) {
          final List<Map<String, dynamic>>
              allMessages = [];

          for (final item in decoded) {
            if (item is Map) {
              allMessages.add(
                Map<String, dynamic>.from(item),
              );
            }
          }

          final List<Map<String, dynamic>>
              grouped =
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
          'Error loading messages: '
          '${response.statusCode}',
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
  // GROUP CONVERSATIONS
  // ------------------------------------------------------------

  List<Map<String, dynamic>> groupConversations(
    List<Map<String, dynamic>> allMessages,
  ) {
    final Map<String, Map<String, dynamic>>
        grouped = {};

    for (final message in allMessages) {
      final int? otherUserId =
          getOtherUserId(message);

      final int? propertyId =
          getPropertyId(message);

      if (otherUserId == null ||
          propertyId == null) {
        continue;
      }

      final String key =
          '${otherUserId}_$propertyId';

      final bool messageUnread =
          isMessageUnread(message);

      if (!grouped.containsKey(key)) {
        final Map<String, dynamic> conversation =
            Map<String, dynamic>.from(message);

        conversation['_hasUnread'] =
            messageUnread;

        grouped[key] = conversation;
      } else {
        final Map<String, dynamic> existing =
            grouped[key]!;

        if (messageUnread) {
          existing['_hasUnread'] = true;
        }

        final DateTime? existingDate =
            parseDate(existing['sentAt']);

        final DateTime? currentDate =
            parseDate(message['sentAt']);

        if (currentDate != null &&
            (existingDate == null ||
                currentDate.isAfter(
                  existingDate,
                ))) {
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
  // CHECK UNREAD
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
        receiverId ==
            widget.userId.toString();

    final dynamic readValue =
        message['isRead'];

    final bool isRead =
        readValue == true ||
        readValue
                ?.toString()
                .toLowerCase() ==
            'true';

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
        localDate.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        localDate.minute
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute';
  }

  // ------------------------------------------------------------
  // AVATAR
  // ------------------------------------------------------------

  Widget buildAvatar(
    String name,
    bool unread,
  ) {
    final String initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDCE8FF),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),

        if (unread)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // OPEN CHAT
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
        builder: (context) =>
            ChatScreen(
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
      loadMessages();
    });
  }

  // ------------------------------------------------------------
  // CONVERSATION CARD
  // ------------------------------------------------------------

  Widget buildConversationCard(
    BuildContext context,
    Map<String, dynamic> message,
  ) {
    final String otherUserName =
        getOtherUserName(message);

    final String messageText =
        message['content']?.toString() ?? '';

    final String propertyTitle =
        getPropertyTitle(message);

    final bool unread =
        message['_hasUnread'] == true;

    final String time =
        getLatestMessageTime(message);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          openChat(message);
        },
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: unread
                ? const Color(0xFFF8FAFF)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? const Color(0xFFD9E6FF)
                  : const Color(0xFFE8EAED),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // AVATAR
              // ------------------------------------------------

              buildAvatar(
                otherUserName,
                unread,
              ),

              const SizedBox(width: 13),

              // ------------------------------------------------
              // MESSAGE CONTENT
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName.isNotEmpty
                                ? otherUserName
                                : 'User',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color:
                                  const Color(0xFF171717),
                            ),
                          ),
                        ),

                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: unread
                                  ? const Color(
                                      0xFF2563EB,
                                    )
                                  : const Color(
                                      0xFF9CA3AF,
                                    ),
                            ),
                          ),
                      ],
                    ),

                    if (propertyTitle
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.home_outlined,
                            size: 14,
                            color:
                                Color(0xFF6B7280),
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              propertyTitle,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w500,
                                color:
                                    Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 6),

                    Text(
                      messageText.isNotEmpty
                          ? messageText
                          : 'No message',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: unread
                            ? const Color(
                                0xFF374151,
                              )
                            : const Color(
                                0xFF6B7280,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------
              // CHEVRON
              // ------------------------------------------------

              const Icon(
                Icons.chevron_right,
                size: 22,
                color: Color(0xFFB0B5BD),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 42,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'When you message a property owner, '
              'your conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final int unreadCount =
        conversations.where(
      (conversation) =>
          conversation['_hasUnread'] == true,
    ).length;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        automaticallyImplyLeading: true,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),

            if (unreadCount > 0)
              Text(
                '$unreadCount unread '
                '${unreadCount == 1 ? 'conversation' : 'conversations'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2563EB),
                ),
              ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadMessages,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : conversations.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadMessages,
                  color:
                      const Color(0xFF2563EB),
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(context)
                                    .size
                                    .height *
                                0.65,
                        child:
                            buildEmptyState(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadMessages,
                  color:
                      const Color(0xFF2563EB),
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      25,
                    ),

                    itemCount:
                        conversations.length,

                    itemBuilder:
                        (context, index) {
                      return buildConversationCard(
                        context,
                        conversations[index],
                      );
                    },
                  ),
                ),
    );
  }
}