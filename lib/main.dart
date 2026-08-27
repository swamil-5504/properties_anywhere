import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_listing_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final cityController = TextEditingController();

  List properties = [];

  // Search properties
  Future<void> searchProperties() async {
    String city = cityController.text.trim();

    // If city is empty, clear old results
    if (city.isEmpty) {
      setState(() {
        properties = [];
      });
      return;
    }

    final url = Uri.parse(
      'http://10.0.2.2:8080/api/properties?city=$city',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        properties = jsonDecode(response.body);
      });
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      appBar: AppBar(
        title: const Text('PropertiesAnywhere'),

        // Add Listing button
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddListingScreen(),
                ),
              );
            },
            child: const Text(
              'Add Listing',
            ),
          ),
        ],
      ),

      // Main screen
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Heading
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

            // City input
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Munich',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: searchProperties,
                child: const Text('Search'),
              ),
            ),

            const SizedBox(height: 25),

            // Property list
            Expanded(
              child: ListView.builder(
                itemCount: properties.length,

                itemBuilder: (context, index) {
                  final property = properties[index];

                  // Get image URL
                  String? imageUrl = property['imageUrl'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property image
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,

                            // Show placeholder if image fails
                            errorBuilder: (context, error, stackTrace) {
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

                        // Property information
                        ListTile(
                          title: Text(
                            property['title'] ?? 'No title',
                          ),

                          subtitle: Text(
                            '${property['city'] ?? ''} • '
                            '${property['address'] ?? ''}',
                          ),

                          trailing: Text(
                            '€${property['rent'] ?? 0}',
                          ),
                        ),

                        // Description
                        if (property['description'] != null &&
                            property['description']
                                .toString()
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            child: Text(
                              property['description'],
                            ),
                          ),
                      ],
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