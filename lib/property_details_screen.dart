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
        property['title']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Property Details',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    height: 280,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.home,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 280,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.home,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.all(20),
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
                          property['title']
                                  ?.toString() ??
                              'No title',
                          style:
                              const TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        '€${property['rent']?.toString() ?? '0'}',
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (ownerName.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ownerName,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${property['city']?.toString() ?? ''}, '
                          '${property['address']?.toString() ?? ''}',
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    property['description']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? property['description']
                            .toString()
                        : 'No description provided.',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          ownerId == null ||
                                  propertyId == null ||
                                  ownerId ==
                                      currentUserId
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ChatScreen(
                                        currentUserId:
                                            currentUserId,
                                        ownerId:
                                            ownerId,
                                        ownerName:
                                            ownerName,
                                        propertyId:
                                            propertyId,
                                        propertyTitle:
                                            propertyTitle,
                                      ),
                                    ),
                                  );
                                },
                      icon: const Icon(
                        Icons.message_outlined,
                      ),
                      label: const Text(
                        'Message Owner',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}