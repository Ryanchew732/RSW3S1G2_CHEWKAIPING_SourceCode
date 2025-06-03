import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:testing/doctor/doctor_details_page.dart';
import 'package:testing/doctor/make_appointment-page.dart';
import 'package:testing/doctor/model/booking.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _requestDatabase = FirebaseDatabase.instance.ref('Requests');
  final DatabaseReference _doctorDatabase = FirebaseDatabase.instance.ref('Doctors');
  List<Booking> _bookings = [];
  Map<String, Doctor> _doctorMap = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      try {
        // Fetch bookings
        final bookingEvent = await _requestDatabase
            .orderByChild('sender')
            .equalTo(currentUserId)
            .once();

        if (bookingEvent.snapshot.value != null) {
          Map<dynamic, dynamic> bookingMap = bookingEvent.snapshot.value as Map<dynamic, dynamic>;
          List<Booking> tempBookings = [];

          // Collect all doctor IDs first
          Set<String> doctorIds = {};
          bookingMap.forEach((key, value) {
            var booking = Booking.fromMap(Map<String, dynamic>.from(value));
            tempBookings.add(booking);
            doctorIds.add(booking.receiver);
          });

          // Fetch all doctors in one go
          final doctorEvent = await _doctorDatabase.once();
          if (doctorEvent.snapshot.value != null) {
            Map<dynamic, dynamic> allDoctors = doctorEvent.snapshot.value as Map<dynamic, dynamic>;
            allDoctors.forEach((key, value) {
              if (doctorIds.contains(key)) {
                _doctorMap[key] = Doctor.fromMap(Map<String, dynamic>.from(value), key);
              }
            });
          }

          setState(() {
            _bookings = tempBookings;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }
      return "Unknown location";
    } catch (e) {
      print("Error getting address: $e");
      return "Location available";
    }
  }

  Widget _buildBookingCard(Booking booking) {
    Doctor? doctor = _doctorMap[booking.receiver];
    if (doctor == null) return Container();

    String status = _getBookingStatus(booking.status);
    Color statusColor = _getStatusColor(booking.status);
    String statusText = _getStatusText(booking.status);
    String formattedDate = _formatDate(booking.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (doctor != null) {
            _navigateToDoctorDetailPage(doctor);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Doctor Information
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF1A73E8)),
                    ),
                    child: doctor.profileImageBase64 != null &&
                        doctor.profileImageBase64!.isNotEmpty
                        ? ClipOval(
                      child: Image.memory(
                        base64Decode(doctor.profileImageBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(Icons.person, size: 30, color: Colors.grey),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.firstName} ${doctor.lastName}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          doctor.category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${doctor.city} • ${booking.time}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _openMap(doctor.latitude, doctor.longitude),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description/Note
              if (booking.description != null && booking.description!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Action Buttons based on status
              if (status == 'pending' || status == 'accepted')
                Center(
                  child: _buildActionButton(
                    text: 'Cancel',
                    color: Colors.red,
                    onPressed: () => _cancelBooking(booking.id),
                  ),
                ),
              if (status == 'completed')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      text: 'Add Review',
                      color: Colors.green,
                      onPressed: () => _addReview(doctor),
                    ),
                    _buildActionButton(
                      text: 'Book Again',
                      color: Colors.blue,
                      onPressed: () => _rebookAppointment(doctor),
                    ),
                  ],
                ),
              if (status == 'rejected' || status == 'canceled')
                Center(
                  child: _buildActionButton(
                    text: 'Book Again',
                    color: Colors.blue,
                    onPressed: () => _rebookAppointment(doctor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addReview(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailPage(doctor: doctor),
      ),
    );
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final String googleMapUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    if (await canLaunch(googleMapUrl)) {
      await launch(googleMapUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'pending';
      case 'accepted':
        return 'accepted';
      case 'rejected':
        return 'rejected';
      case 'completed':
        return 'completed';
      case 'canceled':
        return 'canceled';
      case 'doctor_canceled':
        return 'doctor_canceled';
      default:
        return status;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'canceled':
        return 'Canceled';
      case 'doctor_canceled':
        return 'Doctor Canceled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'canceled':
        return Colors.red;
      case 'doctor_canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateFormat('MM/dd/yyyy').parse(dateString);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _cancelBooking(String bookingId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text('Are you sure you want to cancel this appointment?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final bookingSnapshot = await _requestDatabase.child(bookingId).once();
              if (bookingSnapshot.snapshot.value != null) {
                final booking = Booking.fromMap(
                  Map<String, dynamic>.from(bookingSnapshot.snapshot.value as Map)
                    ..['id'] = bookingId,
                );

                final doctor = _doctorMap[booking.receiver];
                final currentUser = _auth.currentUser;

                if (currentUser == null || doctor == null) return;

                await _requestDatabase.child(bookingId).update({'status': 'canceled'});

                await FirebaseDatabase.instance.ref('Appointments')
                    .child(booking.receiver)
                    .child(booking.date)
                    .child(booking.time.replaceAll(':', ''))
                    .remove();

                await NotificationService.createAppointmentNotification(
                  receiverId: booking.receiver,
                  senderId: currentUser.uid,
                  otherPartyName: 'Patient Name',
                  action: 'canceled',
                  requestId: bookingId,
                  appointmentDate: booking.date,
                  appointmentTime: booking.time,
                  isForDoctor: true,
                );

                await NotificationService.createAppointmentNotification(
                  receiverId: currentUser.uid,
                  senderId: booking.receiver,
                  otherPartyName: 'Dr. ${doctor.firstName} ${doctor.lastName}',
                  action: 'canceled',
                  requestId: bookingId,
                  appointmentDate: booking.date,
                  appointmentTime: booking.time,
                  isForDoctor: false,
                );
              }

              Navigator.pop(context);
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment canceled'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _rebookAppointment(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeAppointmentPage(doctor: doctor),
      ),
    );
  }

  void _navigateToDoctorDetailPage(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailPage(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Booking> upcoming = _bookings.where((b) =>
    _getBookingStatus(b.status) == 'pending' ||
        _getBookingStatus(b.status) == 'accepted').toList();
    List<Booking> completed = _bookings.where((b) =>
    _getBookingStatus(b.status) == 'completed').toList();
    List<Booking> canceled = _bookings.where((b) =>
    _getBookingStatus(b.status) == 'rejected' ||
        _getBookingStatus(b.status) == 'canceled' ||
        _getBookingStatus(b.status) == 'doctor_canceled').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1A73E8),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
          ],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A73E8),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(upcoming, 'No upcoming appointments'),
          _buildBookingList(completed, 'No completed appointments'),
          _buildBookingList(canceled, 'No canceled appointments'),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyMessage) {
    return bookings.isEmpty
        ? Center(
      child: Text(
        emptyMessage,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
    )
        : RefreshIndicator(
      onRefresh: _fetchData,
      color: Color(0xFF1A73E8),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 20),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }
}