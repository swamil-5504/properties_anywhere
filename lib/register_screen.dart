import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    final url = Uri.parse(
      'https://properties-anywhere-backend.onrender.com/api/auth/register',
    );

    try {
      final response = await http.post(
        url,

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final user = jsonDecode(response.body);

        Navigator.pushAndRemoveUntil(
          context,

          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: user['id'],
              userName: user['name'],
            ),
          ),

          (route) => false,
        );
      } else {
        showMessage('Registration failed');
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: nameController,

                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,

                  obscureText: true,

                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: register,
                    child: const Text('Register'),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}