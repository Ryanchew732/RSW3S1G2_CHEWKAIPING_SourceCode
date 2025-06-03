import 'dart:convert';
import 'package:flutter/material.dart';

class Patient {
  final String city;
  final String email;
  final String firstName;
  final String lastName;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String? profileImageBase64; // Changed from URL to base64 and made nullable
  final String uid;

  Patient({
    required this.city,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.profileImageBase64, // Made optional
    required this.uid,
  });

  factory Patient.fromMap(Map<String, dynamic> data) {
    return Patient(
      city: data['city'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      phoneNumber: data['phoneNumber'] ?? '',
      profileImageBase64: data['profileImageBase64'], // Changed to read base64
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'profileImageBase64': profileImageBase64, // Changed to base64
      'uid': uid,
    };
  }

  // Helper method to convert base64 to Image widget
  ImageProvider? get profileImage {
    if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
      return null;
    }
    return MemoryImage(base64Decode(profileImageBase64!));
  }
}