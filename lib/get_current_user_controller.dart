import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GetCurrentUserController extends GetxController {
  var data;
  Future<Map<String, dynamic>> getCurrentUserMethod() async {
    try {
      // Retrieve token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? '';

      final response = await http.get(
        Uri.parse("https://arkindemo.kitchhome.com/api/v1/users/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer $token", // Pass token in the Authorization header
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var userData = jsonDecode(response.body);
        data = userData["data"]["data"];
        if (kDebugMode) {
          print("Current User data $data");
          print("Reviews Allowed is ${data["data"]["data"]["reviewsAllowed"]}");
        }
      } else {
        if (kDebugMode) {
          print("Response code error is ${response.statusCode.toString()}");
        }
      }
    } catch (e) {
      f(kDebugMode) {
        print("exception is ${e.toString()}");
      }
    }
    return data;
  }
}
