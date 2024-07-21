import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'dash.dart'; // Import ScreenSelectionPage (assuming dash.dart contains ScreenSelectionPage)
import 'package:provider/provider.dart';
import 'UserData.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Login'),
          foregroundColor: Color.fromARGB(255, 240, 235, 235),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 131, 2, 244)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/logof.png', // Replace with your logo path
                height: 100.0,
                width: 200.0,
              ),
              const SizedBox(height: 40),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username.';
                  }
                  return null;
                },
                onSaved: (newValue) => _username = newValue!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  return null;
                },
                onSaved: (newValue) => _password = newValue!,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        await loginUser(_username, _password, context);
                      }
                    },
                    child: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 240, 235, 235),
                      minimumSize: const Size(100, 50),
                      backgroundColor: const Color.fromARGB(255, 131, 2, 244),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loginUser(
      String username, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.4:5000/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data['user_id'] != null) {
          // User ID received successfully
          final userId = data['user_id'];
          final userData = Provider.of<UserData>(context, listen: false);
          userData.userId = userId;

          // Print the user ID for verification
          print('Retrieved user ID: $userId');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          // Navigate to ScreenSelectionPage
          Navigator.pushNamed(context, '/screenSelection');
        } else {
          // Login successful but user ID missing in response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Login successful, but user ID missing!')),
          );
        }
      } on FormatException catch (e) {
        // Handle potential JSON parsing errors
        print('Error parsing response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during login.')),
        );
      }
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Login failed! (Status code: ${response.statusCode})')),
      );
    }
  }
}