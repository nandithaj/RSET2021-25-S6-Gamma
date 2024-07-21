import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'UserData.dart'; // Make sure UserData.dart is defined

class NewScreenPage extends StatefulWidget {
  const NewScreenPage({Key? key}) : super(key: key);

  @override
  _NewScreenPageState createState() => _NewScreenPageState();
}

class _NewScreenPageState extends State<NewScreenPage> {
  final _formKey = GlobalKey<FormState>();
  String _screenName = '';
  String _location = '';
  String _businessType = '';
  int _footfall = 0; // Assuming integer footfall
  double _baseRate = 0.0; // Assuming double base rate
  double _peakHourMultiplier = 0.0; // Assuming double peak hour multiplier
  TimeOfDay? _peakHourStart;
  TimeOfDay? _peakHourEnd;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context, listen: false);
    final userId = userData.userId; // Assuming userId getter in UserData

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Screen'),
        backgroundColor: Color(0xff907F9F)
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Screen Name',
                  
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a screen name.';
                  }
                  return null;
                },
                onSaved: (newValue) => _screenName = newValue!,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location.';
                  }
                  return null;
                },
                onSaved: (newValue) => _location = newValue!,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                ),
                onSaved: (newValue) => _businessType = newValue!,
              ),
              TextFormField(
                keyboardType: TextInputType.number, // For numeric input
                decoration: const InputDecoration(
                  labelText: 'Footfall (average daily)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the estimated footfall.';
                  }
                  return null;
                },
                onSaved: (newValue) => _footfall = int.parse(newValue!), // Convert to int
              ),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // For decimal input
                decoration: const InputDecoration(
                  labelText: 'Base Rate (per impression)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the base rate.';
                  }
                  return null;
                },
                onSaved: (newValue) => _baseRate = double.parse(newValue!), // Convert to double
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Peak Hour Multiplier:'),
                  SizedBox(
                    width: 100.0,
                    child: TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the peak hour multiplier.';
                        }
                        return null;
                      },
                      onSaved: (newValue) => _peakHourMultiplier = double.parse(newValue!),
                    ),
                  ),
                ],
              ),
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text('Peak Hour Start:'),
    TextButton(
      onPressed: () async {
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (selectedTime != null) {
          setState(() {
            _peakHourStart = selectedTime;
          });
        }
      },
      child: Text(_peakHourStart?.format(context) ?? 'Select Start Time'), // Display selected time or default text
    ),
  ],
),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Peak Hour End:'),
    TextButton(
      onPressed: () async {
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: _peakHourStart ?? TimeOfDay.now(), // Use previously selected start time if available
        );
        if (selectedTime != null) {
          setState(() {
            _peakHourEnd = selectedTime;
          });
        }
      },
      child: Text(_peakHourEnd?.format(context) ?? 'Select End Time'), // Display selected time or default text
    ),
  ],
),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Use user ID from UserData provider
                      String userIdString = userId!.toString();
                      await registerScreen(_screenName, _location, _businessType, userIdString, _footfall, _baseRate, _peakHourMultiplier, _peakHourStart, _peakHourEnd);

                
                    }
                  },
                  child: const Text('Register Screen'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 50),
                      backgroundColor: const Color(0xffA5F8D3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registerScreen(String screenName, String location, String businessType, String userId, int footfall, double baseRate, double peakHourMultiplier, TimeOfDay? peakHourStart, TimeOfDay? peakHourEnd) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:5000/newScreen'), // Replace with your actual backend URL
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'screen_name': screenName,
      'location': location,
      'business_type': businessType,
      'user_id': userId,
      'footfall': footfall,
      'base_rate': baseRate,
      'peak_hour_multiplier': peakHourMultiplier,
      'peak_hour_start': peakHourStart?.format(context), // Convert TimeOfDay to HH:MM format
      'peak_hour_end': peakHourEnd?.format(context),
    }),
  );

  if (response.statusCode == 201) {
    // Registration successful
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen registration successful!')),
    );
    Navigator.pop(context); // Close the screen after successful registration (optional)
  } else {
    // Registration failed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Screen registration failed! (Status code: ${response.statusCode})'),
      ),
    );
  }
}
}
