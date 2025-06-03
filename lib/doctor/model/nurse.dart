import 'dart:convert';
import 'package:flutter/material.dart';

class Nurse {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String city;
  final double latitude;
  final double longitude;
  final String? profileImageBase64;
  final String assignedDoctorId; // ID of the doctor this nurse is assigned to
  final String qualification;
  final String yearsOfExperience;

  Nurse({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.profileImageBase64,
    required this.assignedDoctorId,
    required this.qualification,
    required this.yearsOfExperience,
  });

  factory Nurse.fromMap(Map<dynamic, dynamic> map, String uid) {
    return Nurse(
      uid: uid,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      city: map['city'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      profileImageBase64: map['profileImageBase64'],
      assignedDoctorId: map['assignedDoctorId'] ?? '',
      qualification: map['qualification'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? '',
    );
  }

  // Helper method to convert base64 to Image widget
  ImageProvider? get profileImage {
    if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
      return null;
    }
    return MemoryImage(base64Decode(profileImageBase64!));
  }
}