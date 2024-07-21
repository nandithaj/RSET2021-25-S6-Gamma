import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UserData.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart package

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Color.fromARGB(255, 154, 159, 127),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10.0),
              GridView.count(
                crossAxisCount: 3, // Number of columns in the grid
                crossAxisSpacing: 40.0,
                mainAxisSpacing: 40.0,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildTotalCount(context),
                  _buildScreenCount(context),
                  _buildGrossCollection(context),
                  _buildHighestSpender(context),
                  _buildLocationGrid(context),
                  _buildUserCostPieChart(
                      context), // Add the pie chart widget here
                ],
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchHighestSpender() async {
    final url = Uri.parse(
        'http://127.0.0.1:5000/highest_spender'); // Assuming highest_spender endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch highest spender');
    }
  }

  Widget _buildHighestSpender(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchHighestSpender(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final username = snapshot.data!['username'];
          final cost = snapshot.data!['total_cost'];
          return Container(
            padding: const EdgeInsets.all(15.0), // Adjust padding as needed
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center text vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center text horizontally
              children: [
                const Text(
                  'Highest Spender',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    const Text('Username:'),
                    const SizedBox(width: 10.0),
                    Text(username),
                  ],
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: [
                    const Text('Total Cost:'),
                    const SizedBox(width: 10.0),
                    Text('₹$cost'), // Assuming cost is a currency
                  ],
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const Text('Loading highest spender data...');
      },
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

  Widget _buildStatCard({required String title, required dynamic value}) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
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

  Widget _buildLocationGrid(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchLocations(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final locations = snapshot.data!;
          return GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            children: locations
                .map((location) => _buildLocationCard(location))
                .toList(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const Text('Loading locations...');
      },
    );
  }

  Widget _buildLocationCard(String location) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Center(child: Text(location)),
    );
  }

  Future<List<String>> _fetchLocations() async {
    final url = Uri.parse(
        'http://127.0.0.1:5000/locations'); // Assuming locations endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final List<String> locations =
          data.cast<String>(); // Assuming data is already a list of strings
      return locations;
    } else {
      throw Exception('Failed to fetch locations');
    }
  }

  Widget _buildUserCostPieChart(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserCosts(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final userCosts = snapshot.data!;
          final List<PieChartSectionData> chartData = userCosts
              .map(
                (userCost) => PieChartSectionData(
                  title: userCost['username'] as String,
                  value: userCost['cost'] as double,
                  color: Colors.primaries[
                      userCosts.indexOf(userCost) % Colors.primaries.length],
                ),
              )
              .toList();

          return PieChart(
            PieChartData(
              sections: chartData,
              centerSpaceRadius: 100,
              sectionsSpace: 4, // Increase thickness by reducing section space
              pieTouchData: PieTouchData(touchCallback: (pieTouchResponse) {}),
              borderData: FlBorderData(show: false),
              // Optional: Add chart customization options
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserCosts() async {
    final url = Uri.parse('http://127.0.0.1:5000/user_costs');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final userCosts = data.cast<Map<String, dynamic>>();

      // Convert 'cost' values to double and filter out sections with zero values
      final List<Map<String, dynamic>> userCostsWithDoubleValues = userCosts
          .map((userCost) {
            final cost = userCost['cost'];
            return {
              'username': userCost['username'] as String,
              'cost': cost != null
                  ? double.parse(cost.toString())
                  : 0.0, // Handle null case
            };
          })
          .where((userCost) =>
              (userCost['cost'] as double) >
              0) // Explicit cast and filter out zero values
          .toList();

      return userCostsWithDoubleValues;
    } else {
      throw Exception('Failed to fetch user costs');
    }
  }

  Widget _buildTotalCount(BuildContext context) {
    return FutureBuilder<int>(
      future: _fetchTotalCount(), // New function to fetch total user count
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatCard(title: 'Total Users', value: snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<int> _fetchTotalCount() async {
    final url = Uri.parse(
        'http://127.0.0.1:5000/usercount'); // Assuming usercount endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final count = data['count'];
      return count;
    } else {
      throw Exception('Failed to fetch total user count');
    }
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
    final url = Uri.parse('http://127.0.0.1:5000/regcount1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final count = data['count'];
      return count;
    } else {
      throw Exception('Failed to fetch screen count');
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
    final url = Uri.parse('http://127.0.0.1:5000/grosscollection1');

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
