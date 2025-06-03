// doctor_requests_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:testing/doctor/model/booking.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/doctor/model/patient.dart';
import 'package:testing/notification_service.dart';

class DoctorRequestsPage extends StatefulWidget {
  const DoctorRequestsPage({super.key});

  @override
  State<DoctorRequestsPage> createState() => _DoctorRequestsPageState();
}

class _DoctorRequestsPageState extends State<DoctorRequestsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _requestDatabase = FirebaseDatabase.instance.ref('Requests');
  final DatabaseReference _appointmentsDatabase = FirebaseDatabase.instance.ref('Appointments');
  final DatabaseReference _patientDatabase = FirebaseDatabase.instance.ref('Patients');
  final DatabaseReference _doctorDatabase = FirebaseDatabase.instance.ref('Doctors');
  final DatabaseReference _notificationRef = FirebaseDatabase.instance.ref('Notifications');

  List<Booking> _pendingRequests = [];
  List<Booking> _upcomingAppointments = [];
  List<Booking> _completedAppointments = [];
  List<Booking> _canceledAppointments = [];
  List<Booking> _rejectedAppointments = [];

  Map<String, Patient> _patientMap = {};
  Doctor? _currentDoctor;
  bool _isLoading = true;
  bool _isRefreshing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchDoctorData().then((_) => _fetchAllAppointments());
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupNotificationListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _notificationRef.child(user.uid).onChildAdded.listen((event) {
        _fetchAllAppointments();
      });
    }
  }

  Future<void> _fetchDoctorData() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final snapshot = await _doctorDatabase.child(currentUserId).once();
    if (snapshot.snapshot.value != null) {
      setState(() {
        _currentDoctor = Doctor.fromMap(
          Map<String, dynamic>.from(snapshot.snapshot.value as Map),
          currentUserId,
        );
      });
    }
  }

  Future<void> _fetchAllAppointments() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final snapshot = await _requestDatabase
          .orderByChild('receiver')
          .equalTo(currentUserId)
          .once();

      if (snapshot.snapshot.value != null) {
        final requestsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final allRequests = requestsMap.entries.map((entry) {
          return Booking.fromMap(Map<String, dynamic>.from(entry.value)..['id'] = entry.key);
          }).toList();

        // Fetch patient details for all requests
        Set<String> patientIds = allRequests.map((r) => r.sender).toSet();
        await _fetchPatients(patientIds);

        // Categorize requests
        _pendingRequests = allRequests.where((r) => r.status == 'pending').toList();
        _upcomingAppointments = allRequests.where((r) => r.status == 'accepted').toList();
        _completedAppointments = allRequests.where((r) => r.status == 'completed').toList();
        _canceledAppointments = allRequests.where((r) => r.status == 'canceled').toList();
        _rejectedAppointments = allRequests.where((r) => r.status == 'rejected').toList();
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading appointments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _fetchPatients(Set<String> patientIds) async {
    try {
      final snapshot = await _patientDatabase.once();
      if (snapshot.snapshot.value != null) {
        final allPatients = snapshot.snapshot.value as Map<dynamic, dynamic>;
        allPatients.forEach((key, value) {
          if (patientIds.contains(key)) {
            _patientMap[key] = Patient.fromMap(Map<String, dynamic>.from(value));
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    }
  }

  Future<void> _updateRequestStatus(String requestId, String action) async {
    try {
      Booking request;
      Patient? patient;
      String newStatus;
      String notificationType;
      String notificationTitle;
      String notificationBody;

      if (action == 'accept') {
        request = _pendingRequests.firstWhere((r) => r.id == requestId);
        newStatus = 'accepted';
        notificationType = 'appointment_accepted';
        notificationTitle = 'Appointment Accepted';
        notificationBody = 'Dr. ${_currentDoctor?.firstName} ${_currentDoctor?.lastName} has accepted your appointment request';
      } else if (action == 'reject') {
        request = _pendingRequests.firstWhere((r) => r.id == requestId);
        newStatus = 'rejected';
        notificationType = 'appointment_rejected';
        notificationTitle = 'Appointment Rejected';
        notificationBody = 'Dr. ${_currentDoctor?.firstName} ${_currentDoctor?.lastName} has rejected your appointment request';
      } else if (action == 'complete') {
        request = _upcomingAppointments.firstWhere((r) => r.id == requestId);
        newStatus = 'completed';
        notificationType = 'appointment_completed';
        notificationTitle = 'Appointment Completed';
        notificationBody = 'Your appointment with Dr. ${_currentDoctor?.firstName} ${_currentDoctor?.lastName} has been marked as completed';
      } else {
        request = _upcomingAppointments.firstWhere((r) => r.id == requestId);
        newStatus = 'canceled';
        notificationType = 'appointment_canceled';
        notificationTitle = 'Appointment Canceled';
        notificationBody = 'Dr. ${_currentDoctor?.firstName} ${_currentDoctor?.lastName} has canceled your upcoming appointment';
      }

      patient = _patientMap[request.sender];

      // Update the request status in database
      await _requestDatabase.child(requestId).update({
        'status': newStatus,
        'updatedAt': ServerValue.timestamp,
      });

      // Create notifications using the service
      if (patient != null && _currentDoctor != null) {
        await NotificationService.createAppointmentNotification(
          receiverId: request.sender,
          senderId: _currentDoctor!.uid,
          otherPartyName: 'Dr. ${_currentDoctor!.firstName} ${_currentDoctor!.lastName}',
          action: action,
          requestId: requestId,
          appointmentDate: request.date,
          appointmentTime: request.time,
          isForDoctor: false,
        );

        // Notification for doctor's own records
        await NotificationService.createAppointmentNotification(
          receiverId: _currentDoctor!.uid,
          senderId: request.sender,
          otherPartyName: '${patient.firstName} ${patient.lastName}',
          action: action == 'cancel' ? 'doctor_canceled' : action,
          requestId: requestId,
          appointmentDate: request.date,
          appointmentTime: request.time,
          isForDoctor: true,
        );
      }

      await _fetchAllAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getStatusUpdateMessage(action)),
          backgroundColor: _getActionColor(action),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error updating request status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _getStatusUpdateMessage(String action) {
    switch (action) {
      case 'accept': return 'Appointment accepted successfully';
      case 'reject': return 'Appointment rejected';
      case 'complete': return 'Appointment marked as completed';
      case 'cancel': return 'Appointment canceled';
      default: return 'Appointment updated';
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'accept':
      case 'complete': return Colors.green;
      case 'reject':
      case 'cancel': return Colors.red;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'completed': return Colors.blue;
      case 'canceled': return Colors.red;
      case 'rejected': return Colors.red;
      case 'upcoming': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'completed': return 'Completed';
      case 'canceled': return 'Canceled';
      case 'rejected': return 'Rejected';
      case 'upcoming': return 'Upcoming';
      default: return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateString);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildBookingCard(Booking booking, Patient? patient, bool isRequest,
      {bool isUpcoming = false}) {
    final status = booking.status ?? '';
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);
    String formattedDate = _formatDate(booking.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A73E8)),
                  ),
                  child: patient?.profileImageBase64 != null &&
                      patient!.profileImageBase64!.isNotEmpty
                      ? ClipOval(
                    child: Image.memory(
                      base64Decode(patient.profileImageBase64!),
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient != null
                            ? '${patient.firstName} ${patient.lastName}'.trim()
                            : 'Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${booking.time} • ${patient?.city ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                'Notes:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                booking.description!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (isRequest || isUpcoming) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isRequest) ...[
                    Expanded(
                      child: _buildActionButton(
                        text: 'Accept',
                        icon: Icons.check,
                        color: Colors.green,
                        onPressed: () => _showConfirmationDialog(
                          context,
                          booking.id!,
                          'accept',
                          'Accept Appointment',
                          'Are you sure you want to accept this appointment request from ${patient?.firstName ?? 'the patient'}?',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        text: 'Reject',
                        icon: Icons.close,
                        color: Colors.red,
                        onPressed: () => _showConfirmationDialog(
                          context,
                          booking.id!,
                          'reject',
                          'Reject Appointment',
                          'Are you sure you want to reject this appointment request from ${patient?.firstName ?? 'the patient'}?',
                        ),
                      ),
                    ),
                  ] else if (isUpcoming) ...[
                    Expanded(
                      child: _buildActionButton(
                        text: 'Complete',
                        icon: Icons.done_all,
                        color: Colors.blue,
                        onPressed: () => _showConfirmationDialog(
                          context,
                          booking.id!,
                          'complete',
                          'Complete Appointment',
                          'Mark this appointment with ${patient?.firstName ?? 'the patient'} as completed?',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        text: 'Cancel',
                        icon: Icons.cancel,
                        color: Colors.red,
                        onPressed: () => _showConfirmationDialog(
                          context,
                          booking.id!,
                          'cancel',
                          'Cancel Appointment',
                          'Are you sure you want to cancel this appointment with ${patient?.firstName ?? 'the patient'}?',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context,
      String requestId,
      String action,
      String title,
      String message,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(requestId, action);
            },
            child: Text(
              action == 'reject' || action == 'cancel' ? 'Confirm' : 'Yes',
              style: GoogleFonts.poppins(
                color: _getActionColor(action),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
            Tab(text: 'Rejected'),
          ],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          isScrollable: true,
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF1A73E8),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAllAppointments,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingList(_pendingRequests, 'No pending appointment requests'),
            _buildBookingList(_upcomingAppointments, 'No upcoming appointments scheduled'),
            _buildBookingList(_completedAppointments, 'No completed appointments'),
            _buildBookingList(_canceledAppointments, 'No canceled appointments'),
            _buildBookingList(_rejectedAppointments, 'No rejected appointments'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyMessage) {
    return bookings.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final patient = _patientMap[booking.sender];
        bool isRequest = _tabController.index == 0;
        bool isUpcoming = _tabController.index == 1;
        return _buildBookingCard(booking, patient, isRequest, isUpcoming: isUpcoming);
      },
    );
  }
}