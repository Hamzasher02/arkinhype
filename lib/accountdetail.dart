import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'dart:async';

class AccountDetailScreen extends StatefulWidget {
  @override
  _AccountDetailScreenState createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  Map<String, dynamic> updatedUserData = {};
  Timer? _timer;
  String graphLabel = 'Balance';
  List<double> graphData = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _updateGraphData('Balance');

    // Fetch user data every 10 seconds
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchUserProfile();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the screen is disposed
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? '';

    final url = Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          updatedUserData = responseData['data']['user'];
        });
        _updateGraphData(
            graphLabel); // Update graph data to reflect new user data
        print('User profile fetched successfully');
      } else {
        print('Failed to fetch user profile');
      }
    } catch (error) {
      print('Error fetching user profile: $error');
    }
  }

  // Pull-to-refresh functionality
  Future<void> _handleRefresh() async {
    await _fetchUserProfile(); // Refresh the user profile on pull-down
  }

  // Update graph data based on selected grid item
  void _updateGraphData(String label) {
    setState(() {
      graphLabel = label;

      if (label == 'Balance') {
        double balance = (updatedUserData['balance']?.toDouble() ?? 0.0);
        graphData = [
          balance,
          balance * 1.02,
          balance * 1.05,
          balance * 1.03,
          balance * 1.07,
          balance * 1.04,
          balance * 1.09,
        ];
      } else if (label == 'Rewards') {
        double rewards = (updatedUserData['rewards']?.toDouble() ?? 0.0);
        graphData = [
          rewards,
          rewards * 1.01,
          rewards * 1.03,
          rewards * 1.02,
          rewards * 1.05,
          rewards * 1.03,
          rewards * 1.08,
        ];
      } else if (label == 'Commission') {
        double commission =
            (updatedUserData['stuckcommission']?.toDouble() ?? 0.0);
        graphData = [
          commission,
          commission * 1.03,
          commission * 1.05,
          commission * 1.02,
          commission * 1.06,
          commission * 1.04,
          commission * 1.07,
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // Triggered on pull-down gesture
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30.h),

              // Deposit section
              _buildDepositSection(),

              SizedBox(height: 16.0),

              // Grid View Section
              _buildGridView(),

              SizedBox(height: 16.0),

              // Line Graph Section
              _buildTradingGraph(),

              SizedBox(height: 16.0),

              // Bar Chart Section
              _buildSimpleBarChart(),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build deposit section
  Widget _buildDepositSection() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 36, 36),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Deposit 50,000 USDT to unlock a VIP 1 trial and enjoy exclusive perks!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.amberAccent),
                      ),
                      onPressed: () {},
                      child: Text('Deposit Now'),
                    ),
                    SizedBox(width: 8.0),
                    TextButton.icon(
                      onPressed: () {},
                      label: Text('VIP Benefits'),
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16.0),
        ],
      ),
    );
  }

  // Method to build the trading-like graph (Line Chart)
  Widget _buildTradingGraph() {
    return Container(
      color: Colors.black12,
      width: double.infinity,
      height: 250.h,
      child: Echarts(
        option: '''
        {
          title: {
            text: '$graphLabel Data',
            left: 'center',
            textStyle: {
              color: 'white'
            }
          },
          tooltip: {
            trigger: 'axis',
            axisPointer: {
              type: 'cross'
            }
          },
          xAxis: {
            type: 'category',
            data: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            boundaryGap: true,
            axisLine: { onZero: false, lineStyle: { color: 'white' }},
          },
          yAxis: {
            scale: true,
            splitArea: {
              show: true
            },
            axisLine: { lineStyle: { color: 'white' }},
          },
          series: [
            {
              name: '$graphLabel',
              type: 'line',
              data: ${graphData.map((e) => e.toStringAsFixed(2)).toList()},
              itemStyle: {
                color: '#ffcc00'
              },
            }
          ],
          backgroundColor: 'black'
        }
        ''',
      ),
    );
  }

  // Method to build the grid view for various items
  Widget _buildGridView() {
    final items = [
      {
        'label': 'Balance',
        'value': updatedUserData['balance']?.toStringAsFixed(1) ?? '0.0',
      },
      {
        'label': 'Rewards',
        'value': updatedUserData['rewards']?.toStringAsFixed(1) ?? '0.0',
      },
      {
        'label': 'Allowed',
        'value': updatedUserData['reviewsAllowed']?.toStringAsFixed(1) ?? '0.0',
      },
      {
        'label': 'Used',
        'value': updatedUserData['reviewsUsed']?.toStringAsFixed(1) ?? '0.0',
      },
      {
        'label': 'Commission',
        'value':
            updatedUserData['stuckcommission']?.toStringAsFixed(1) ?? '0.0',
      },
      {
        'label': 'Deposit',
        'value':
            updatedUserData['requiredDeposite']?.toStringAsFixed(1) ?? '0.0',
      }
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8, // Adjusted to provide more vertical space
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _updateGraphData(item['label']!), // Update graph on tap
          child: Card(
            color: const Color.fromARGB(255, 36, 36, 36),
            child: Padding(
              padding:
                  const EdgeInsets.all(8.0), // Add padding to avoid overflow
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit
                        .scaleDown, // Ensure text fits the available space
                    child: Text(
                      item['label']!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  FittedBox(
                    // Ensures this text fits within bounds
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item['value']!,
                      style: const TextStyle(
                          color: Colors.amberAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to build a simple bar chart
  Widget _buildSimpleBarChart() {
    return Container(
      color: Colors.black12,
      width: double.infinity,
      height: 250.h,
      child: Echarts(
        option: '''
        {
          title: {
            text: 'User Statistics',
            left: 'center',
            textStyle: {
              color: 'white'
            }
          },
          tooltip: {
            trigger: 'axis',
            axisPointer: {
              type: 'shadow'
            }
          },
          xAxis: {
            type: 'category',
            data: ['Balance', 'Rewards', 'Allowed Reviews', 'Commission'],
            axisLine: { lineStyle: { color: 'white' }},
          },
          yAxis: {
            type: 'value',
            axisLine: { lineStyle: { color: 'white' }},
          },
          series: [
            {
              data: [
                ${updatedUserData['balance']?.toDouble() ?? 0.0},
                ${updatedUserData['rewards']?.toDouble() ?? 0.0},
                ${updatedUserData['reviewsAllowed']?.toDouble() ?? 0.0},
                ${updatedUserData['stuckcommission']?.toDouble() ?? 0.0}
              ],
              type: 'bar',
              itemStyle: {
                color: '#ffcc00'
              },
            }
          ],
          backgroundColor: 'black'
        }
        ''',
      ),
    );
  }
}
