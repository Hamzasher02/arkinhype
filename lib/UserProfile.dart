import 'package:arkinhype/echart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_echarts/flutter_echarts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileWidget extends StatefulWidget {
  final Map<String, dynamic> userData;

  ProfileWidget({required this.userData});

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  Map<String, dynamic> updatedUserData = {};
  int reviewsAllowed = 0; // Add this variable to store reviewsAllowed

  @override
  void initState() {
    super.initState();
    updatedUserData = widget.userData;
    reviewsAllowed =
        updatedUserData['reviewsAllowed'] ?? 0; // Initialize it here
    _updateUserProfile();
  }

  Future<void> _updateUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token1 = prefs.getString("token")!;

    final url =
        Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/updateMe');
    final token = token1;
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fullname': updatedUserData['fullname'],
          'address': updatedUserData['address'],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          updatedUserData = responseData['data']['user'];
          reviewsAllowed =
              updatedUserData['reviewsAllowed'] ?? 0; // Update it here
        });
        print('Profile updated successfully');
      } else {
        print('Failed to update profile');
      }
    } catch (error) {
      print('Error updating profile: $error');
    }
  }

  void _showEditDialog() {
    TextEditingController fullnameController =
        TextEditingController(text: updatedUserData['fullname']);
    TextEditingController addressController =
        TextEditingController(text: updatedUserData['address']);
    TextEditingController emailcontroller =
        TextEditingController(text: updatedUserData['email']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 224, 169, 2),
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullnameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: emailcontroller,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  updatedUserData['fullname'] = fullnameController.text;
                  updatedUserData['address'] = addressController.text;
                  updatedUserData['email'] = emailcontroller.text;
                });
                _updateUserProfile();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Icon(Icons.arrow_back),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration:
                    BoxDecoration(color: Color.fromARGB(80, 48, 48, 48)),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                            updatedUserData['photo'] ?? Icon(Icons.person)),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${updatedUserData['fullname']}',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${updatedUserData['_id']}',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 87, 86, 86),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 36, 36),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      height: 35.h,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 105, 104, 104),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            color: Colors.green,
                          ),
                          Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'Non-VIP',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      height: 35.h,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 105, 104, 104),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.person_add,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Main Account',
                                style: TextStyle(color: Colors.white),
                              ))
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 105, 104, 104),
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              reviewsAllowed == 0
                                  ? 'Verified ID'
                                  : 'Not Verified', // Conditionally display text
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            SizedBox(height: 10),
            Container(
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
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.amberAccent),
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
                  CircularProgressIndicator.adaptive(
                    strokeAlign: 0.1,
                    backgroundColor: Colors.amberAccent,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0.h),
            CarouselSlider(
              options: CarouselOptions(
                height: 80.h,
                autoPlay: true,
                enlargeCenterPage: true,
                animateToClosest: true,
                aspectRatio: 16 / 9,
                autoPlayInterval: Duration(seconds: 3),
                viewportFraction: 0.8,
              ),
              items: [
                'assets/images/11.png',
                'assets/images/21.png',
                'assets/images/download.png',
              ].map((imagePath) {
                return Builder(
                  builder: (BuildContext context) {
                    return Card(
                      color: const Color.fromARGB(255, 23, 24, 24),
                      child: ListTile(
                        trailing: CircleAvatar(
                          backgroundImage: AssetImage(imagePath),
                        ),
                        title: Text(
                          'Wining Products',
                          style: TextStyle(color: Colors.amberAccent),
                        ),
                        subtitle: Text(
                          '1k+ Wining Products give review earn easy',
                          style: TextStyle(
                              color: const Color.fromARGB(255, 129, 129, 127)),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.0.h),
            // Echart Graph
            RandomChartContainer()
          ],
        ),
      ),
    );
  }
}
