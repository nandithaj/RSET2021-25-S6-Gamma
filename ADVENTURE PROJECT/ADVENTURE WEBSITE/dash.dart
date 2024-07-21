import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'newScreen.dart';
import 'UserData.dart';
import 'advertise_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Wrap Scaffold with Container
      color: Color.fromARGB(255, 97, 5, 5), // Set background color here
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Color.fromARGB(255, 93, 27, 152),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Your Ads'),
                const SizedBox(height: 10.0),
                GridView.count(
                  crossAxisCount: 3, // Number of columns in the grid
                  crossAxisSpacing: 40.0,
                  mainAxisSpacing: 40.0,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildAdvertiseButton(context),
                    _buildAdsPlayed(context),
                    _buildGrossFootfall(context),
                  ],
                ),
                const SizedBox(height: 20.0),
                _buildSectionTitle('Your Screens'),
                const SizedBox(height: 10.0),
                GridView.count(
                  crossAxisCount: 3, // Number of columns in the grid
                  crossAxisSpacing: 40.0,
                  mainAxisSpacing: 40.0,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildRegisterButton(context),
                    _buildScreenCount(context),
                    _buildGrossCollection(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAdvertiseButton(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/adimage.jpg', // Replace 'assets/ad_image.jpg' with your image path
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScreenSelectionPage(),
              ),
            );
          },
          icon: Icon(Icons.add_circle_outline),
          label: Text(
            'Advertise',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 55, 7, 121).withOpacity(0.8),
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/regimage.jpeg', // Replace 'assets/register_image.jpg' with your image path
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewScreenPage(),
              ),
            );
          },
          icon: Icon(Icons.app_registration),
          label: Text(
            'Register Screen',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 54, 2, 10).withOpacity(0.6),
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required dynamic value}) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 114, 11, 145).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center text horizontally
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // Align text in the center
          ),
          Text(
            value.toString(),
            style: (value is int || value is double)
                ? const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  )
                : const TextStyle(fontSize: 20.0),
            textAlign: TextAlign.center, // Align text in the center
          ),
        ],
      ),
    );
  }

  Widget _buildScreenCount(BuildContext context) {
    final userId = Provider.of<UserData>(context).userId;

    if (userId == null) {
      return const Text('Loading...');
    }

    return FutureBuilder<int>(
      future: _fetchScreenCount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatCard(
              title: 'Registered Screens', value: snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<int> _fetchScreenCount(int userId) async {
    final url = Uri.parse('http://127.0.0.1:5000/regcount/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final count = data['count'];
      return count;
    } else {
      throw Exception('Failed to fetch screen count');
    }
  }

  Widget _buildAdsPlayed(BuildContext context) {
    final userId = Provider.of<UserData>(context).userId;

    if (userId == null) {
      return const Text('Loading...');
    }

    return FutureBuilder<int>(
      future: _fetchAdsPlayedCount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatCard(title: 'Ads Played', value: snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<int> _fetchAdsPlayedCount(int userId) async {
    final url = Uri.parse('http://127.0.0.1:5000/adsplayed/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final count = data['count'];
      return count;
    } else {
      throw Exception('Failed to fetch ads played count');
    }
  }

  Widget _buildGrossFootfall(BuildContext context) {
    final userId = Provider.of<UserData>(context).userId;

    if (userId == null) {
      return const Text('Loading...');
    }

    return FutureBuilder<int>(
      future: _fetchGrossFootfallCount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatCard(title: 'Ads Seen By', value: snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<int> _fetchGrossFootfallCount(int userId) async {
    final url = Uri.parse('http://127.0.0.1:5000/grossfootfallcount/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final footfallCount = data['footfall'];
      return footfallCount;
    } else {
      throw Exception('Failed to fetch gross footfall count');
    }
  }

  Widget _buildGrossCollection(BuildContext context) {
    final userId = Provider.of<UserData>(context).userId;

    if (userId == null) {
      return const Text('Loading...');
    }

    return FutureBuilder<double>(
      future: _fetchGrossCollection(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatCard(
              title: 'Gross Collection(in Rs.)', value: snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<double> _fetchGrossCollection(int userId) async {
    final url = Uri.parse('http://127.0.0.1:5000/grosscollection/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final double collection = data['collection'];
      return collection;
    } else {
      throw Exception('Failed to fetch gross collection');
    }
  }
}
