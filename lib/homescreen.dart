import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:arkinhype/buildBannerGraph.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  final List<dynamic> products;
  final List<dynamic> categories;

  HomeScreen({required this.products, required this.categories});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> displayedProducts = [];
  String? selectedCategory;
  double balance = 0.0;
  double rewards = 0.0;
  double trialBalance = 0.0;
  double trialRewards = 0.0;
  int reviewsAllowed = 0;
  int stuckreviews = 0;
  String? stuckcommission;
  String? requiredDeposite;
  Timer? _timer;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    displayedProducts = widget.products; // Show all products initially
    _fetchUserData(); // Fetch user data when initializing

    // Start polling to refresh data every 20 seconds
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchUserData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  void _filterProducts(String categoryId) {
    setState(() {
      selectedCategory = categoryId;
      displayedProducts = widget.products
          .where((product) => product['category']?['_id'] == categoryId)
          .toList();
    });
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('Token not found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final userData =
              responseData['data']['data']; // Extract nested 'data'

          if (mounted) {
            setState(() {
              // Parsing and safely assigning values to variables
              balance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
              rewards = (userData['rewards'] as num?)?.toDouble() ?? 0.0;
              trialBalance =
                  (userData['trialbalance'] as num?)?.toDouble() ?? 0.0;
              trialRewards =
                  (userData['trialReward'] as num?)?.toDouble() ?? 0.0;
              reviewsAllowed = (userData['reviewsAllowed'] as int?) ?? 0;
              stuckreviews = (userData['stuckreviews'] as int?) ?? 0;
              stuckcommission = userData['stuckcommission']?.toString();
              requiredDeposite = userData['requiredDeposite']?.toString();
            });
          }
        } else {
          print('Failed to fetch user data.');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _showReviewDialog(String productId) async {
    final product =
        widget.products.firstWhere((prod) => prod['_id'] == productId);

    // New logic: If reviewsAllowed == 0, show a dialog and return
    if (reviewsAllowed == 0) {
      _showNoAllowedReviewsDialog();
      return;
    }

    // Check if stuckreviews is equal to reviewsAllowed
    if (stuckreviews == reviewsAllowed) {
      _showStuckReviewDialog(product);
      return; // Exit if the user can't give more reviews
    }

    final TextEditingController _reviewController = TextEditingController();
    int _rating = 0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (userId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User data or token not found.'),
        ),
      );
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Submit Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Image and Name
                    Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        children: [
                          Image.network(
                            product['photo'] ?? '',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.production_quantity_limits);
                            },
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            product['productName'] ?? 'Product Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Icon(
                            Icons.star,
                            color:
                                _rating > index ? Colors.yellow : Colors.grey,
                          ),
                        );
                      }),
                    ),
                    // Review TextField
                    TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        labelText: 'Review',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    if (_rating > 0 && _reviewController.text.isNotEmpty) {
                      final reviewUrl = Uri.parse(
                          'https://arkindemo.kitchhome.com/api/v1/reviews');

                      try {
                        final response = await http.post(
                          reviewUrl,
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({
                            'review': _reviewController.text,
                            'rating': _rating,
                            'productId': productId,
                            'user': userId,
                          }),
                        );

                        if (mounted) {
                          Navigator.of(context)
                              .pop(); // Close the dialog safely

                          if (response.statusCode == 201) {
                            final responseData = json.decode(response.body);
                            if (responseData['status'] == 'success') {
                              await _fetchUserData(); // Update user data

                              // Show success toast with tick mark in the center
                              Fluttertoast.showToast(
                                msg: "Successfully submitted review",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );

                              // Move to the next product
                              int currentPage = _pageController.page!.toInt();
                              if (currentPage < displayedProducts.length - 1) {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to submit review.'),
                                ),
                              );
                            }
                          } else if (response.statusCode == 400) {
                            final responseData = json.decode(response.body);
                            if (responseData['message'] ==
                                "Insufficient balance for normal review.") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'You have insufficient balance to submit a review.'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Server error: ${response.statusCode}'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Server error: ${response.statusCode}'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  """'Error occurred: $e Here's the continuation and completion of the code with the updated app bar and the necessary modifications for responsiveness and visual appeal:

```dart"""),
                            ),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Please provide a rating and review.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // New dialog for no allowed reviews
  void _showNoAllowedReviewsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Reviews Allowed'),
          content: Text('You have no allowed reviews remaining.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStuckReviewDialog(dynamic product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Limit Reached'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Image and Name
                Container(
                  margin: EdgeInsets.only(bottom: 16.0.h),
                  child: Column(
                    children: [
                      Image.network(
                        product['photo'] ?? '',
                        width: 100.w,
                        height: 100.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 8.0.h),
                      Text(
                        product['productName'] ?? 'Product Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show stuck review details
                Text(
                  'You cannot submit more reviews as you have reached the limit.',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0.sp),
                Text('Stuck Reviews: $stuckreviews'),
                Text('Stuck Commission: ${stuckcommission ?? 'Not available'}'),
                Text(
                    'Required Deposit: ${requiredDeposite ?? 'Not available'}'),
                Text('Reviews Allowed: $reviewsAllowed'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'ARKIN HYPE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.amberAccent,
          ),
        ),
        leading: Image.asset(
          'assets/images/22.png', // Path to your logo image
          fit: BoxFit.contain,
          height: 35,
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.only(top: 02.h),
        child: Column(
          children: [
            // User Info
            Column(
              children: [
                Card(
                  color: Color.fromARGB(46, 53, 31, 31),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Balance',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '\$${rewards.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rewards',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.0.h),
                Card(
                  color: Color.fromARGB(46, 53, 31, 31),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '\$${trialBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Trial Balance',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '\$${trialRewards.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Trial Rewards',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Category Filter
            Container(
              padding: EdgeInsets.all(8.0.sp),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Color.fromARGB(110, 31, 30, 30))),
                        onPressed: () {
                          _filterProducts(category['_id']);
                        },
                        child: Text(
                          category['categoryName'] ?? " ",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Product Slider

// CarouselSlider with images from API and random sales numbers
            CarouselSlider(
              options: CarouselOptions(
                height: 100.h,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayInterval: Duration(seconds: 3),
                viewportFraction: 0.8,
              ),
              items: displayedProducts.map((product) {
                // Generate a random sales number
                int randomSales = Random().nextInt(1000) +
                    1; // Random number between 1 and 1000

                return Builder(
                  builder: (BuildContext context) {
                    return Card(
                      color: const Color.fromARGB(255, 23, 24, 24),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product['photo'] ?? ''),
                        ),
                        title: Text(
                          'Product Sales',
                          style: TextStyle(color: Colors.amberAccent),
                        ),
                        subtitle: Text(
                          '$randomSales sales so far',
                          style: TextStyle(
                              color: const Color.fromARGB(255, 129, 129, 127)),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: displayedProducts.length,
                itemBuilder: (context, index) {
                  final product = displayedProducts[index];
                  return GestureDetector(
                    onTap: () => _showReviewDialog(product['_id']),
                    child: Card(
                      color: Color.fromARGB(101, 43, 42, 42),
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15.0)),
                                child: Image.network(
                                  product['photo'] ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 150.h,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                        Icons.production_quantity_limits,
                                        size: 150.h);
                                  },
                                ),
                              ),
                              Container(
                                height: 150.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(15.0)),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['productName'] ?? 'Product Name',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${product['description'] ?? 'Description'}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.0.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            Colors.amber)),
                                    onPressed: () =>
                                        _showReviewDialog(product['_id']),
                                    child: Text(
                                      "Review",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }
}
