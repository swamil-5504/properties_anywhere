import 'package:flutter/material.dart';

import 'chat_screen.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  final int currentUserId;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
    required this.currentUserId,
  });

  int? getOwnerId() {
    final dynamic user = property['user'];

    if (user is Map) {
      return int.tryParse(
        user['id']?.toString() ?? '',
      );
    }

    return null;
  }

  String getOwnerName() {
    final dynamic user = property['user'];

    if (user is Map) {
      final dynamic name = user['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        property['imageUrl']?.toString() ?? '';

    final String ownerName = getOwnerName();

    final int? ownerId = getOwnerId();

    final int? propertyId = int.tryParse(
      property['id']?.toString() ?? '',
    );

    final String propertyTitle =
        property['title']?.toString() ?? 'Property';

    final String city =
        property['city']?.toString() ?? '';

    final String address =
        property['address']?.toString() ?? '';

    final String description =
        property['description']?.toString().trim() ?? '';

    final String rent =
        property['rent']?.toString() ?? '0';

    final bool canMessage =
        ownerId != null &&
        propertyId != null &&
        ownerId != currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: CustomScrollView(
        slivers: [
          // --------------------------------------------------
          // PROPERTY IMAGE
          // --------------------------------------------------

          SliverAppBar(
            expandedHeight: 330,
            pinned: true,

            backgroundColor: Colors.white,

            elevation: 0,

            leading: Padding(
              padding: const EdgeInsets.all(8),

              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),

                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            actions: [
              Padding(
                padding: const EdgeInsets.all(8),

                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),

                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),

                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Favorites coming soon',
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,

                      errorBuilder:
                          (context, error, stackTrace) {
                        return _imagePlaceholder();
                      },
                    )
                  : _imagePlaceholder(),
            ),
          ),

          // --------------------------------------------------
          // CONTENT
          // --------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                110,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // --------------------------------------------------
                  // TITLE + RENT
                  // --------------------------------------------------

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          propertyTitle,

                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                            height: 1.15,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,

                          children: [
                            Text(
                              '€$rent',

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFF2563EB),
                              ),
                            ),

                            const Text(
                              '/ month',

                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // --------------------------------------------------
                  // LOCATION
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(16),

                      border: Border.all(
                        color:
                            const Color(0xFFE5E7EB),
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Container(
                          width: 42,
                          height: 42,

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEFF6FF),

                            borderRadius:
                                BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.location_on_outlined,

                            color:
                                Color(0xFF2563EB),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Location',

                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xFF9CA3AF),
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                city.isNotEmpty
                                    ? city
                                    : 'Location unavailable',

                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      Color(0xFF171717),
                                ),
                              ),

                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 2),

                                Text(
                                  address,

                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    color:
                                        Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // DESCRIPTION
                  // --------------------------------------------------

                  const Text(
                    'About this place',

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description.isNotEmpty
                        ? description
                        : 'No description provided.',

                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // OWNER
                  // --------------------------------------------------

                  if (ownerName.isNotEmpty) ...[
                    const Text(
                      'Listed by',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(16),

                        border: Border.all(
                          color:
                              const Color(0xFFE5E7EB),
                        ),
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,

                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(0xFFEFF6FF),

                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.person_outline,

                              color:
                                  Color(0xFF2563EB),

                              size: 26,
                            ),
                          ),

                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  ownerName,

                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Color(0xFF171717),
                                  ),
                                ),

                                const SizedBox(height: 3),

                                const Text(
                                  'Property owner',

                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.verified_outlined,

                            color:
                                Color(0xFF2563EB),

                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // --------------------------------------------------
      // BOTTOM MESSAGE BUTTON
      // --------------------------------------------------

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08),

                blurRadius: 15,

                offset: const Offset(0, -4),
              ),
            ],
          ),

          child: SizedBox(
            height: 54,
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: canMessage
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(
                            currentUserId:
                                currentUserId,

                            ownerId: ownerId!,

                            ownerName:
                                ownerName,

                            propertyId:
                                propertyId!,

                            propertyTitle:
                                propertyTitle,
                          ),
                        ),
                      );
                    }
                  : null,

              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 21,
              ),

              label: Text(
                ownerId == currentUserId
                    ? 'Your Listing'
                    : 'Message Owner',

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2563EB),

                disabledBackgroundColor:
                    const Color(0xFFE5E7EB),

                disabledForegroundColor:
                    const Color(0xFF9CA3AF),

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
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

          size: 90,

          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}