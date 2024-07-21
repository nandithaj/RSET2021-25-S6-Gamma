import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'login.dart';
import 'dash.dart';
import 'newScreen.dart';
import 'UserData.dart';
import 'SuperAdminDashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserData>(
      create: (context) => UserData(),
      child: MaterialApp(
        title: 'Login Page',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // Define routes
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          //'/NewScreen': (context) => const SignupPage(),
          '/DashboardScreen': (context) => const DashboardScreen(),
          '/RegisterScreen': (context) => const NewScreenPage(),
          '/SuperAdminDashboard': (context) => const SuperAdminDashboard(),
          // ... other routes for your app
        },
      ),
    );
  }
}
