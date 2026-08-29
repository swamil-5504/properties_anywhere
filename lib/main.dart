import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'add_listing_screen.dart';
import 'property_details_screen.dart';
import 'my_listings_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

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

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor:
            const Color(0xFFF7F8FA),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF171717),
          elevation: 0,
        ),

        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.5,
            ),
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,

            minimumSize:
                const Size.fromHeight(50),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
        ),
      ),

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

  int unreadMessageCount = 0;

  Timer? unreadTimer;

  @override
  void initState() {
    super.initState();

    loadUnreadCount();

    unreadTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadUnreadCount();
      },
    );
  }

  // ------------------------------------------------------------
  // UNREAD MESSAGES
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
            int.tryParse(response.body.trim());

        if (count != null && mounted) {
          setState(() {
            unreadMessageCount = count;
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Error loading unread count: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // SEARCH
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
      final response =
          await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is List) {
          final List<Map<String, dynamic>>
              loadedProperties = [];

          for (final dynamic item in decoded) {
            if (item is Map) {
              loadedProperties.add(
                Map<String, dynamic>.from(item),
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
          'Search error: ${response.statusCode}',
        );

        if (mounted) {
          setState(() {
            properties = [];
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Search connection error: $error',
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
  // MESSAGES
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

    await loadUnreadCount();
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
  // CREATE LISTING
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
  // PROFILE
  // ------------------------------------------------------------

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProfileScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
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
          currentUserId: widget.userId,
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

  Widget messageBadge() {
    if (unreadMessageCount <= 0) {
      return const SizedBox.shrink();
    }

    final String text =
        unreadMessageCount > 99
            ? '99+'
            : unreadMessageCount.toString();

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        constraints:
            const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,

            errorBuilder:
                (context, error, stackTrace) {
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEFF6FF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Color(0xFF2563EB),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          const Text(
            'PropertiesAnywhere',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------

  Widget buildBottomNavigation() {
    return SafeArea(
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          children: [
            _bottomItem(
              icon: Icons.message_outlined,
              label: 'Messages',
              badge: true,
              onTap: openMessages,
            ),

            _bottomItem(
              icon: Icons.list_alt_outlined,
              label: 'My Listings',
              onTap: openMyListings,
            ),

            _bottomItem(
              icon: Icons.add_home_outlined,
              label: 'Create',
              onTap: openAddListing,
            ),

            _bottomItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: openProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 23,
                    color:
                        const Color(0xFF4B5563),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    label,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color:
                          Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),

            if (badge) messageBadge(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROPERTY CARD
  // ------------------------------------------------------------

  Widget buildPropertyCard(
    Map<String, dynamic> property,
  ) {
    final String imageUrl =
        property['imageUrl']
                ?.toString() ??
            '';

    final String title =
        property['title']
                ?.toString() ??
            'No title';

    final String city =
        property['city']
                ?.toString() ??
            '';

    final String address =
        property['address']
                ?.toString() ??
            '';

    final String rent =
        property['rent']
                ?.toString() ??
            '0';

    final String description =
        property['description']
                ?.toString()
                .trim() ??
            '';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openPropertyDetails(property);
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // IMAGE
            SizedBox(
              height: 190,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _imagePlaceholder();
                      },
                    )
                  : _imagePlaceholder(),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF171717),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        '€$rent',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color:
                            Color(0xFF6B7280),
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          '$city${address.isNotEmpty ? ' • $address' : ''}',
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),

                    Text(
                      description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            Color(0xFF4B5563),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF2563EB),
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Icon(
                        Icons.arrow_forward,
                        size: 15,
                        color:
                            Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(
          Icons.home_outlined,
          size: 65,
          color: Color(0xFF9CA3AF),
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
      // IMPORTANT:
      // Header is separate from body.
      // No profile/message icon here.
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),

            // Only this part scrolls.
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Find your next home.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Search rooms and properties by city.',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SEARCH
                    TextField(
                      controller:
                          cityController,
                      textInputAction:
                          TextInputAction.search,
                      onSubmitted: (_) {
                        searchProperties();
                      },
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Search by city',
                        prefixIcon:
                            Icon(
                          Icons.search,
                          color:
                              Color(0xFF6B7280),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : searchProperties,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.search,
                              ),
                        label: Text(
                          isLoading
                              ? 'Searching...'
                              : 'Search Properties',
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    if (properties.isEmpty)
                      _emptyState()
                    else
                      Column(
                        children:
                            properties.map(
                          buildPropertyCard,
                        ).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed bottom navigation.
      bottomNavigationBar:
          buildBottomNavigation(),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 32,
              color:
                  Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Find your next place',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Enter a city above to discover available properties.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}