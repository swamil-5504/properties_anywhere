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
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Map<String, dynamic>> properties = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'http://10.0.2.2:8080/api/properties/user/${widget.userId}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          properties = data
              .whereType<Map>()
              .map(
                (property) => Map<String, dynamic>.from(property),
              )
              .toList();
        });
      } else {
        setState(() {
          properties = [];
        });

        print('Error loading listings: ${response.statusCode}');
      }
    } catch (error) {
      print('Connection error: $error');

      setState(() {
        properties = [];
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openEditListing(
    Map<String, dynamic> property,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingScreen(
          property: property,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      loadListings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : properties.isEmpty
              ? const Center(
                  child: Text(
                    'You have no listings yet.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadListings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];

                      final String imageUrl =
                          property['imageUrl']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 20,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.home,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.home,
                                    size: 70,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
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
                                            fontSize: 21,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '€${property['rent']?.toString() ?? '0'}',
                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    '${property['city']?.toString() ?? ''} • '
                                    '${property['address']?.toString() ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),

                                  if (property['description'] !=
                                          null &&
                                      property['description']
                                          .toString()
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      property['description']
                                          .toString(),
                                      maxLines: 3,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          openEditListing(
                                        property,
                                      ),
                                      icon: const Icon(
                                        Icons.edit,
                                      ),
                                      label: const Text(
                                        'Edit Listing',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
