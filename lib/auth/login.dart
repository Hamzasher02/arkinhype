import 'dart:convert';
import 'package:arkinhype/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arkinhype/mainclasses.dart';
import 'package:flutter/gestures.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordObscured =
      true; // Added this variable to toggle password visibility
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loginUrl =
        Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/login');
    final loginResponse = await http.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phone': _phoneController.text,
        'password': _passwordController.text,
      }),
    );

    if (loginResponse.statusCode == 200) {
      final loginData = json.decode(loginResponse.body);
      if (loginData['status'] == 'success') {
        final token = loginData['token'];
        final userId = loginData['data']['user']['_id'];

        // Save token and userId to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        // Fetch products and categories
        final productsUrl =
            Uri.parse('https://arkindemo.kitchhome.com/api/v1/products');
        final categoriesUrl =
            Uri.parse('https://arkindemo.kitchhome.com/api/v1/categories');

        final productsResponse = await http.get(
          productsUrl,
          headers: {'Authorization': 'Bearer $token'},
        );
        final categoriesResponse = await http.get(
          categoriesUrl,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (productsResponse.statusCode == 200 &&
            categoriesResponse.statusCode == 200) {
          final productsData = json.decode(productsResponse.body);
          final categoriesData = json.decode(categoriesResponse.body);

          if (productsData['status'] == 'success' &&
              categoriesData['status'] == 'success') {
            final products = productsData['data']['products'];
            final categories = categoriesData['data']['categories'];

            // Fetch user profile data from /users/me
            final userUrl =
                Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/me');
            final userResponse = await http.get(
              userUrl,
              headers: {'Authorization': 'Bearer $token'},
            );

            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);

              // Navigate to HomeScreen with animation
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return MainClasses(
                      products: products,
                      categories: categories,
                      userdata: userData['data']['data'],
                    );
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                ),
              );
            } else {
              setState(() {
                _errorMessage = 'Error fetching user data.';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Failed to fetch products or categories.';
            });
          }
        } else {
          setState(() {
            _errorMessage =
                'Error fetching products or categories: ${productsResponse.statusCode}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Error: ${loginResponse.statusCode}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(174, 255, 214, 64),
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/22.png'),
                SizedBox(height: 6.h),
                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  focusNode: _focusNode,
                ),
                SizedBox(height: 16.h),
                _buildPasswordField(), // Using the new password field with toggle
                SizedBox(height: 20.h),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(174, 255, 214, 64),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                SizedBox(height: 16.h),
                // Sign up button
                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.white70),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(color: Colors.amber),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => SignUpScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100.h),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.amber),
        filled: true,
        fillColor: Colors.black87,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber, width: 2),
        ),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _isPasswordObscured,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white30),
        prefixIcon: Icon(Icons.lock, color: Colors.amber),
        filled: true,
        fillColor: Colors.black87,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
      ),
    );
  }
}
