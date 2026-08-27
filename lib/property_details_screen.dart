import 'package:flutter/material.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        property['imageUrl']?.toString() ?? '';

    String? ownerName;

    final dynamic user = property['user'];

    if (user is Map) {
      final dynamic name = user['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        ownerName = name.toString().trim();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
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
              padding: const EdgeInsets.all(20),
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
                          property['title']?.toString() ??
                              'No title',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        '€${property['rent']?.toString() ?? '0'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (ownerName != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ownerName!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
                          style: const TextStyle(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property['description']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? property['description'].toString()
                        : 'No description provided.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Messaging will be available soon.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.message_outlined,
                      ),
                      label: const Text('Message Owner'),
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
