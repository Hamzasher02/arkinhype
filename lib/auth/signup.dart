import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  File? _photo;
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if passwords match
    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() {
        _errorMessage = "Passwords don't match.";
        _isLoading = false;
      });
      return;
    }

    // Prepare the request data
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://arkindemo.kitchhome.com/api/v1/users/signup'),
    )
      ..fields['fullname'] = _fullnameController.text
      ..fields['email'] = _emailController.text
      ..fields['phone'] = _phoneController.text
      ..fields['address'] = _addressController.text
      ..fields['password'] = _passwordController.text
      ..fields['passwordConfirm'] = _passwordConfirmController.text;

    if (_photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await _photo!.readAsBytes(),
          filename: _photo!.path.split('/').last,
        ),
      );
    }

    // Make the API request
    final response = await request.send();

    if (response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (data['status'] == 'success') {
        // Navigate to the login screen upon successful sign-up
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage =
              data['message'] ?? 'Sign up failed. Please try again.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Error: ${response.statusCode}';
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
        title: Text('Sign Up'),
        backgroundColor: const Color.fromARGB(174, 255, 214, 64),
        elevation: 0,
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
                Image.asset('assets/images/22.png', scale: 3),
                _photo == null
                    ? TextButton(
                        onPressed: _pickImage,
                        child: Text('Pick a profile photo'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber,
                        ),
                      )
                    : Image.file(
                        _photo!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                SizedBox(height: 6),
                _buildTextField(
                  controller: _fullnameController,
                  labelText: 'Full Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  icon: Icons.home,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordConfirmController,
                  labelText: 'Confirm Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(174, 255, 214, 64),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                SizedBox(height: 16),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
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
}
