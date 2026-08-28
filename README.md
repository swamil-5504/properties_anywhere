# PropertiesAnywhere – Flutter Frontend

PropertiesAnywhere is a Flutter mobile application for finding and listing rental properties. It is designed as a simple WG-Gesucht-style platform where users can browse properties, create their own listings, view property details, and manage their listings.

## Current Features

* User registration and login
* User-specific sessions using user ID and name
* Search properties by city
* Display property listings
* Property images
* Property title, rent, city and address
* Property descriptions
* Property details screen
* Display property owner information from backend data
* Add new property listings
* My Listings page
* Edit and update existing listings
* Logout functionality
* Navigation between property, listing and authentication screens

## Technology Stack

* Flutter
* Dart
* Material UI
* HTTP
* JSON REST APIs
* Android Emulator

## Backend Connection

The application currently connects to the local Spring Boot backend running on port `8080`.

For the Android Emulator, the backend is accessed using:

```text
http://10.0.2.2:8080
```

`10.0.2.2` refers to the host machine's localhost from inside the Android Emulator.

## Project Structure

```text
lib/
├── main.dart
├── login_screen.dart
├── register_screen.dart
├── add_listing_screen.dart
├── property_details_screen.dart
├── my_listings_screen.dart
└── edit_listing_screen.dart
```

The exact files may increase as new features are added.

## Main Screens

### Login

Allows an existing user to log into the application.

### Register

Allows a new user to create an account.

### Home

The main property discovery screen.

Users can:

* Enter a city
* Search for properties
* View property cards
* Open property details
* Add a listing
* Logout

### Property Details

Displays:

* Property image
* Title
* Rent
* Owner name
* City
* Address
* Description
* Message Owner action

The owner name is taken from the `user` object returned by the backend rather than being hardcoded.

### Add Listing

Allows the currently logged-in user to create a property listing.

The backend associates the property with the user's ID.

### My Listings

Displays properties created by the currently logged-in user.

Users can select a listing and edit its information.

### Edit Listing

Allows the owner to modify:

* Title
* City
* Address
* Rent
* Image URL
* Description

The updated information is sent to the Spring Boot backend using a `PUT` request.

## API Communication

The frontend communicates with the backend using HTTP requests.

Example property search:

```text
GET /api/properties?city=Siegen
```

Create property:

```text
POST /api/properties?userId=1
```

Get a property:

```text
GET /api/properties/{id}
```

Get a user's listings:

```text
GET /api/properties/user/{userId}
```

Update a property:

```text
PUT /api/properties/{id}
```

## Running the Application

Make sure Flutter is installed and configured.

Run:

```bash
flutter pub get
```

Then start an Android emulator and run:

```bash
flutter run
```

Make sure the Spring Boot backend is running on port `8080`.

## Android Emulator

When running the backend on the development computer:

```text
localhost:8080
```

is replaced by:

```text
10.0.2.2:8080
```

inside the Android Emulator.

## Current Development Status

### Completed

* Authentication flow
* Property creation
* Property search
* Property details
* Owner information
* My Listings
* Property editing
* Property updating
* Local Android testing

### Planned

* Messaging between users
* Conversation list
* Chat screen
* Sending and receiving messages
* Unread message indicators
* Improved authentication
* Property filtering
* Favorites
* Better image handling
* Production backend configuration

## Development

This project is currently being developed and tested locally before deployment to a remote server.
