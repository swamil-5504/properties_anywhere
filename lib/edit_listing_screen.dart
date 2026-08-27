import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  final int userId;

  const EditListingScreen({
    super.key,
    required this.property,
    required this.userId,
  });

  @override
  State<EditListingScreen> createState() =>
      _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late TextEditingController titleController;
  late TextEditingController cityController;
  late TextEditingController addressController;
  late TextEditingController rentController;
  late TextEditingController imageUrlController;
  late TextEditingController descriptionController;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.property['title']?.toString() ?? '',
    );

    cityController = TextEditingController(
      text: widget.property['city']?.toString() ?? '',
    );

    addressController = TextEditingController(
      text: widget.property['address']?.toString() ?? '',
    );

    rentController = TextEditingController(
      text: widget.property['rent']?.toString() ?? '',
    );

    imageUrlController = TextEditingController(
      text: widget.property['imageUrl']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.property['description']?.toString() ?? '',
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

  Future<void> updateListing() async {
    final title = titleController.text.trim();
    final city = cityController.text.trim();
    final address = addressController.text.trim();
    final rentText = rentController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        rentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in title, city, address and rent.',
          ),
        ),
      );
      return;
    }

    final double? rent = double.tryParse(rentText);

    if (rent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid rent.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    final propertyId = widget.property['id'];

    final url = Uri.parse(
      'http://10.0.2.2:8080/api/properties/'
      '$propertyId?userId=${widget.userId}',
    );

    final body = jsonEncode({
      'title': title,
      'city': city,
      'address': address,
      'rent': rent,
      'imageUrl': imageUrl,
      'description': description,
    });

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Listing updated successfully.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        print('Update error: ${response.statusCode}');
        print(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update listing. '
                'Status: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (error) {
      print('Connection error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not connect to the server.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your property',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: rentController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly Rent (€)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isUpdating ? null : updateListing,
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update Listing',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}