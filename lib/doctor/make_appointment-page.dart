import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/notification_service.dart';

class MakeAppointmentPage extends StatefulWidget {
  final Doctor doctor;

  const MakeAppointmentPage({super.key, required this.doctor});

  @override
  State<MakeAppointmentPage> createState() => _MakeAppointmentPageState();
}

class _MakeAppointmentPageState extends State<MakeAppointmentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _requestDatabase = FirebaseDatabase.instance.ref('Requests');
  final DatabaseReference _appointmentsDatabase = FirebaseDatabase.instance.ref('Appointments');
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _availableTimeSlots = [];
  Map<DateTime, List<String>> _bookedSlots = {};
  bool _isLoading = false;
  DateTime _firstAvailableDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _fetchBookedAppointments();
  }

  Future<void> _fetchBookedAppointments() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _appointmentsDatabase.child(widget.doctor.uid).once();
      if (snapshot.snapshot.value != null) {
        Map<DateTime, List<String>> tempBookedSlots = {};
        Map<dynamic, dynamic> appointments = snapshot.snapshot.value as Map<dynamic, dynamic>;

        appointments.forEach((date, slots) {
          try {
            DateTime appointmentDate = DateTime.parse(date);
            List<String> bookedSlots = [];
            if (slots is Map) {
              slots.forEach((time, patientId) {
                bookedSlots.add(time);
              });
            }
            tempBookedSlots[appointmentDate] = bookedSlots;
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }
        });

        setState(() => _bookedSlots = tempBookedSlots);
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateAvailableTimeSlots() {
    if (_selectedDate == null || _selectedDate!.isBefore(_firstAvailableDate)) {
      setState(() => _availableTimeSlots = []);
      return;
    }

    // Check if doctor has availability for the selected date
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    if (widget.doctor.availability == null || !widget.doctor.availability!.containsKey(dateStr)) {
      setState(() => _availableTimeSlots = []);
      return;
    }

    final availableSlots = widget.doctor.availability![dateStr]!;
    final bookedSlots = _bookedSlots[_selectedDate!] ?? [];

    List<String> allSlots = [];

    // Generate all possible time slots based on doctor's availability
    for (var slot in availableSlots) {
      final startTime = slot['start']!.split(':');
      final endTime = slot['end']!.split(':');

      final startHour = int.parse(startTime[0]);
      final startMin = int.parse(startTime[1]);
      final endHour = int.parse(endTime[0]);
      final endMin = int.parse(endTime[1]);

      // Generate slots in 30-minute intervals
      int currentHour = startHour;
      int currentMin = startMin;

      while (currentHour < endHour || (currentHour == endHour && currentMin < endMin)) {
        final timeSlot = '${currentHour.toString().padLeft(2, '0')}:${currentMin.toString().padLeft(2, '0')}';

        // Only add if not already booked
        if (!bookedSlots.contains(timeSlot)) {
          allSlots.add(timeSlot);
        }

        // Increment time by 30 minutes
        currentMin += 30;
        if (currentMin >= 60) {
          currentMin = 0;
          currentHour++;
        }
      }
    }

    setState(() {
      _availableTimeSlots = allSlots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Appointment',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorInfoCard(),
              const SizedBox(height: 32),
              _buildDateSelectionSection(),
              const SizedBox(height: 28),
              _buildTimeSelectionSection(),
              const SizedBox(height: 28),
              _buildDescriptionSection(),
              const SizedBox(height: 32),
              _buildConfirmButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
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
                  : const Icon(Icons.person, size: 40, color: Color(0xFF5F6368)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${widget.doctor.firstName} ${widget.doctor.lastName}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Select a date'
                          : DateFormat('MMMM yyyy').format(_selectedDate!),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF1A73E8)),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
              _buildCalendar(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedDate == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Please select a date first'),
          )
        else if (_selectedDate!.isBefore(_firstAvailableDate))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'You can only book appointments starting from ${DateFormat('MMM d, yyyy').format(_firstAvailableDate)}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          )
        else if (_availableTimeSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.doctor.availability == null
                    ? 'Doctor has not set availability'
                    : 'No available time slots for this day',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _availableTimeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _availableTimeSlots[index];
                final isBooked = _bookedSlots[_selectedDate!]?.contains(timeSlot) ?? false;

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => setState(() => _selectedTime = timeSlot),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey.shade300
                          : _selectedTime == timeSlot
                          ? const Color(0xFF1A73E8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBooked
                            ? Colors.grey.shade400
                            : _selectedTime == timeSlot
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeSlot,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: _selectedTime == timeSlot
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isBooked
                                ? Colors.grey.shade600
                                : _selectedTime == timeSlot
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        if (isBooked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Booked',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _descriptionController,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your description here...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          shadowColor: const Color(0xFF1A73E8).withOpacity(0.3),
        ),
        onPressed: _bookAppointment,
        child: Text(
          'CONFIRM APPOINTMENT',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    DateTime now = DateTime.now();
    DateTime currentDate = _selectedDate ?? now;
    int daysInMonth = DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
    DateTime firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    int startingWeekday = firstDayOfMonth.weekday;

    List<Widget> dayWidgets = [];

    // Add day headers
    dayWidgets.addAll(['S', 'M', 'T', 'W', 'T', 'F', 'S']
        .map((day) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        day,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
      ),
    ))
        .toList());

    // Add empty cells for days before the first of the month
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Add day numbers
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime dayDate = DateTime(currentDate.year, currentDate.month, day);
      bool isSelected = _selectedDate != null &&
          _selectedDate!.year == dayDate.year &&
          _selectedDate!.month == dayDate.month &&
          _selectedDate!.day == dayDate.day;
      bool isToday = now.year == dayDate.year &&
          now.month == dayDate.month &&
          now.day == dayDate.day;
      bool isPast = dayDate.isBefore(DateTime(now.year, now.month, now.day));
      bool isBeforeMinDate = dayDate.isBefore(_firstAvailableDate);

      // Check if doctor is available on this date
      final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
      bool isAvailable = widget.doctor.availability != null &&
          widget.doctor.availability!.containsKey(dateStr);

      dayWidgets.add(
        GestureDetector(
          onTap: isPast || isBeforeMinDate || !isAvailable
              ? null
              : () {
            setState(() {
              _selectedDate = dayDate;
              _selectedTime = null;
              _updateAvailableTimeSlots();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A73E8)
                  : isToday
                  ? const Color(0xFFE8F0FE)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFF1A73E8), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : isPast || isBeforeMinDate || !isAvailable
                          ? Colors.grey.shade400
                          : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (!isPast && !isBeforeMinDate && isAvailable)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: dayWidgets.length,
      itemBuilder: (context, index) => dayWidgets[index],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _firstAvailableDate,
      firstDate: _firstAvailableDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1A73E8),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _updateAvailableTimeSlots();
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null || _descriptionController.text.isEmpty) {
      _showValidationErrorDialog();
      return;
    }

    final date = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final time = _selectedTime!;
    final timeKey = time.replaceAll(':', ''); // Convert "09:00" to "0900"

    // First check if the slot is still available
    final slotSnapshot = await _appointmentsDatabase
        .child(widget.doctor.uid)
        .child(date)
        .child(timeKey)
        .once();

    if (slotSnapshot.snapshot.value != null) {
      // Slot is already booked by someone else
      _showSlotAlreadyBookedDialog();
      return;
    }

    final description = _descriptionController.text;
    final requestId = _requestDatabase.push().key!;
    final currentUserId = _auth.currentUser!.uid;
    final receiverId = widget.doctor.uid;
    final status = 'pending';

    try {
      // First mark the time slot as booked
      await _appointmentsDatabase
          .child(widget.doctor.uid)
          .child(date)
          .child(timeKey)
          .set(currentUserId);

      // Then save the appointment request
      await _requestDatabase.child(requestId).set({
        'date': date,
        'time': time,
        'description': description,
        'id': requestId,
        'receiver': receiverId,
        'sender': currentUserId,
        'status': status,
        'createdAt': ServerValue.timestamp,
      });

      // Send notifications
      final user = _auth.currentUser;
      if (user != null) {
        // Get user's first and last name (you'll need to implement this)
        // For this example, I'll assume you have these values
        String userFirstName = 'Patient'; // Replace with actual first name
        String userLastName = ''; // Replace with actual last name

        // Notification for doctor
        await NotificationService.createAppointmentNotification(
          receiverId: widget.doctor.uid,
          senderId: currentUserId,
          otherPartyName: '$userFirstName $userLastName',
          action: 'requested',
          requestId: requestId,
          appointmentDate: date,
          appointmentTime: time,
          isForDoctor: true,
        );

        // Notification for patient
        await NotificationService.createAppointmentNotification(
          receiverId: currentUserId,
          senderId: widget.doctor.uid,
          otherPartyName: 'Dr. ${widget.doctor.firstName} ${widget.doctor.lastName}',
          action: 'booked',
          requestId: requestId,
          appointmentDate: date,
          appointmentTime: time,
          isForDoctor: false,
        );
      }

      // Update local state
      setState(() {
        if (!_bookedSlots.containsKey(_selectedDate!)) {
          _bookedSlots[_selectedDate!] = [];
        }
        _bookedSlots[_selectedDate!]!.add(time);
        _availableTimeSlots.remove(time);
      });

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog();
      debugPrint('Error booking appointment: $e');
    }
  }

  void _showSlotAlreadyBookedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Time Slot Booked',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This time slot has already been booked by someone else. Please choose another time.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedTime = null;
                _updateAvailableTimeSlots();
              });
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Appointment Booked!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your appointment has been successfully booked for ${DateFormat('MMM d, yyyy').format(_selectedDate!)} at $_selectedTime.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Booking Failed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Failed to book your appointment. Please try again.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showValidationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Missing Information',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please complete all required fields:\n'
              '- Select a date\n'
              '- Select an available time\n'
              '- Add a description',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}