import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const MyListingsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MyListingsScreen> createState() =>
      _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Map<String, dynamic>> properties = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  // ------------------------------------------------------------
  // LOAD USER LISTINGS
  // ------------------------------------------------------------

  Future<void> loadListings() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final Uri url = Uri.parse(
      'http://10.0.2.2:8080/api/properties/user/${widget.userId}',
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

          for (final dynamic item in decoded) {
            if (item is Map) {
              loadedProperties.add(
                Map<String, dynamic>.from(item),
              );
            }
          }

          if (mounted) {
            setState(() {
              properties = loadedProperties;
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
          'Error loading listings: '
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // OPEN EDIT LISTING
  // ------------------------------------------------------------

  Future<void> openEditListing(
    Map<String, dynamic> property,
  ) async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditListingScreen(
          property: property,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadListings();
    }
  }

  // ------------------------------------------------------------
  // IMAGE PLACEHOLDER
  // ------------------------------------------------------------

  Widget buildImagePlaceholder() {
    return Container(
      height: 210,
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(
          Icons.home_outlined,
          size: 70,
          color: Color(0xFF93C5FD),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROPERTY IMAGE
  // ------------------------------------------------------------

  Widget buildPropertyImage(
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return buildImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      height: 210,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) {
        return buildImagePlaceholder();
      },
      loadingBuilder:
          (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          height: 210,
          width: double.infinity,
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2563EB),
            ),
          ),
        );
      },
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
                borderRadius:
                    BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 44,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No listings yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Properties you create will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LISTING CARD
  // ------------------------------------------------------------

  Widget buildListingCard(
    Map<String, dynamic> property,
  ) {
    final String imageUrl =
        property['imageUrl']?.toString() ?? '';

    final String title =
        property['title']?.toString().trim() ?? '';

    final String city =
        property['city']?.toString().trim() ?? '';

    final String address =
        property['address']?.toString().trim() ?? '';

    final String rent =
        property['rent']?.toString() ?? '0';

    final String description =
        property['description']
                ?.toString()
                .trim() ??
            '';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // IMAGE
          // --------------------------------------------------

          Stack(
            children: [
              buildPropertyImage(imageUrl),

              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '€$rent / month',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --------------------------------------------------
          // DETAILS
          // --------------------------------------------------

          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty
                      ? title
                      : 'Untitled property',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color: Color(0xFF171717),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // LOCATION

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 19,
                      color: Color(0xFF2563EB),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        city.isNotEmpty &&
                                address.isNotEmpty
                            ? '$city • $address'
                            : city.isNotEmpty
                                ? city
                                : address.isNotEmpty
                                    ? address
                                    : 'Location unavailable',
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color:
                              Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // DESCRIPTION

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  Text(
                    description,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 17),

                const Divider(
                  height: 1,
                  color: Color(0xFFE5E7EB),
                ),

                const SizedBox(height: 15),

                // EDIT BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      openEditListing(
                        property,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      'Edit Listing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2563EB),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF171717),
        elevation: 0,
        surfaceTintColor: Colors.white,

        title: const Text(
          'My Listings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                isLoading
                    ? null
                    : loadListings,
            icon: const Icon(
              Icons.refresh_outlined,
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
          : properties.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadListings,
                  color: const Color(0xFF2563EB),
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
                        child: buildEmptyState(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadListings,
                  color: const Color(0xFF2563EB),
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      30,
                    ),
                    itemCount:
                        properties.length,
                    itemBuilder:
                        (context, index) {
                      return buildListingCard(
                        properties[index],
                      );
                    },
                  ),
                ),
    );
  }
}