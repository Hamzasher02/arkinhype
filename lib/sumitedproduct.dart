import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewsScreen extends StatefulWidget {
  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token =
        prefs.getString("token") ?? ''; // Retrieve token from SharedPreferences

    final url =
        'https://arkindemo.kitchhome.com/api/v1/reviews'; // Replace with your actual API endpoint

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization':
              'Bearer $token', // Pass token in the Authorization header
          'Content-Type': 'application/json', // Set content-type if needed
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Decode the JSON response
        setState(() {
          reviews =
              data['data']['reviews'] ?? []; // Ensure reviews list is not null
          isLoading = false;
        });
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Background color matching Withdraw screen
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Reviews',
          style: TextStyle(color: Colors.amber, fontSize: 22), // App bar design
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            )
          : reviews.isEmpty
              ? Center(
                  child: Text(
                    'No reviews available.',
                    style: TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final product = review['product'];

                      final productName =
                          product != null && product['productName'] != null
                              ? product['productName']
                              : 'Unknown Product';
                      final productPhoto = product != null &&
                              product['photo'] != null
                          ? product['photo']
                          : 'https://via.placeholder.com/50'; // Placeholder image

                      return Card(
                        color: Colors.black, // Card background color
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.amber, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  productPhoto,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Review: ${review['review'] ?? 'No review'}',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rating: ${review['rating']?.toString() ?? 'No rating'}',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Date: ${review['createdAt'] ?? 'Unknown date'}',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
