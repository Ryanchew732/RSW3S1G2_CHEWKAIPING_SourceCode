import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing/doctor/doctor_chatlist_page.dart';
import 'package:testing/doctor/doctor_profile.dart';
import 'package:testing/doctor/doctor_requests_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _children = [
    const DoctorRequestsPage(),
    const DoctorChatlistPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildIcon(int index, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _selectedIndex == index
                ? Colors.grey[200]
                : Colors.transparent,
          ),
          child: Icon(icon),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _selectedIndex == index
                ? const Color(0xFF424242)
                : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Removed the appBar property entirely
        body: _children.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedItemColor: const Color(0xFF424242),
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _buildIcon(0, Icons.calendar_today, 'Requests'),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(1, Icons.chat, 'Chats'),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(2, Icons.person, 'Profile'),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}