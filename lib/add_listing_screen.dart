import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddListingScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const AddListingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final titleController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final rentController = TextEditingController();
  final imageUrlController = TextEditingController();
  final descriptionController = TextEditingController();

  Future<void> addListing() async {
    String title = titleController.text.trim();
    String city = cityController.text.trim();
    String address = addressController.text.trim();
    String rent = rentController.text.trim();
    String imageUrl = imageUrlController.text.trim();
    String description = descriptionController.text.trim();

    if (title.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        rent.isEmpty) {
      showMessage('Please fill in title, city, address and rent');
      return;
    }

    final url = Uri.parse(
      'https://properties-anywhere-backend.onrender.com/api/properties?userId=${widget.userId}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'city': city,
          'address': address,
          'rent': double.parse(rent),
          'imageUrl': imageUrl,
          'description': description,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        showMessage('Listing added successfully');

        Navigator.pop(context);
      } else {
        print(response.body);
        showMessage('Failed to add listing');
      }
    } catch (error) {
      print(error);
      showMessage('Could not connect to server');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    cityController.dispose();
    addressController.dispose();
    rentController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Listing'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Listing by ${widget.userName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Nice room in Munich',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Munich',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. Main Street 10',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: rentController,
                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  labelText: 'Monthly Rent (€)',
                  hintText: 'e.g. 650',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: imageUrlController,

                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Paste an image URL',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: descriptionController,

                maxLines: 4,

                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your property...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: addListing,

                  child: const Text(
                    'Post Listing',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}