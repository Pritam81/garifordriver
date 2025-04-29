import 'package:flutter/material.dart';
import 'package:garifordriver/screens/Tabs/earningtab.dart';
import 'package:garifordriver/screens/Tabs/hometab.dart';
import 'package:garifordriver/screens/Tabs/ratingtab.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Actual content screens (excluding Share)
  final List<Widget> _screens = [
    HomeTab(), // index 0
    EarningTab(), // index 1
    RatingTab(), // index 3 in navBar, but index 2 in _screens
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Share item
      Share.share('Check out this amazing app!');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  final List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money_outlined),
      activeIcon: Icon(Icons.attach_money),
      label: 'Earning',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.share_outlined),
      activeIcon: Icon(Icons.share),
      label: 'Share',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.star_border),
      activeIcon: Icon(Icons.star),
      label: 'Rating',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _selectedIndex == 3
              ? _screens[2] // Rating
              : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Share.share('Check out this amazing app!');
          } else {
            _onItemTapped(index);
          }
        },
        selectedItemColor: Colors.yellow[800],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}
