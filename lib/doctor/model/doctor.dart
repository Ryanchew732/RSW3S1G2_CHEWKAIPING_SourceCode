import 'dart:convert';
import 'package:flutter/cupertino.dart';

class Doctor {
  final String uid;
  final String category;
  final String city;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageBase64;
  final String qualification;
  final String phoneNumber;
  final String yearsOfExperience;
  final double latitude;
  final double longitude;
  final int numberOfReviews;
  final int totalReviews;
  Map<String, dynamic>? availability; // Changed to daily availability
  final String? aboutMe;

  Doctor({
    required this.uid,
    required this.category,
    required this.city,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageBase64,
    required this.qualification,
    required this.phoneNumber,
    required this.yearsOfExperience,
    required this.latitude,
    required this.longitude,
    required this.numberOfReviews,
    required this.totalReviews,
    this.availability,
    this.aboutMe,
  });

  factory Doctor.fromMap(Map<dynamic, dynamic> map, String uid) {
    // Handle availability conversion
    Map<String, dynamic>? availability;
    if (map['availability'] != null) {
      availability = {};
      final availData = Map<String, dynamic>.from(map['availability'] as Map);
      availData.forEach((dateStr, slots) {
        availability![dateStr] = (slots as List<dynamic>).map((slot) {
          return Map<String, String>.from(slot as Map);
        }).toList();
      });
    }

    return Doctor(
      uid: uid,
      category: map['category']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      profileImageBase64: map['profileImageBase64']?.toString(),
      qualification: map['qualification']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      yearsOfExperience: map['yearsOfExperience']?.toString() ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      numberOfReviews: (map['numberOfReviews'] ?? 0).toInt(),
      totalReviews: (map['totalReviews'] ?? 0).toInt(),
      aboutMe: map['aboutMe']?.toString(),
      availability: availability,
    );
  }

  ImageProvider? get profileImage {
    if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
      return null;
    }
    return MemoryImage(base64Decode(profileImageBase64!));
  }

  get specialty => null;
}