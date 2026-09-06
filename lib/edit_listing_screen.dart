import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  late TextEditingController descriptionController;

  // --------------------------------------------------
  // PHOTO
  // --------------------------------------------------

  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;

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
    descriptionController.dispose();

    super.dispose();
  }

  // --------------------------------------------------
  // CAMERA / GALLERY OPTIONS
  // --------------------------------------------------

  Future<void> _showImageSourceOptions() async {
    if (isUpdating) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Change property photo',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose how you want to add your photo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _imageOption(
                        icon: Icons.camera_alt_outlined,
                        title: 'Camera',
                        subtitle: 'Take a photo',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _imageOption(
                        icon: Icons.photo_library_outlined,
                        title: 'Gallery',
                        subtitle: 'Choose a photo',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // PICK IMAGE
  // --------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (error) {
      debugPrint(error.toString());

      if (!mounted) return;

      _showMessage(
        source == ImageSource.camera
            ? 'Could not open camera'
            : 'Could not open gallery',
      );
    }
  }

  // --------------------------------------------------
  // REMOVE NEW PHOTO
  // --------------------------------------------------

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // --------------------------------------------------
  // UPDATE LISTING
  // --------------------------------------------------

  Future<void> updateListing() async {
    final title = titleController.text.trim();
    final city = cityController.text.trim();
    final address = addressController.text.trim();
    final rentText = rentController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        rentText.isEmpty) {
      _showMessage(
        'Please fill in title, city, address and rent.',
      );
      return;
    }

    final double? rent = double.tryParse(rentText);

    if (rent == null) {
      _showMessage('Please enter a valid rent.');
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

    try {
      // Multipart request instead of JSON
      final request = http.MultipartRequest(
        'PUT',
        url,
      );

      request.fields['title'] = title;
      request.fields['city'] = city;
      request.fields['address'] = address;
      request.fields['rent'] = rent.toString();
      request.fields['description'] = description;

      // Only upload a file if the user selected a new photo.
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        if (!mounted) {
          return;
        }

        _showMessage(
          'Listing updated successfully.',
        );

        Navigator.pop(context, true);
      } else {
        debugPrint(
          'Update error: ${response.statusCode}',
        );

        debugPrint(response.body);

        if (mounted) {
          _showMessage(
            'Failed to update listing. '
            'Status: ${response.statusCode}',
          );
        }
      }
    } catch (error) {
      debugPrint(
        'Connection error: $error',
      );

      if (mounted) {
        _showMessage(
          'Could not connect to the server.',
        );
      }
    }

    if (mounted) {
      setState(() {
        isUpdating = false;
      });
    }
  }

  // --------------------------------------------------
  // IMAGE OPTION CARD
  // --------------------------------------------------

  Widget _imageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 25,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(String message) {
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

  // --------------------------------------------------
  // INPUT DECORATION
  // --------------------------------------------------

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

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final existingImageUrl =
        widget.property['imageUrl']?.toString() ?? '';

    String? displayImageUrl;

    if (existingImageUrl.isNotEmpty) {
      displayImageUrl = existingImageUrl.startsWith('http')
          ? existingImageUrl
          : 'http://10.0.2.2:8080$existingImageUrl';
    }

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
                borderRadius:
                    BorderRadius.circular(18),
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
              'Change the photo using your camera or gallery.',
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
              ),
            ),

            const SizedBox(height: 14),

            // NEW PHOTO SELECTED
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _removeSelectedImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              )

            // EXISTING SERVER PHOTO
            else if (displayImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Image.network(
                      displayImageUrl,
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return _noImagePreview();
                      },
                    ),
                  ),

                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withOpacity(0.65),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Current photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )

            // NO IMAGE
            else
              _noImagePreview(),

            const SizedBox(height: 12),

            // CHANGE / ADD PHOTO
            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed: isUpdating
                    ? null
                    : _showImageSourceOptions,

                icon: Icon(
                  _selectedImage != null ||
                          displayImageUrl != null
                      ? Icons.refresh_outlined
                      : Icons.add_a_photo_outlined,
                  size: 20,
                ),

                label: Text(
                  _selectedImage != null ||
                          displayImageUrl != null
                      ? 'Change Photo'
                      : 'Add Photo',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      primaryBlue,

                  side: const BorderSide(
                    color: primaryBlue,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
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
                            Icons
                                .check_circle_outline,
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

  // --------------------------------------------------
  // NO IMAGE PLACEHOLDER
  // --------------------------------------------------

  Widget _noImagePreview() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 42,
            color: Color(0xFF9CA3AF),
          ),

          SizedBox(height: 10),

          Text(
            'No photo added',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}