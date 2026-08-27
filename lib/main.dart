import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'add_listing_screen.dart';
import 'property_details_screen.dart';
import 'my_listings_screen.dart';

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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final cityController = TextEditingController();

  List<Map<String, dynamic>> properties = [];

  bool isLoading = false;

  Future<void> searchProperties() async {
    final city = cityController.text.trim();

    if (city.isEmpty) {
      setState(() {
        properties = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'http://10.0.2.2:8080/api/properties?city=${Uri.encodeComponent(city)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            properties = decoded
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
        }
      } else {
        print('Error: ${response.statusCode}');
        print(response.body);

        setState(() {
          properties = [];
        });
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

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void openAddListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddListingScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void openMyListings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyListingsScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void openPropertyDetails(Map<String, dynamic> property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(
          property: property,
        ),
      ),
    );
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PropertiesAnywhere',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'My Listings',
            onPressed: openMyListings,
          ),
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            tooltip: 'Add Listing',
            onPressed: openAddListing,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Welcome, ${widget.userName}!',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Find your next home.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Search for rooms and properties by city.',
            ),
            const SizedBox(height: 25),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Munich',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.location_city,
                ),
              ),
              onSubmitted: (value) {
                searchProperties();
              },
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : searchProperties,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: properties.isEmpty
                  ? const Center(
                      child: Text(
                        'Search for a city to see properties.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final property = properties[index];

                        final imageUrl =
                            property['imageUrl']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 20,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              openPropertyDetails(property);
                            },
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        height: 180,
                                        width: double.infinity,
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(
                                            Icons.home,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.home,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ListTile(
                                  title: Text(
                                    property['title']?.toString() ??
                                        'No title',
                                  ),
                                  subtitle: Text(
                                    '${property['city']?.toString() ?? ''}'
                                    ' • '
                                    '${property['address']?.toString() ?? ''}',
                                  ),
                                  trailing: Text(
                                    '€${property['rent']?.toString() ?? '0'}',
                                  ),
                                ),
                                if (property['description'] != null &&
                                    property['description']
                                        .toString()
                                        .isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    child: Text(
                                      property['description']
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
    );
  }
}