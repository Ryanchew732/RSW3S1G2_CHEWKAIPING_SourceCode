import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/auth/login_page.dart';
import 'package:testing/doctor/doctor_home_page.dart';
import 'package:testing/intro_slider.dart';
import 'package:testing/patient/patient_home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    User? user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

    // Wait for 2 seconds for the splash screen to show
    await Future.delayed(Duration(seconds: 2));

    if (user == null) {
      if (!hasSeenIntro) {
        // First-time user - show intro screens
        _navigateToIntro();
        await prefs.setBool('hasSeenIntro', true);
      } else {
        // Returning user - go directly to login
        _navigateToLogin();
      }
    } else {
      // Existing user - check role and navigate accordingly
      DatabaseReference userRef = _database.child('Doctors').child(user.uid);
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        _navigateToDoctorHome();
      } else {
        userRef = _database.child('Patients').child(user.uid);
        snapshot = await userRef.get();
        if (snapshot.exists) {
          _navigateToPatientHome();
        } else {
          _navigateToLogin();
        }
      }
    }
  }

  void _navigateToIntro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => IntroSlider()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToDoctorHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DoctorHomePage()),
    );
  }

  void _navigateToPatientHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => PatientHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Color(0xff3F2A66),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/images/login_bg.png',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

