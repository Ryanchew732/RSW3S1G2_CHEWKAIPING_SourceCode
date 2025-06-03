import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testing/doctor/model/doctor.dart';

class MyAppointmentPage extends StatefulWidget {
  final Doctor doctor;
  const MyAppointmentPage({super.key, required this.doctor});

  @override
  State<MyAppointmentPage> createState() => _MyAppointmentPageState();
}

class _MyAppointmentPageState extends State<MyAppointmentPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late DateTime _firstAvailableDate;
  Map<DateTime, List<String>> _bookedSlots = {};
  List<String> _availableTimeSlots = [];
  bool _isLoading = true;

  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance.ref().child('Appointments');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _firstAvailableDate = DateTime.now().add(Duration(days: 7));
    _fetchBookedAppointments();
  }

  Future<void> _fetchBookedAppointments() async {
    final snapshot = await _appointmentsRef.child(widget.doctor.uid).once();
    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> appointments = snapshot.snapshot.value as Map<dynamic, dynamic>;
      appointments.forEach((date, slots) {
        DateTime appointmentDate = DateTime.parse(date);
        List<String> bookedSlots = [];
        if (slots is Map) {
          slots.forEach((time, patientId) {
            bookedSlots.add(time);
          });
        }
        _bookedSlots[appointmentDate] = bookedSlots;
      });
    }
    setState(() {
      _isLoading = false;
      _updateAvailableTimeSlots();
    });
  }

  void _updateAvailableTimeSlots() {
    if (_selectedDay.isBefore(_firstAvailableDate)) {
      _availableTimeSlots = [];
      return;
    }

    // Get the day name (e.g., "Monday")
    String dayName = DateFormat('EEEE').format(_selectedDay);

    // Check if the doctor is available on this day
    if (widget.doctor.availability != null &&
        widget.doctor.availability!.containsKey(dayName)) {
      final availability = widget.doctor.availability![dayName]!;
      final startTime = availability['startTime'] ?? '08:00';
      final endTime = availability['endTime'] ?? '17:00';

      // Parse start and end times
      final startHour = int.parse(startTime.split(':')[0]);
      final endHour = int.parse(endTime.split(':')[0]);

      // Generate time slots with 1-hour intervals
      List<String> slots = [];
      for (int hour = startHour; hour < endHour; hour++) {
        slots.add('${hour.toString().padLeft(2, '0')}:00');
      }

      // Filter out booked slots
      final bookedSlots = _bookedSlots[_selectedDay] ?? [];
      _availableTimeSlots = slots.where((slot) => !bookedSlots.contains(slot)).toList();
    } else {
      _availableTimeSlots = [];
    }
  }

  Future<void> _bookAppointment(String timeSlot) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Format the date as YYYY-MM-DD for Firebase key
      String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay);

      await _appointmentsRef
          .child(widget.doctor.uid)
          .child(dateKey)
          .child(timeSlot)
          .set(userId);

      // Update local state
      if (!_bookedSlots.containsKey(_selectedDay)) {
        _bookedSlots[_selectedDay] = [];
      }
      _bookedSlots[_selectedDay]!.add(timeSlot);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _updateAvailableTimeSlots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _updateAvailableTimeSlots();
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              disabledDecoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            enabledDayPredicate: (day) {
              // Only allow dates from one week from now
              return day.isAfter(_firstAvailableDate.subtract(Duration(days: 1)));
            },
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Available Time Slots for ${DateFormat('EEEE, MMMM d').format(_selectedDay)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          if (_selectedDay.isBefore(_firstAvailableDate))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'You can only book appointments starting from ${DateFormat('MMMM d').format(_firstAvailableDate)}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            )
          else if (_availableTimeSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No available time slots for this day',
                style: GoogleFonts.poppins(),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                itemCount: _availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _availableTimeSlots[index];
                  return ElevatedButton(
                    onPressed: () => _bookAppointment(slot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      slot,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}