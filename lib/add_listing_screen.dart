import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  bool _isLoading = false;

  Future<void> addListing() async {
    String title = titleController.text.trim();
    String city = cityController.text.trim();
    String address = addressController.text.trim();
    String rentText = rentController.text.trim();
    String imageUrl = imageUrlController.text.trim();
    String description = descriptionController.text.trim();

    if (title.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        rentText.isEmpty) {
      showMessage(
        'Please fill in title, city, address and rent',
      );
      return;
    }

    final double? rent = double.tryParse(rentText);

    if (rent == null || rent <= 0) {
      showMessage('Please enter a valid monthly rent');
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
          'rent': rent,
          'imageUrl': imageUrl,
          'description': description,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        showMessage('Listing posted successfully');

        Navigator.pop(context);
      } else {
        debugPrint(response.body);
        showMessage('Failed to post listing');
      }
    } catch (error) {
      if (!mounted) return;

      debugPrint(error.toString());
      showMessage('Could not connect to server');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6B7280),
      ),

      suffixText: suffix,

      suffixStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
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
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Post a Property',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            35,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'List your property',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Posted by ${widget.userName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Basic information
              sectionTitle(
                'Property details',
                'Tell people about the place you are offering.',
              ),

              const SizedBox(height: 18),

              // Title
              const Text(
                'Listing title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: titleController,

                textCapitalization:
                    TextCapitalization.sentences,

                decoration: fieldDecoration(
                  hint: 'e.g. Cozy room in Munich',
                  icon: Icons.home_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // City
              const Text(
                'City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: cityController,

                textCapitalization:
                    TextCapitalization.words,

                decoration: fieldDecoration(
                  hint: 'e.g. Munich',
                  icon: Icons.location_city_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // Address
              const Text(
                'Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: addressController,

                decoration: fieldDecoration(
                  hint: 'e.g. Main Street 10',
                  icon: Icons.location_on_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // Rent
              const Text(
                'Monthly rent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: rentController,

                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: fieldDecoration(
                  hint: 'e.g. 650',
                  icon: Icons.euro_outlined,
                  suffix: 'EUR / month',
                ),
              ),

              const SizedBox(height: 30),

              // Photos
              sectionTitle(
                'Property photo',
                'Add an image URL to show your property.',
              ),

              const SizedBox(height: 18),

              const Text(
                'Image URL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: imageUrlController,

                keyboardType: TextInputType.url,

                decoration: fieldDecoration(
                  hint: 'Paste an image URL',
                  icon: Icons.image_outlined,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Example: https://example.com/property.jpg',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),

              const SizedBox(height: 30),

              // Description
              sectionTitle(
                'Description',
                'Give potential tenants more information.',
              ),

              const SizedBox(height: 18),

              TextField(
                controller: descriptionController,

                textCapitalization:
                    TextCapitalization.sentences,

                maxLines: 6,

                decoration: InputDecoration(
                  hintText:
                      'Describe the room, apartment, location, '
                      'facilities, roommates, transport connections...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    height: 1.4,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.all(16),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Information box
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Make your listing clear and detailed. '
                        'Good photos and descriptions help people '
                        'understand your property better.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Post button
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : addListing,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB),

                    disabledBackgroundColor:
                        const Color(0xFF93B4F5),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [
                            Icon(
                              Icons.publish_outlined,
                              size: 21,
                            ),

                            SizedBox(width: 9),

                            Text(
                              'Post Listing',
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

              const SizedBox(height: 14),

              const Center(
                child: Text(
                  'You can edit your listing later.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
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