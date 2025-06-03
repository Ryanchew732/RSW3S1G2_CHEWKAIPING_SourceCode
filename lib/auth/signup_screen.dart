import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';

import '../doctor/doctor_home_page.dart';
import '../nurse/nurse_home_page.dart';
import '../patient/patient_home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final _formKey = GlobalKey<FormState>();
  String userType = 'Patient';
  String email = '';
  String password = '';
  String phoneNumber = '';
  String firstName = '';
  String lastName = '';
  String city = 'Kuala Lumpur';
  String profileImageBase64 = '';
  String category = 'General';
  String qualification = '';
  String yearsOfExperience = '';
  double latitude = 0.0;
  double longitude = 0.0;
  String? selectedDoctorId;
  List<Map<String, dynamic>> availableDoctors = [];
  String aboutMe = '';

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final Location _location = Location();
  bool _isLoading = false;
  bool _obscureText = true;

  // Availability variables
  Map<DateTime, List<Map<String, String>>> _availability = {};
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    if (userType == 'Nurse') {
      _fetchDoctors();
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      DataSnapshot snapshot = await _database.child('Doctors').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> doctorsMap = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          availableDoctors = doctorsMap.entries.map((entry) {
            return {
              'id': entry.key,
              'name': '${entry.value['firstName']} ${entry.value['lastName']}',
              'specialty': entry.value['category'] ?? 'General',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue.shade600),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImagePicker(),
                const SizedBox(height: 30),
                _buildUserTypeSelector(),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => email = val,
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Password',
                  obscureText: _obscureText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  ),
                  onChanged: (val) => password = val,
                  validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => phoneNumber = val,
                  validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'First Name',
                        onChanged: (val) => firstName = val,
                        validator: (val) => val!.isEmpty ? 'Enter first name' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: 'Last Name',
                        onChanged: (val) => lastName = val,
                        validator: (val) => val!.isEmpty ? 'Enter last name' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDropdown(
                  label: 'City',
                  value: city,
                  items: ['Kuala Lumpur', 'Shah Alam', 'Petaling Jaya', 'Subang Jaya', 'Klang'],
                  onChanged: (val) => setState(() => city = val!),
                ),
                if (userType == 'Doctor') ...[
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Qualification',
                    onChanged: (val) => qualification = val,
                    validator: (val) => val!.isEmpty ? 'Enter qualification' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    label: 'Category',
                    value: category,
                    items: ['Dentist', 'Cardiology', 'Oncology', 'Surgeon', 'General'],
                    onChanged: (val) => setState(() => category = val!),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Years of Experience',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => yearsOfExperience = val,
                    validator: (val) => val!.isEmpty ? 'Enter years of experience' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'About Me (max 30 words)',
                    maxLines: 3,
                    onChanged: (val) => aboutMe = val,
                    validator: (val) {
                      if (val != null && val.split(' ').length > 30) {
                        return 'Please limit to 30 words';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDoctorAvailabilitySelector(),
                ],
                if (userType == 'Nurse') ...[
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Qualification',
                    onChanged: (val) => qualification = val,
                    validator: (val) => val!.isEmpty ? 'Enter qualification' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Years of Experience',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => yearsOfExperience = val,
                    validator: (val) => val!.isEmpty ? 'Enter years of experience' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildDoctorDropdown(),
                ],
                const SizedBox(height: 20),
                _buildLocationButton(),
                if (latitude != 0.0 && longitude != 0.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Location: (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildRegisterButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: _imageFile != null
                ? Image.file(
              File(_imageFile!.path),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            )
                : Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select User Type',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Patient'),
                selected: userType == 'Patient',
                onSelected: (selected) {
                  setState(() {
                    userType = selected ? 'Patient' : userType;
                  });
                },
                selectedColor: Colors.blue.shade600,
                backgroundColor: Colors.grey.shade100,
                labelStyle: GoogleFonts.poppins(
                  color: userType == 'Patient' ? Colors.white : Colors.black,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Doctor'),
                selected: userType == 'Doctor',
                onSelected: (selected) {
                  setState(() {
                    userType = selected ? 'Doctor' : userType;
                  });
                },
                selectedColor: Colors.blue.shade600,
                backgroundColor: Colors.grey.shade100,
                labelStyle: GoogleFonts.poppins(
                  color: userType == 'Doctor' ? Colors.white : Colors.black,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Nurse'),
                selected: userType == 'Nurse',
                onSelected: (selected) {
                  setState(() {
                    userType = selected ? 'Nurse' : userType;
                    if (selected) _fetchDoctors();
                  });
                },
                selectedColor: Colors.blue.shade600,
                backgroundColor: Colors.grey.shade100,
                labelStyle: GoogleFonts.poppins(
                  color: userType == 'Nurse' ? Colors.white : Colors.black,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade400,
            width: 1.5,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade400,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDoctorId,
      hint: Text('Select Doctor', style: GoogleFonts.poppins()),
      items: availableDoctors.map<DropdownMenuItem<String>>((doctor) {
        return DropdownMenuItem<String>(
          value: doctor['id'],
          child: Text(
            '${doctor['name']} (${doctor['specialty']})',
            style: GoogleFonts.poppins(),
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => selectedDoctorId = val),
      validator: (val) => userType == 'Nurse' && val == null
          ? 'Please select a doctor'
          : null,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelText: 'Assigned Doctor',
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade400,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorAvailabilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Availability',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Select specific dates and time ranges when you are available:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 15),

        // Date Picker
        ElevatedButton(
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                _selectedStartTime = null;
                _selectedEndTime = null;
              });
            }
          },
          child: Text(
            _selectedDate == null
                ? 'Select Date'
                : 'Selected: ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
          ),
        ),

        if (_selectedDate != null) ...[
          const SizedBox(height: 15),

          // Start Time Picker
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedStartTime ?? TimeOfDay.now(),
              );
              if (pickedTime != null) {
                setState(() {
                  _selectedStartTime = pickedTime;
                  if (_selectedEndTime != null &&
                      (_selectedEndTime!.hour < pickedTime.hour ||
                          (_selectedEndTime!.hour == pickedTime.hour &&
                              _selectedEndTime!.minute <= pickedTime.minute))) {
                    _selectedEndTime = null;
                  }
                });
              }
            },
            child: Text(
              _selectedStartTime == null
                  ? 'Select Start Time'
                  : 'Start: ${_selectedStartTime!.format(context)}',
            ),
          ),

          const SizedBox(height: 10),

          // End Time Picker
          ElevatedButton(
            onPressed: _selectedStartTime == null
                ? null
                : () async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedEndTime ?? TimeOfDay(
                  hour: _selectedStartTime!.hour + 1,
                  minute: _selectedStartTime!.minute,
                ),
              );
              if (pickedTime != null &&
                  (pickedTime.hour > _selectedStartTime!.hour ||
                      (pickedTime.hour == _selectedStartTime!.hour &&
                          pickedTime.minute > _selectedStartTime!.minute))) {
                setState(() {
                  _selectedEndTime = pickedTime;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('End time must be after start time'),
                  ),
                );
              }
            },
            child: Text(
              _selectedEndTime == null
                  ? 'Select End Time'
                  : 'End: ${_selectedEndTime!.format(context)}',
            ),
          ),

          const SizedBox(height: 15),

          // Add Time Slot Button
          ElevatedButton(
            onPressed: _selectedStartTime == null || _selectedEndTime == null
                ? null
                : () {
              final dateKey = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
              );

              final newSlot = {
                'start': '${_selectedStartTime!.hour}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}',
                'end': '${_selectedEndTime!.hour}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}',
              };

              // Check for overlapping slots
              bool hasOverlap = false;
              if (_availability[dateKey] != null) {
                for (var slot in _availability[dateKey]!) {
                  final existingStart = slot['start']!.split(':');
                  final existingEnd = slot['end']!.split(':');
                  final existingStartHour = int.parse(existingStart[0]);
                  final existingStartMin = int.parse(existingStart[1]);
                  final existingEndHour = int.parse(existingEnd[0]);
                  final existingEndMin = int.parse(existingEnd[1]);

                  final newStartHour = _selectedStartTime!.hour;
                  final newStartMin = _selectedStartTime!.minute;
                  final newEndHour = _selectedEndTime!.hour;
                  final newEndMin = _selectedEndTime!.minute;

                  if ((newStartHour < existingEndHour ||
                      (newStartHour == existingEndHour && newStartMin < existingEndMin)) &&
                      (newEndHour > existingStartHour ||
                          (newEndHour == existingStartHour && newEndMin > existingStartMin))) {
                    hasOverlap = true;
                    break;
                  }
                }
              }

              if (hasOverlap) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This time slot overlaps with an existing one'),
                  ),
                );
              } else {
                setState(() {
                  _availability[dateKey] ??= [];
                  _availability[dateKey]!.add(newSlot);
                  _selectedStartTime = null;
                  _selectedEndTime = null;
                });
              }
            },
            child: const Text('Add Time Slot'),
          ),

          const SizedBox(height: 20),
        ],

        // Display selected availability
        if (_availability.isNotEmpty) ...[
          const Divider(),
          Text(
            'Current Availability:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ..._availability.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(entry.key),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ...entry.value.map((slot) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        Text(
                          '${slot['start']} - ${slot['end']}',
                          style: GoogleFonts.poppins(),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _availability[entry.key]!.remove(slot);
                              if (_availability[entry.key]!.isEmpty) {
                                _availability.remove(entry.key);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),

          // Remove availability button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _availability.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('Clear All Availability'),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _getLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Get Current Location',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Register',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _imageFile = pickedFile;
        profileImageBase64 = base64String;
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await _location.getLocation();
    setState(() {
      latitude = locationData.latitude ?? 0.0;
      longitude = locationData.longitude ?? 0.0;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (userType == 'Nurse' && selectedDoctorId == null) {
        _showErrorDialog('Please select a doctor');
        return;
      }

      if (userType == 'Doctor' && _availability.isEmpty) {
        _showErrorDialog('Please set at least one available time slot');
        return;
      }

      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          String userTypePath = userType == 'Doctor'
              ? 'Doctors'
              : userType == 'Nurse'
              ? 'Nurses'
              : 'Patients';

          // Initialize userData with common fields
          Map<String, dynamic> userData = {
            'uid': user.uid,
            'email': email,
            'phoneNumber': phoneNumber,
            'firstName': firstName,
            'lastName': lastName,
            'city': city,
            'profileImageBase64': profileImageBase64,
            'latitude': latitude,
            'longitude': longitude,
            'createdAt': ServerValue.timestamp,
            'aboutMe': aboutMe,
          };

          if (userType == 'Doctor') {
            // Convert availability to Firebase format
            Map<String, dynamic> availability = {};
            _availability.forEach((date, slots) {
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              availability[dateStr] = slots;
            });

            userData.addAll({
              'qualification': qualification,
              'category': category,
              'yearsOfExperience': yearsOfExperience,
              'totalReviews': 0,
              'averageRating': 0.0,
              'numberOfReviews': 0,
              'availability': availability,
            });
          } else if (userType == 'Nurse') {
            userData.addAll({
              'qualification': qualification,
              'yearsOfExperience': yearsOfExperience,
              'assignedDoctorId': selectedDoctorId,
            });
          }

          await _database.child(userTypePath).child(user.uid).set(userData);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
              switch (userType) {
                case 'Doctor':
                  return const DoctorHomePage();
                case 'Nurse':
                  return const NurseHomePage();
                default:
                  return const PatientHomePage();
              }
            },
          ));
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Registration failed';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email.';
        }
        _showErrorDialog(errorMessage);
      } catch (e) {
        _showErrorDialog('An unexpected error occurred: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}