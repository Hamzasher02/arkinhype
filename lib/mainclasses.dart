import 'package:arkinhype/UserProfile.dart';
import 'package:arkinhype/accountdetail.dart';
import 'package:arkinhype/sumitedproduct.dart';
import 'package:arkinhype/withdrawscreen.dart';
import 'package:flutter/material.dart';
import 'package:arkinhype/homescreen.dart'; // Assuming this is where HomeScreen is defined

class MainClasses extends StatefulWidget {
  final List<dynamic> products;
  final List<dynamic> categories;
  final Map<String, dynamic> userdata;
  final token;

  MainClasses(
      {required this.products,
      required this.categories,
      required this.userdata,
      this.token});

  @override
  _MainClassesState createState() => _MainClassesState();
}

class _MainClassesState extends State<MainClasses> {
  int _selectedIndex = 0;

  // List of widgets for each screen
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize the screens list in initState
    _screens = [
      HomeScreen(products: widget.products, categories: widget.categories),
      AccountDetailScreen(),
      ProfileWidget(userData: widget.userdata),
      Withdraw(),
      ReviewsScreen(), // Screen for submitted products
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index < _screens.length) {
        _selectedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display selected screen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Prevents auto-color changes
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money), // Icon for Withdraw
            label: 'Withdraw',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), // Icon for Submitted Reviews
            label: 'Submitted',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(204, 255, 208, 38),
        unselectedItemColor: Colors.white, // Color for unselected items
        backgroundColor: Colors.black, // Set the background color to black
        onTap: _onItemTapped, // Update the selected index
      ),
    );
  }
}
