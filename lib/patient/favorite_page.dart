import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/doctor/doctor_details_page.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/doctor/widget/doctor_card.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('Doctors');
  final DatabaseReference _favoritesDatabase = FirebaseDatabase.instance.ref().child('Favorites');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Doctor> _favoriteDoctors = [];
  bool _isLoading = true;
  late DatabaseReference _favoritesRef;
  late StreamSubscription<DatabaseEvent> _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _setupFavoritesListener();
  }

  void _setupFavoritesListener() {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      _favoritesRef = _favoritesDatabase.child(userId);
      _favoritesSubscription = _favoritesRef.onValue.listen((event) {
        _fetchFavoriteDoctors();
      });
    }
    _fetchFavoriteDoctors();
  }

  Future<void> _fetchFavoriteDoctors() async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      final favoritesEvent = await _favoritesDatabase.child(userId).once();
      if (favoritesEvent.snapshot.value != null) {
        Map<dynamic, dynamic> favorites = favoritesEvent.snapshot.value as Map<dynamic, dynamic>;
        List<String> favoriteIds = [];

        favorites.forEach((doctorId, isFavorite) {
          if (isFavorite == true) {
            favoriteIds.add(doctorId.toString());
          }
        });

        if (favoriteIds.isNotEmpty) {
          List<Doctor> tmpDoctors = [];
          for (String doctorId in favoriteIds) {
            final doctorEvent = await _database.child(doctorId).once();
            if (doctorEvent.snapshot.value != null) {
              Doctor doctor = Doctor.fromMap(
                  doctorEvent.snapshot.value as Map<dynamic, dynamic>,
                  doctorId
              );
              tmpDoctors.add(doctor);
            }
          }
          setState(() {
            _favoriteDoctors = tmpDoctors;
            _isLoading = false;
          });
          return;
        }
      }
    }
    setState(() {
      _isLoading = false;
      _favoriteDoctors = [];
    });
  }

  Future<void> _removeFavorite(String doctorId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _favoritesDatabase.child(userId).child(doctorId).remove();
    }
  }

  @override
  void dispose() {
    _favoritesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorite Doctors',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1A73E8), // Dark blue
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A73E8), // Dark blue
        ),
      )
          : _favoriteDoctors.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No favorite doctors yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tap the heart icon on doctors to add them here',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchFavoriteDoctors,
        color: Color(0xFF1A73E8), // Dark blue
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _favoriteDoctors.length,
            itemBuilder: (context, index) {
              final doctor = _favoriteDoctors[index];
              return Dismissible(
                key: Key(doctor.uid),
                background: Container(
                  color: Colors.red[400],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          "Remove Favorite",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to remove this doctor from favorites?",
                          style: GoogleFonts.poppins(),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              "Remove",
                              style: GoogleFonts.poppins(
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _removeFavorite(doctor.uid);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailPage(doctor: doctor),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Stack(
                        children: [
                          DoctorCard(doctor: doctor),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.favorite,
                                  color: Colors.red,
                                  size: 28),
                              onPressed: () => _removeFavorite(doctor.uid),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}