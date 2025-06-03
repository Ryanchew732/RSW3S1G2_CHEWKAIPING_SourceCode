import 'dart:convert';
import 'package:flutter/material.dart';

class Review {
  final String userId;
  final String userName;
  final String userProfileImage; // Can be a URL or base64
  final double rating;
  final String reviewText;
  final String date;

  Review({
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.rating,
    required this.reviewText,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'rating': rating,
      'reviewText': reviewText,
      'date': date,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userProfileImage: map['userProfileImage'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'] ?? '',
      date: map['date'] ?? '',
    );
  }

  // Helper method to get the image provider (Base64 or URL)
  ImageProvider get profileImage {

    if (userProfileImage.isEmpty) {
      return AssetImage('assets/default_profile.png'); // Fallback image
    } else if (userProfileImage.startsWith('http')) {
      return NetworkImage(userProfileImage);
    } else {
      return MemoryImage(base64Decode(userProfileImage));
    }
  }
}
