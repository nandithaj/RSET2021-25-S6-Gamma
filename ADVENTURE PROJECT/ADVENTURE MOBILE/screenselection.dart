import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/screendata.dart';
import 'package:provider/provider.dart';
import 'UserData.dart'; // Make sure UserData.dart is defined

class ScreenSelectionPage extends StatefulWidget {
  const ScreenSelectionPage({Key? key}) : super(key: key);

  @override
  _ScreenSelectionPageState createState() => _ScreenSelectionPageState();
}

class _ScreenSelectionPageState extends State<ScreenSelectionPage> {
  List<String> screenNames = [];
  String? selectedScreenName; // Store the selected screen name

  @override
  void initState() {
    super.initState();
    fetchScreenNames();
  }

  Future<void> fetchScreenNames() async {
    final userId = Provider.of<UserData>(context, listen: false).userId;
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.4:5000/screens?owner_id=$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          screenNames = List<String>.from(data['screen_names']);
        });
      } else {
        print('Failed to fetch screen names: ${response.statusCode}');
        // Consider showing an error message to the user
      }
    } catch (error) {
      print('Error fetching screen names: $error');
      // Consider showing an error message to the user
    }
  }

  Future<void> getScreenId(String screenName) async {
    final userId = Provider.of<UserData>(context, listen: false).userId;
    final screenIdProvider = Provider.of<ScreenIdProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.4:5000/getscreenid?owner_id=$userId&screen_name=$screenName'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final screenId = data['screen_id'];
        print('Screen ID for $screenName: $screenId');
        screenIdProvider.setSelectedScreenId(screenId);
      } else {
        print('Failed to fetch screen ID: ${response.statusCode}');
        // Consider showing an error message to the user
      }
    } catch (error) {
      print('Error fetching screen ID: $error');
      // Consider showing an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 240, 235, 235),
        title: const Text('Select your screen'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 131, 2, 244),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Select the screen on which the advertisement should be played',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 20),
            ListView.builder(
              itemCount: screenNames.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final screenName = screenNames[index];
                return RadioListTile<String>(
                  title: Text(screenName),
                  value: screenName,
                  groupValue: selectedScreenName,
                  onChanged: (value) {
                    setState(() {
                      selectedScreenName = value;
                      getScreenId(selectedScreenName!); // Fetch screen ID when screen is selected
                    });
                  },
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (selectedScreenName != null) {
                  // You can potentially send the selected screen index and user ID here
                  // using an API call or navigate to the ad playing page with arguments
                  print('Selected screen name and user ID: ');
                  final userId =
                      Provider.of<UserData>(context, listen: false).userId;
                  print('User ID: $userId');
                  print('Selected screen: $selectedScreenName');
                  Navigator.pushNamed(
                      context, '/adPlaying'); // Adjust route name if needed
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a screen')),
                  );
                }
              },
              icon: Icon(Icons.play_arrow), // Use play_arrow icon for play functionality
              label: Text('Play Advertisement'),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 240, 235, 235),
                minimumSize:
                    Size(double.infinity, 80.0), // Set button height to 50
                backgroundColor: const Color.fromARGB(255, 131, 2, 244),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
