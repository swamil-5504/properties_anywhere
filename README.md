# PropertiesAnywhere – Flutter Frontend

> 🚧 **Work in Progress**

Flutter Android application for **PropertiesAnywhere**, a property and room rental platform.

## Tech Stack

* Flutter
* Dart
* Android
* HTTP REST API
* Spring Boot Backend
* PostgreSQL

## Current Features

* User registration and login
* Search properties by city
* View property details
* Add and manage listings
* View personal listings
* User-to-user chat
* Property-based conversations
* Read/unread messages
* New message notification count
* Mark messages as read

## Project Structure

```text
lib/
├── main.dart
├── login_screen.dart
├── add_listing_screen.dart
├── property_details_screen.dart
├── my_listings_screen.dart
├── messages_screen.dart
└── chat_screen.dart
```

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

For the Android Emulator, the app currently connects to the local backend using:

```text
http://10.0.2.2:8080
```

## Build APK

```bash
flutter build apk --release
```

## Status

🚧 **Work in Progress**

The frontend is actively being developed. UI, features, API integration, and application structure may change as development continues.

More features, improvements, testing, and production deployment are planned.
