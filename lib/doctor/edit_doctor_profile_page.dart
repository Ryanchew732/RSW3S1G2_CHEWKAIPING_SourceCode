  import 'dart:convert';
  import 'dart:io';

  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:location/location.dart';
  import 'package:intl/intl.dart';
  import 'package:testing/doctor/model/doctor.dart';

  class EditProfilePage extends StatefulWidget {
    final Doctor doctor;
    const EditProfilePage({super.key, required this.doctor});

    @override
    State<EditProfilePage> createState() => _EditProfilePageState();
  }

  class _EditProfilePageState extends State<EditProfilePage> {
    final DatabaseReference _database = FirebaseDatabase.instance.ref('Doctors');
    final _formKey = GlobalKey<FormState>();
    final ImagePicker _picker = ImagePicker();
    final Location _location = Location();
    XFile? _imageFile;
    bool _isLoading = false;
    bool _isGettingLocation = false;

    late String _firstName;
    late String _lastName;
    late String _phoneNumber;
    late String _city;
    late String _qualification;
    late String _category;
    late String _yearsOfExperience;
    late String _aboutMe;
    late String _profileImageBase64;
    double _latitude = 0.0;
    double _longitude = 0.0;

    // Availability variables
    Map<DateTime, List<Map<String, String>>> _availability = {};
    DateTime? _selectedDate;
    TimeOfDay? _selectedStartTime;
    TimeOfDay? _selectedEndTime;

    @override
    void initState() {
      super.initState();
      _firstName = widget.doctor.firstName;
      _lastName = widget.doctor.lastName;
      _phoneNumber = widget.doctor.phoneNumber;
      _city = widget.doctor.city;
      _qualification = widget.doctor.qualification;
      _category = widget.doctor.category;
      _yearsOfExperience = widget.doctor.yearsOfExperience;
      _aboutMe = widget.doctor.aboutMe ?? '';
      _profileImageBase64 = widget.doctor.profileImageBase64 ?? '';
      _latitude = widget.doctor.latitude;
      _longitude = widget.doctor.longitude;

      // Initialize availability from doctor data
      if (widget.doctor.availability != null) {
        widget.doctor.availability!.forEach((dateStr, slots) {
          try {
            final date = DateTime.parse(dateStr);
            // Convert each slot to the correct format
            final convertedSlots = (slots as List<dynamic>).map((slot) {
              final slotMap = Map<String, dynamic>.from(slot as Map);
              return {
                'start': slotMap['start']?.toString() ?? '',
                'end': slotMap['end']?.toString() ?? '',
              };
            }).toList();

            _availability[date] = List<Map<String, String>>.from(convertedSlots);
          } catch (e) {
            print('Error parsing availability slot: $e');
          }
        });
      }
    }

    Future<void> _pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _imageFile = pickedFile;
          _profileImageBase64 = base64String;
        });
      }
    }

    Future<void> _getCurrentLocation() async {
      setState(() => _isGettingLocation = true);
      try {
        bool serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) {
            throw Exception('Location services are disabled');
          }
        }

        PermissionStatus permissionGranted = await _location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await _location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            throw Exception('Location permissions are denied');
          }
        }

        final locationData = await _location.getLocation();
        setState(() {
          _latitude = locationData.latitude ?? _latitude;
          _longitude = locationData.longitude ?? _longitude;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isGettingLocation = false);
      }
    }

    Future<void> _updateProfile() async {
      if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Convert availability to Firebase format
            Map<String, dynamic> availability = {};
            _availability.forEach((date, slots) {
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              availability[dateStr] = slots.map((slot) => {
                'start': slot['start'],
                'end': slot['end'],
              }).toList();
            });

            await _database.child(user.uid).update({
              'firstName': _firstName,
              'lastName': _lastName,
              'phoneNumber': _phoneNumber,
              'city': _city,
              'qualification': _qualification,
              'category': _category,
              'yearsOfExperience': _yearsOfExperience,
              'aboutMe': _aboutMe,
              'profileImageBase64': _profileImageBase64,
              'latitude': _latitude,
              'longitude': _longitude,
              'availability': availability,
            });
            Navigator.of(context).pop();
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }

    Widget _buildAvailabilityEditor() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

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
                    // Reset end time if it's now before start time
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
                if (pickedTime != null) {
                  // Validate end time is after start time
                  if (pickedTime.hour > _selectedStartTime!.hour ||
                      (pickedTime.hour == _selectedStartTime!.hour &&
                          pickedTime.minute > _selectedStartTime!.minute)) {
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
                // Create date without time components for the key
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

                    // Check if new slot overlaps with existing slot
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
          ],

          // Display selected availability
          if (_availability.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            Text(
              'Current Availability:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ..._availability.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(entry.key),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ...entry.value.map((slot) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Row(
                        children: [
                          Text('${slot['start']} - ${slot['end']}'),
                          IconButton(
                            icon: Icon(Icons.delete, size: 18, color: Colors.red),
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

            // Remove all availability button
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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _updateProfile,
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 4,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 4,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: _imageFile != null
                              ? Image.file(
                            File(_imageFile!.path),
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          )
                              : _profileImageBase64.isNotEmpty
                              ? Image.memory(
                            base64Decode(_profileImageBase64),
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          )
                              : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                _buildTextField(
                  label: 'First Name',
                  initialValue: _firstName,
                  icon: Icons.person_outline,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter first name' : null,
                  onChanged: (value) => _firstName = value,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Last Name',
                  initialValue: _lastName,
                  icon: Icons.person_outline,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter last name' : null,
                  onChanged: (value) => _lastName = value,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Phone Number',
                  initialValue: _phoneNumber,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter phone number' : null,
                  onChanged: (value) => _phoneNumber = value,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Qualification',
                  initialValue: _qualification,
                  icon: Icons.school_outlined,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter qualification' : null,
                  onChanged: (value) => _qualification = value,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Years of Experience',
                  initialValue: _yearsOfExperience,
                  icon: Icons.work_outline,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty
                      ? 'Please enter years of experience'
                      : null,
                  onChanged: (value) => _yearsOfExperience = value,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'About Me (max 30 words)',
                  initialValue: _aboutMe,
                  icon: Icons.info_outline,
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.split(' ').length > 30) {
                      return 'Please limit to 30 words';
                    }
                    return null;
                  },
                  onChanged: (value) => _aboutMe = value,
                ),
                const SizedBox(height: 20),
                _buildCityDropdown(),
                const SizedBox(height: 20),
                _buildCategoryDropdown(),
                const SizedBox(height: 20),
                _buildAvailabilityEditor(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isGettingLocation
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    )
                        : const Text(
                      'Update Current Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_latitude != 0.0 && _longitude != 0.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Current Location: (${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'UPDATE PROFILE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildTextField({
      required String label,
      required String initialValue,
      required IconData icon,
      TextInputType? keyboardType,
      int maxLines = 1,
      required String? Function(String?) validator,
      required Function(String) onChanged,
    }) {
      return TextFormField(
        initialValue: initialValue,
        style: const TextStyle(fontSize: 18),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 24),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
      );
    }

    Widget _buildCityDropdown() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: DropdownButtonFormField<String>(
          value: _city,
          items: [
            'Kuala Lumpur',
            'Shah Alam',
            'Petaling Jaya',
            'Subang Jaya',
            'Klang',
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _city = value!;
            });
          },
          decoration: InputDecoration(
            labelText: 'City',
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: Colors.blue.shade600,
              size: 24,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.blue.shade600,
            size: 28,
          ),
          dropdownColor: Colors.white,
        ),
      );
    }

    Widget _buildCategoryDropdown() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: DropdownButtonFormField<String>(
          value: _category,
          items: [
            'General',
            'Dentist',
            'Cardiology',
            'Oncology',
            'Surgeon',
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _category = value!;
            });
          },
          decoration: InputDecoration(
            labelText: 'Specialty',
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.medical_services_outlined,
              color: Colors.blue.shade600,
              size: 24,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.blue.shade600,
            size: 28,
          ),
          dropdownColor: Colors.white,
        ),
      );
    }
  }