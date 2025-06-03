import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:testing/doctor/model/Nurse.dart';
import 'package:testing/doctor/model/booking.dart';
import 'package:testing/doctor/model/doctor.dart';


class NurseCheckSchedulePage extends StatefulWidget {
  const NurseCheckSchedulePage({super.key});

  @override
  State<NurseCheckSchedulePage> createState() => _NurseCheckSchedulePageState();
}

class _NurseCheckSchedulePageState extends State<NurseCheckSchedulePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final DatabaseReference _requestDatabase = FirebaseDatabase.instance.ref('Requests');

  late TabController _tabController;
  bool _isLoading = true;

  // Data
  Nurse? _currentNurse;
  Doctor? _assignedDoctor;
  List<Booking> _upcomingAppointments = [];
  List<Booking> _completedAppointments = [];
  List<Booking> _canceledAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNurseData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNurseData() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Get nurse data
      final nurseSnapshot = await _database.child('Nurses').child(currentUserId).get();
      if (nurseSnapshot.exists) {
        _currentNurse = Nurse.fromMap(
          Map<String, dynamic>.from(nurseSnapshot.value as Map),
          currentUserId,
        );

        // Get assigned doctor data
        if (_currentNurse!.assignedDoctorId.isNotEmpty) {
          final doctorSnapshot = await _database.child('Doctors')
              .child(_currentNurse!.assignedDoctorId).get();
          if (doctorSnapshot.exists) {
            _assignedDoctor = Doctor.fromMap(
              Map<String, dynamic>.from(doctorSnapshot.value as Map),
              _currentNurse!.assignedDoctorId,
            );
            await _fetchDoctorAppointments();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching nurse data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDoctorAppointments() async {
    if (_assignedDoctor == null) return;

    try {
      final snapshot = await _requestDatabase
          .orderByChild('receiver')
          .equalTo(_assignedDoctor!.uid)
          .once();

      if (snapshot.snapshot.value != null) {
        final requestsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final allRequests = requestsMap.entries.map((entry) {
          return Booking.fromMap(Map<String, dynamic>.from(entry.value)..['id'] = entry.key);
        }).toList();

        setState(() {
          _upcomingAppointments = allRequests.where((r) => r.status == 'accepted').toList();
          _completedAppointments = allRequests.where((r) => r.status == 'completed').toList();
          _canceledAppointments = allRequests.where((r) => r.status == 'canceled').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return Colors.green;
      case 'completed': return Colors.blue;
      case 'canceled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return 'Upcoming';
      case 'completed': return 'Completed';
      case 'canceled': return 'Canceled';
      default: return status;
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

  Widget _buildAppointmentCard(Booking booking) {
    Color statusColor = _getStatusColor(booking.status ?? '');
    String statusText = _getStatusText(booking.status ?? '');
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF1A73E8)),
                  ),
                  child: Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _assignedDoctor?.category ?? 'General',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${booking.time} • ${_assignedDoctor?.city ?? ''}',
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
            const SizedBox(height: 12),
            if (booking.description?.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<Booking> appointments, String emptyMessage) {
    return appointments.isEmpty
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
      onRefresh: _fetchDoctorAppointments,
      color: Color(0xFF1A73E8),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor\'s Schedule',
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
          : _assignedDoctor == null
          ? Center(
        child: Text(
          'No doctor assigned',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList(_upcomingAppointments, 'No upcoming appointments'),
          _buildAppointmentList(_completedAppointments, 'No completed appointments'),
          _buildAppointmentList(_canceledAppointments, 'No canceled appointments'),
        ],
      ),
    );
  }
}