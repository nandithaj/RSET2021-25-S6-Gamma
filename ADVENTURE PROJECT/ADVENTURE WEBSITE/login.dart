import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set debug banner to false
      home: const LoginPage(),
    );
  }
}

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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/times-square-1.jpg', // Replace with your image path
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 300, // Adjust the width of the container as needed
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logof.png', // Replace with your logo path
                      height: 100.0,
                      width: 200.0,
                    ),
                    const SizedBox(height: 20),
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
                            minimumSize: const Size(100, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to signup page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupPage(),
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loginUser(
      String username, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/login'),
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
        if (data['user_id'] != null &&
            username == 'super' &&
            password == 'admin') {
          // Super admin login successful
          final userId = data['user_id'];
          final userData = Provider.of<UserData>(context, listen: false);
          userData.userId = userId;
          userData.isSuperAdmin = true;

          print('Retrieved user ID: $userId (Super Admin)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Super Admin Login successful!')),
          );
          Navigator.pushNamed(context, '/SuperAdminDashboard');
        } else if (data['user_id'] != null) {
          // Regular user login successful
          final userId = data['user_id'];
          final userData = Provider.of<UserData>(context, listen: false);
          userData.userId = userId;
          userData.isSuperAdmin = false;

          print('Retrieved user ID: $userId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          Navigator.pushNamed(context, '/DashboardScreen');
        } else {
          // Login successful but user ID missing or invalid credentials
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Login failed! Check credentials or missing user ID.'),
            ),
          );
        }
      } on FormatException catch (e) {
        // Handle JSON parsing errors
        print('Error parsing response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during login.')),
        );
      }
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed! (Status code: ${response.statusCode})'),
        ),
      );
    }
  }
}
