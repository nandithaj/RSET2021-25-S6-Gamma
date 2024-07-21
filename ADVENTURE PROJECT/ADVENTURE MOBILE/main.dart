import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'screenselection.dart';
import 'displayPage.dart';
import 'UserData.dart';
import 'screendata.dart'; // Import the ScreenIdProvider class

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserData>(
          create: (context) => UserData(),
        ),
        ChangeNotifierProvider<ScreenIdProvider>(
          create: (context) => ScreenIdProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Login Page',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // Define routes
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/screenSelection': (context) => ScreenSelectionPage(),
          '/adPlaying': (context) => DisplayAdImage(), // Add route for AdPlayingPage
        },
      ),
    );
  }
}
