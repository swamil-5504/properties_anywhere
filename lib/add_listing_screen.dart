import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  final descriptionController = TextEditingController();

  // ------------------------------------------------------------
  // PHOTO
  // ------------------------------------------------------------

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  bool _isLoading = false;

  // ------------------------------------------------------------
  // SHOW CAMERA / GALLERY OPTIONS
  // ------------------------------------------------------------

  Future<void> _showImageSourceOptions() async {
    if (_isLoading) return;

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
                // Handle
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
                    'Add a property photo',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
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
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    // CAMERA
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

                    // GALLERY
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

  // ------------------------------------------------------------
  // CAMERA / GALLERY PICKER
  // ------------------------------------------------------------

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

      showMessage(
        source == ImageSource.camera
            ? 'Could not open camera'
            : 'Could not open gallery',
      );
    }
  }

  // ------------------------------------------------------------
  // REMOVE SELECTED PHOTO
  // ------------------------------------------------------------

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ------------------------------------------------------------
  // ADD LISTING
  // ------------------------------------------------------------

  Future<void> addListing() async {
    String title = titleController.text.trim();
    String city = cityController.text.trim();
    String address = addressController.text.trim();
    String rentText = rentController.text.trim();
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
      // Multipart request for property + image
      final request = http.MultipartRequest(
        'POST',
        url,
      );

      // Property fields
      request.fields['title'] = title;
      request.fields['city'] = city;
      request.fields['address'] = address;
      request.fields['rent'] = rent.toString();
      request.fields['description'] = description;

      // Add image if selected
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

  // ------------------------------------------------------------
  // IMAGE OPTION CARD
  // ------------------------------------------------------------

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
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
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
                color: const Color(0xFF2563EB),
                size: 25,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COMMON MESSAGE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // TEXT FIELD DECORATION
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
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
    descriptionController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // HEADER CARD
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.18),
                        borderRadius:
                            BorderRadius.circular(15),
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
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Posted by ${widget.userName}',
                            style:
                                const TextStyle(
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

              // ------------------------------------------------
              // PROPERTY DETAILS
              // ------------------------------------------------

              sectionTitle(
                'Property details',
                'Tell people about the place you are offering.',
              ),

              const SizedBox(height: 18),

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

              // ------------------------------------------------
              // PHOTOS
              // ------------------------------------------------

              sectionTitle(
                'Property photo',
                'Add a photo from your camera or gallery.',
              ),

              const SizedBox(height: 18),

              if (_selectedImage != null) ...[
                // PHOTO PREVIEW
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

                    // SMALL X BUTTON
                    Positioned(
                      top: 10,
                      right: 10,

                      child: GestureDetector(
                        onTap: _removeImage,

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
                ),

                const SizedBox(height: 12),

                // CHANGE PHOTO BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _showImageSourceOptions,

                    icon: const Icon(
                      Icons.refresh_outlined,
                      size: 20,
                    ),

                    label: const Text(
                      'Change Photo',
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF2563EB),

                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // ADD PHOTO BOX
                InkWell(
                  onTap: _isLoading
                      ? null
                      : _showImageSourceOptions,

                  borderRadius:
                      BorderRadius.circular(18),

                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),

                      border: Border.all(
                        color: const Color(
                          0xFFD1D5DB,
                        ),
                      ),
                    ),

                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFEFF6FF,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(17),
                          ),

                          child: const Icon(
                            Icons
                                .add_a_photo_outlined,
                            color:
                                Color(0xFF2563EB),
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Add a photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF171717),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Camera or Gallery',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF2563EB,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(10),
                          ),

                          child: const Text(
                            'Choose Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // ------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------

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

                  contentPadding:
                      const EdgeInsets.all(16),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // INFORMATION BOX
              // ------------------------------------------------

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius:
                      BorderRadius.circular(14),
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

              // ------------------------------------------------
              // POST BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : addListing,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB),

                    disabledBackgroundColor:
                        const Color(0xFF93B4F5),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
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