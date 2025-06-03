import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    required this.appointmentId,
    Key? key,
  }) : super(key: key);

  @override
  _AppointmentDetailsScreenState createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic> _appointmentData = {};
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    try {
      // Load appointment data
      final snapshot = await FirebaseDatabase.instance
          .ref('Requests')
          .child(widget.appointmentId)
          .once();

      if (snapshot.snapshot.value != null) {
        setState(() {
          _appointmentData = Map<String, dynamic>.from(
              snapshot.snapshot.value as Map
          );
        });

        // Load doctor data
        final doctorSnapshot = await FirebaseDatabase.instance
            .ref('Doctors')
            .child(_appointmentData['receiver'])
            .once();

        if (doctorSnapshot.snapshot.value != null) {
          setState(() {
            _doctorData = Map<String, dynamic>.from(
                doctorSnapshot.snapshot.value as Map
            );
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointment details')),
      );
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final String googleMapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    if (await canLaunch(googleMapUrl)) {
      await launch(googleMapUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  Future<void> _cancelAppointment() async {
    try {
      // Show confirmation dialog
      bool confirmCancel = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cancel Appointment', style: GoogleFonts.poppins()),
          content: Text('Are you sure you want to cancel this appointment?',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes',
                  style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmCancel == true) {
        // Update appointment status in Firebase
        await FirebaseDatabase.instance
            .ref('Requests')
            .child(widget.appointmentId)
            .update({'status': 'cancelled'});

        // Update local state
        setState(() {
          _appointmentData['status'] = 'cancelled';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment cancelled successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: ${e.toString()}')),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Chip(
      label: Text(
        status,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...', style: GoogleFonts.poppins()),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
              SizedBox(height: 16),
              Text(
                'Loading appointment details...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Appointment Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        _buildStatusChip(_appointmentData['status'] ?? 'N/A'),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _appointmentData['date'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: _appointmentData['time'] ?? 'N/A',
                    ),
                    if (_appointmentData['description'] != null)
                      _buildDetailItem(
                        icon: Icons.note,
                        label: 'Notes',
                        value: _appointmentData['description'],
                        isMultiline: true,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Doctor Information Card
            if (_doctorData != null) ...[
              Text(
                'Doctor Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: Text(
                          'Dr. ${_doctorData!['firstName']} ${_doctorData!['lastName']}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _doctorData!['category'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Divider(height: 24),
                      _buildDoctorDetailItem(
                        icon: Icons.school,
                        label: 'Qualification',
                        value: _doctorData!['qualification'] ?? 'N/A',
                      ),
                      _buildDoctorDetailItem(
                        icon: Icons.work,
                        label: 'Years of Experience',
                        value: _doctorData!['yearsOfExperience'] ?? 'N/A',
                      ),
                      _buildDoctorDetailItem(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: _doctorData!['city'] ?? 'N/A',
                        showMap: true,
                        onMapPressed: () {
                          if (_doctorData!['latitude'] != null && _doctorData!['longitude'] != null) {
                            _openMap(
                                _doctorData!['latitude'].toDouble(),
                                _doctorData!['longitude'].toDouble()
                            );
                          }
                        },
                      ),
                      _buildDoctorDetailItem(
                        icon: Icons.phone,
                        label: 'Contact',
                        value: _doctorData!['phoneNumber'] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 20),

            // Action Buttons
            if (_appointmentData['status']?.toLowerCase() == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel Appointment',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool showMap = false,
    VoidCallback? onMapPressed,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showMap && onMapPressed != null)
            IconButton(
              icon: Icon(
                Icons.map,
                color: Colors.blue.shade700,
                size: 24,
              ),
              onPressed: onMapPressed,
            ),
        ],
      ),
    );
  }
}