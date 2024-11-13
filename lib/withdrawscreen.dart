import 'dart:convert';
import 'dart:async'; // Import for Timer
import 'package:arkinhype/fonts.dart';
import 'package:arkinhype/get_current_user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Withdraw extends StatefulWidget {
  @override
  _WithdrawState createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  GetCurrentUserController getCurrentUserController =
      Get.put(GetCurrentUserController());

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletAddressController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final fontstyle _fontstyle = fontstyle();

  String _selectedPaymentMethod = '';
  final String _paymentMethodTRC20 = "USDT TRC20";
  final String _paymentMethodERC20 = "USDT ERC20";
  final String apiUrl = "https://arkindemo.kitchhome.com/api/v1/withdrawals";

  @override
  void initState() {
    super.initState();
    getCurrentUserController.getCurrentUserMethod();
    _startPolling();
  }

  Future<void> _submitWithdrawal() async {
    String amount = _amountController.text;
    String walletAddress = _walletAddressController.text;
    String email = _emailController.text;
    String name = _nameController.text;

    if (amount.isEmpty ||
        walletAddress.isEmpty ||
        email.isEmpty ||
        name.isEmpty ||
        _selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all fields'),
      ));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? '';

    Map<String, dynamic> withdrawData = {
      "amount": int.tryParse(amount) ?? 0,
      "payment": _selectedPaymentMethod,
      "walletAddress": walletAddress,
      "email": email,
      "name": name,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(withdrawData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear all fields after successful submission
        _amountController.clear();
        _walletAddressController.clear();
        _emailController.clear();
        _nameController.clear();
        setState(() {
          _selectedPaymentMethod = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Withdrawal submitted successfully'),
        ));

        // Refresh user data to update balance
        getCurrentUserController.getCurrentUserMethod();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to submit withdrawal request'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  void _startPolling() {
    Timer.periodic(Duration(seconds: 30), (timer) async {
      await getCurrentUserController.getCurrentUserMethod();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Withdraw", style: TextStyle(color: Colors.amber)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Balance Information
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.amber],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "5634********243",
                          style: _fontstyle.head1.copyWith(color: Colors.white),
                        ),
                        SizedBox(
                          child: Text(
                            getCurrentUserController.data != null &&
                                    getCurrentUserController
                                            .data["totalBalance"] !=
                                        null
                                ? double.parse(getCurrentUserController
                                        .data["totalBalance"]
                                        .toString())
                                    .toStringAsFixed(2)
                                : '0.00',
                            style:
                                _fontstyle.head1.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${getCurrentUserController.data?["fullname"] ?? 'N/A'}",
                          style:
                              _fontstyle.head1.copyWith(color: Colors.white70),
                        ),
                        getCurrentUserController.data?["reviewsAllowed"] == 0
                            ? Row(
                                children: [
                                  Text(
                                    "activate",
                                    style: _fontstyle.head1,
                                  ),
                                  Icon(
                                    Icons.done,
                                    color: Colors.green,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    "deactivate",
                                    style: _fontstyle.head1,
                                  ),
                                  Icon(
                                    Icons.no_accounts,
                                    color: Colors.red,
                                  ),
                                ],
                              )
                      ],
                    ),
                  ],
                ),
              ),

              // Form fields
              _buildInputField(_nameController, 'Name', Icons.person),
              SizedBox(height: 16),
              _buildInputField(
                _amountController,
                'Amount',
                Icons.monetization_on,
                TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildInputField(_walletAddressController, 'Wallet Address',
                  Icons.account_balance_wallet),
              SizedBox(height: 16),
              _buildInputField(_emailController, 'Email', Icons.email,
                  TextInputType.emailAddress),

              // Payment Method Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentMethodButton(_paymentMethodTRC20),
                    _buildPaymentMethodButton(_paymentMethodERC20),
                  ],
                ),
              ),

              // Submit Button
              ElevatedButton(
                onPressed: _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    Text("Submit Withdrawal", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String labelText, IconData icon,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
    );
  }

  Widget _buildPaymentMethodButton(String paymentMethod) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPaymentMethod = paymentMethod;
        });
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: _selectedPaymentMethod == paymentMethod
            ? Colors.amber
            : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(paymentMethod,
          style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
