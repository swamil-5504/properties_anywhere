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

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color textColor = Color(0xFF171717);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    final propertyId = widget.property['id'];

    final url = Uri.parse(
      'https://properties-anywhere-backend.onrender.com/api/properties/'
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
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      } else {
        debugPrint(
          'Update error: ${response.statusCode}',
        );

        debugPrint(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update listing. '
                'Status: ${response.statusCode}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint(
        'Connection error: $error',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not connect to the server.',
            ),
            behavior: SnackBarBehavior.floating,
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

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: secondaryTextColor,
        size: 21,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: textColor,
          ),
          onPressed: isUpdating
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Edit Listing',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          30,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.edit_outlined,
                      color: primaryBlue,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Update your listing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w700,
                            color: textColor,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Make changes to your property details.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // BASIC DETAILS
            // --------------------------------------------------

            const Text(
              'Basic details',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: titleController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: inputDecoration(
                label: 'Property title',
                icon: Icons.home_outlined,
                hint: 'e.g. Nice room in Siegen',
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: cityController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: inputDecoration(
                label: 'City',
                icon: Icons.location_city_outlined,
                hint: 'e.g. Siegen',
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: addressController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: inputDecoration(
                label: 'Address',
                icon: Icons.location_on_outlined,
                hint: 'e.g. Hauptstraße 10',
              ),
            ),

            const SizedBox(height: 26),

            // --------------------------------------------------
            // RENT
            // --------------------------------------------------

            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: rentController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: inputDecoration(
                label: 'Monthly rent (€)',
                icon: Icons.euro_outlined,
                hint: 'e.g. 650',
              ),
            ),

            const SizedBox(height: 26),

            // --------------------------------------------------
            // PROPERTY IMAGE
            // --------------------------------------------------

            const Text(
              'Property image',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add an image URL to show your property photo.',
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: imageUrlController,
              keyboardType:
                  TextInputType.url,
              decoration: inputDecoration(
                label: 'Image URL',
                icon: Icons.image_outlined,
                hint: 'https://example.com/house.jpg',
              ),
            ),

            const SizedBox(height: 26),

            // --------------------------------------------------
            // DESCRIPTION
            // --------------------------------------------------

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: descriptionController,
              textCapitalization:
                  TextCapitalization.sentences,
              maxLines: 6,
              decoration: inputDecoration(
                label: 'About the property',
                icon: Icons.description_outlined,
                hint:
                    'Describe the room, location, facilities, etc.',
              ).copyWith(
                alignLabelWithHint: true,
                contentPadding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  18,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // UPDATE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed:
                    isUpdating
                        ? null
                        : updateListing,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryBlue,
                  disabledBackgroundColor:
                      const Color(0xFFD1D5DB),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: isUpdating
                    ? const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          Text(
                            'Updating...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 21,
                          ),

                          SizedBox(width: 9),

                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'Your existing listing will be updated.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}