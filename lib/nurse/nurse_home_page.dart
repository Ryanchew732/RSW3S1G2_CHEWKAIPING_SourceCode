import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testing/doctor/model/Nurse.dart';
import 'package:testing/nurse/nurse_check_schedule_page.dart';
import 'nurse_profile_page.dart'; // Create these pages

class NurseHomePage extends StatefulWidget {
  const NurseHomePage({super.key});

  @override
  State<NurseHomePage> createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Nurse? _nurse;
  Map<String, dynamic>? _assignedDoctor;

  int _selectedIndex = 0;
  final List<Widget> _children = [
    const NurseCheckSchedulePage(), // Your tasks/requests page
    const NurseProfilePage(), // Your profile page
  ];

  @override
  void initState() {
    super.initState();
    _loadNurseData();
  }

  Future<void> _loadNurseData() async {
    if (_currentUser == null) return;

    try {
      DataSnapshot snapshot = await _database.child('Nurses').child(_currentUser!.uid).get();
      if (snapshot.exists) {
        setState(() {
          _nurse = Nurse.fromMap(snapshot.value as Map<dynamic, dynamic>, _currentUser!.uid);
        });

        if (_nurse!.assignedDoctorId.isNotEmpty) {
          DataSnapshot doctorSnapshot = await _database.child('Doctors').child(_nurse!.assignedDoctorId).get();
          if (doctorSnapshot.exists) {
            setState(() {
              _assignedDoctor = doctorSnapshot.value as Map<String, dynamic>;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading nurse data: $e');
    }
  }

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
        body: _children.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedItemColor: const Color(0xFF424242),
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _buildIcon(0, Icons.assignment, 'Schedule'),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(1, Icons.person, 'Profile'),
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