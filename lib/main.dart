import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'add_listing_screen.dart';
import 'property_details_screen.dart';
import 'my_listings_screen.dart';
import 'messages_screen.dart';

void main() {
  runApp(const PropertiesAnywhereApp());
}

class PropertiesAnywhereApp extends StatelessWidget {
  const PropertiesAnywhereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PropertiesAnywhere',
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController cityController =
      TextEditingController();

  List<Map<String, dynamic>> properties = [];

  bool isLoading = false;

  // ------------------------------------------------------------
  // UNREAD MESSAGE COUNT
  // ------------------------------------------------------------

  int unreadMessageCount = 0;

  Timer? unreadTimer;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    loadUnreadCount();

    // Check every 5 seconds while HomeScreen is open.
    unreadTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadUnreadCount();
      },
    );
  }

  // ------------------------------------------------------------
  // LOAD UNREAD COUNT
  //
  // Backend:
  //
  // GET
  // /api/messages/unread/count/{userId}
  //
  // ------------------------------------------------------------

  Future<void> loadUnreadCount() async {
    try {
      final Uri url = Uri.parse(
        'https://properties-anywhere-backend.onrender.com/api/messages/unread/count/${widget.userId}',
      );

      final response =
          await http.get(url);

      if (response.statusCode == 200) {
        final int? count =
            int.tryParse(
          response.body.trim(),
        );

        if (count != null &&
            mounted) {
          setState(() {
            unreadMessageCount = count;
          });
        }
      } else {
        debugPrint(
          'Unread count error: '
          '${response.statusCode}',
        );
      }
    } catch (error) {
      debugPrint(
        'Error loading unread count: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // SEARCH PROPERTIES
  // ------------------------------------------------------------

  Future<void> searchProperties() async {
    final String city =
        cityController.text.trim();

    if (city.isEmpty) {
      setState(() {
        properties = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final Uri url = Uri.parse(
      'https://properties-anywhere-backend.onrender.com/api/properties'
      '?city=${Uri.encodeComponent(city)}',
    );

    try {
      final http.Response response =
          await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is List) {
          final List<Map<String, dynamic>>
              loadedProperties = [];

          for (final dynamic item
              in decoded) {
            if (item is Map) {
              loadedProperties.add(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            }
          }

          if (mounted) {
            setState(() {
              properties =
                  loadedProperties;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              properties = [];
            });
          }
        }
      } else {
        debugPrint(
          'Error searching properties: '
          '${response.statusCode}',
        );

        debugPrint(response.body);

        if (mounted) {
          setState(() {
            properties = [];
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Connection error: $error',
      );

      if (mounted) {
        setState(() {
          properties = [];
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ------------------------------------------------------------
  // ADD LISTING
  // ------------------------------------------------------------

  void openAddListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddListingScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MY LISTINGS
  // ------------------------------------------------------------

  void openMyListings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyListingsScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN MESSAGES
  //
  // IMPORTANT:
  //
  // We DO NOT change unreadMessageCount here.
  //
  // Simply opening MessagesScreen does NOT mark messages
  // as read.
  //
  // Only opening the specific ChatScreen marks that
  // conversation as read.
  //
  // After returning, we ask backend for the real count.
  // ------------------------------------------------------------

  Future<void> openMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MessagesScreen(
          userId: widget.userId,
        ),
      ),
    );

    // User returned from Messages.
    //
    // Refresh the actual backend count.
    await loadUnreadCount();
  }

  // ------------------------------------------------------------
  // PROPERTY DETAILS
  // ------------------------------------------------------------

  void openPropertyDetails(
    Map<String, dynamic> property,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PropertyDetailsScreen(
          property: property,
          currentUserId:
              widget.userId,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    unreadTimer?.cancel();

    cityController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // MESSAGE BADGE
  // ------------------------------------------------------------

  Widget buildMessageBadge() {
    if (unreadMessageCount <= 0) {
      return const SizedBox.shrink();
    }

    final String text =
        unreadMessageCount > 99
            ? '99+'
            : unreadMessageCount
                .toString();

    return Positioned(
      right: -4,
      top: -4,
      child: Container(
        constraints:
            const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 2,
        ),
        decoration:
            BoxDecoration(
          color: Colors.red,
          shape:
              BoxShape.circle,
          border:
              Border.all(
            color: Theme.of(context)
                .scaffoldBackgroundColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PropertiesAnywhere',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(
              Icons.list_alt,
            ),
            tooltip:
                'My Listings',
            onPressed:
                openMyListings,
          ),

          IconButton(
            icon:
                const Icon(
              Icons.add_home_outlined,
            ),
            tooltip:
                'Add Listing',
            onPressed:
                openAddListing,
          ),

          IconButton(
            icon:
                const Icon(
              Icons.logout,
            ),
            tooltip:
                'Logout',
            onPressed:
                logout,
          ),
        ],
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),

            Text(
              'Welcome, ${widget.userName}!',
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Find your next home.',
              style:
                  TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Search for rooms and properties by city.',
            ),

            const SizedBox(
              height: 25,
            ),

            TextField(
              controller:
                  cityController,
              decoration:
                  const InputDecoration(
                labelText:
                    'City',
                hintText:
                    'e.g. Munich',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(
                  Icons.location_city,
                ),
              ),
              onSubmitted: (_) {
                searchProperties();
              },
            ),

            const SizedBox(
              height: 15,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : searchProperties,
                child:
                    isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Text(
                            'Search',
                          ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            Expanded(
              child:
                  properties.isEmpty
                      ? const Center(
                          child: Text(
                            'Search for a city to see properties.',
                            textAlign:
                                TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              properties.length,
                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
                            final Map<
                                    String,
                                    dynamic>
                                property =
                                properties[index];

                            final String
                                imageUrl =
                                property[
                                            'imageUrl']
                                        ?.toString() ??
                                    '';

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 20,
                              ),
                              child:
                                  InkWell(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                                onTap: () {
                                  openPropertyDetails(
                                    property,
                                  );
                                },
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    if (imageUrl
                                        .isNotEmpty)
                                      Image.network(
                                        imageUrl,
                                        height:
                                            180,
                                        width:
                                            double
                                                .infinity,
                                        fit:
                                            BoxFit
                                                .cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height:
                                                180,
                                            width:
                                                double
                                                    .infinity,
                                            color: Colors
                                                .grey
                                                .shade300,
                                            child:
                                                const Center(
                                              child:
                                                  Icon(
                                                Icons.home,
                                                size:
                                                    60,
                                                color:
                                                    Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Container(
                                        height:
                                            180,
                                        width:
                                            double
                                                .infinity,
                                        color: Colors
                                            .grey
                                            .shade300,
                                        child:
                                            const Center(
                                          child:
                                              Icon(
                                            Icons.home,
                                            size:
                                                60,
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ),

                                    ListTile(
                                      title:
                                          Text(
                                        property[
                                                    'title']
                                                ?.toString() ??
                                            'No title',
                                      ),
                                      subtitle:
                                          Text(
                                        '${property['city']?.toString() ?? ''}'
                                        ' • '
                                        '${property['address']?.toString() ?? ''}',
                                      ),
                                      trailing:
                                          Text(
                                        '€${property['rent']?.toString() ?? '0'}',
                                      ),
                                    ),

                                    if (property[
                                                'description'] !=
                                            null &&
                                        property[
                                                'description']
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .fromLTRB(
                                          16,
                                          0,
                                          16,
                                          16,
                                        ),
                                        child:
                                            Text(
                                          property[
                                                  'description']
                                              .toString(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // ----------------------------------------------------------
      // FOOTER MESSAGE BUTTON + UNREAD COUNT
      // ----------------------------------------------------------

      bottomNavigationBar:
          SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child:
              Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  IconButton(
                    iconSize: 30,
                    tooltip:
                        unreadMessageCount >
                                0
                            ? '$unreadMessageCount new messages'
                            : 'Messages',
                    icon:
                        const Icon(
                      Icons.message_outlined,
                    ),
                    onPressed:
                        openMessages,
                  ),

                  buildMessageBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}