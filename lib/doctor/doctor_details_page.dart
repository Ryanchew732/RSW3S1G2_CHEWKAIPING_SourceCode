// doctor_details_page.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/doctor/make_appointment-page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat_screen.dart';
import 'model/doctor.dart';
import 'model/review.dart';

class DoctorDetailPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _reviewsDatabase = FirebaseDatabase.instance.ref('Reviews');
  final DatabaseReference _favoritesDatabase = FirebaseDatabase.instance.ref('Favorites');

  List<Review> reviews = [];
  bool isLoadingReviews = true;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  bool _isCheckingFavorite = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => _isCheckingFavorite = false);
      return;
    }

    setState(() => _isFavoriteLoading = true);
    try {
      final snapshot = await _favoritesDatabase.child(userId).child(widget.doctor.uid).get();
      setState(() {
        _isFavorite = snapshot.exists && snapshot.value == true;
        _isFavoriteLoading = false;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      setState(() {
        _isFavoriteLoading = false;
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add favorites')),
      );
      return;
    }

    setState(() => _isFavoriteLoading = true);
    try {
      if (_isFavorite) {
        await _favoritesDatabase.child(userId).child(widget.doctor.uid).remove();
      } else {
        await _favoritesDatabase.child(userId).child(widget.doctor.uid).set(true);
      }
      setState(() => _isFavorite = !_isFavorite);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorites')),
      );
    } finally {
      setState(() => _isFavoriteLoading = false);
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => isLoadingReviews = true);
    try {
      final reviewsSnapshot = await _reviewsDatabase.child(widget.doctor.uid).get();
      if (reviewsSnapshot.exists) {
        Map<dynamic, dynamic> reviewsMap = reviewsSnapshot.value as Map<dynamic, dynamic>;
        List<Review> tempReviews = [];
        reviewsMap.forEach((key, value) {
          tempReviews.add(Review.fromMap(Map<String, dynamic>.from(value)));
        });
        setState(() {
          reviews = tempReviews;
          isLoadingReviews = false;
        });
      } else {
        setState(() => isLoadingReviews = false);
      }
    } catch (e) {
      setState(() => isLoadingReviews = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reviews: $e')),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open dialer')),
        );
      }
    }
  }

  void _openMap() async {
    final String googleMapUrl =
        'https://www.google.com/maps/search/?api=1&query=${widget.doctor.latitude},${widget.doctor.longitude}';
    if (await canLaunchUrl(Uri.parse(googleMapUrl))) {
      await launchUrl(Uri.parse(googleMapUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isCheckingFavorite)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red[400] : Colors.white,
              ),
              onPressed: _isFavoriteLoading ? null : _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD2E3FC), width: 2),
                          ),
                          child: widget.doctor.profileImageBase64 != null &&
                              widget.doctor.profileImageBase64!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(widget.doctor.profileImageBase64!),
                              fit: BoxFit.cover,
                            ),
                          )
                              : Icon(Icons.person, size: 50, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.doctor.firstName} ${widget.doctor.lastName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.doctor.category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A73E8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 18, color: Colors.orange.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.doctor.city,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.call,
                                    color: Colors.green,
                                    onPressed: () => _makePhoneCall(widget.doctor.phoneNumber),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionButton(
                                    icon: Icons.chat,
                                    color: const Color(0xFF1A73E8),
                                    onPressed: () {
                                      String currentUserId = _auth.currentUser?.uid ?? '';
                                      String docName = '${widget.doctor.firstName} ${widget.doctor.lastName}';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            doctorId: widget.doctor.uid,
                                            doctorName: docName,
                                            patientId: currentUserId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About Me Section
            if (widget.doctor.aboutMe != null && widget.doctor.aboutMe!.isNotEmpty) ...[
              _buildSectionHeader('About Me'),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor.aboutMe!,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.medical_services, size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Specialty: ${widget.doctor.category}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.school, size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Qualification: ${widget.doctor.qualification}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.work, size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Experience: ${widget.doctor.yearsOfExperience} years',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildBigButton(
              icon: Icons.map,
              text: 'VIEW LOCATION ON MAP',
              color: Colors.orange,
              onPressed: _openMap,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Patient Reviews'),
            const SizedBox(height: 12),
            isLoadingReviews
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade600))
                : ReviewsSection(reviews: reviews),
            const SizedBox(height: 16),
            _buildBigButton(
              icon: Icons.edit,
              text: 'LEAVE A REVIEW',
              color: Colors.orange,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ReviewDialog(
                    onSubmit: (reviewText, rating) {
                      _addReview(reviewText, rating);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildBigButton(
              icon: Icons.calendar_today,
              text: 'BOOK APPOINTMENT',
              color: const Color(0xFF1A73E8),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MakeAppointmentPage(
                      doctor: widget.doctor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addReview(String reviewText, double rating) {
    String userId = _auth.currentUser?.uid ?? '';
    String userName = 'Anonymous';
    String userProfileImage = '';

    final newReview = Review(
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      rating: rating,
      reviewText: reviewText,
      date: DateTime.now().toIso8601String(),
    );

    _reviewsDatabase.child(widget.doctor.uid).push().set(newReview.toMap()).then((_) {
      setState(() {
        reviews.add(newReview);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $error')),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBigButton({required IconData icon, required String text, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewDialog extends StatelessWidget {
  final Function(String reviewText, double rating) onSubmit;
  final TextEditingController reviewController = TextEditingController();
  double rating = 5.0;

  ReviewDialog({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Leave a Review',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Rating:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  Expanded(
                    child: Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: Colors.orange,
                      inactiveColor: Colors.grey.shade300,
                      label: rating.toStringAsFixed(1),
                      onChanged: (value) => setState(() => rating = value),
                    ),
                  ),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () {
            onSubmit(reviewController.text, rating);
            Navigator.pop(context);
          },
          child: Text(
            'SUBMIT',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class ReviewsSection extends StatelessWidget {
  final List<Review> reviews;

  const ReviewsSection({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    double averageRating = reviews.isEmpty ? 0 : reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 6),
            Text(
              averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 200,
          ),
          child: reviews.isEmpty
              ? Center(
            child: Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: reviews.length > 2 ? 2 : reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ReviewTile(review: review);
            },
          ),
        ),
        if (reviews.length > 2) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'All Reviews',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          return ReviewTile(review: reviews[index]);
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.poppins(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
              child: Text(
                'View All Reviews',
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade50,
          backgroundImage: review.userProfileImage.isNotEmpty
              ? NetworkImage(review.userProfileImage)
              : null,
          child: review.userProfileImage.isEmpty
              ? Icon(Icons.person, size: 24, color: Colors.blue.shade600)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 18,
                    color: index < review.rating.floor()
                        ? Colors.amber
                        : Colors.grey.shade300,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                review.reviewText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateTime.parse(review.date).day}/${DateTime.parse(review.date).month}/${DateTime.parse(review.date).year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}