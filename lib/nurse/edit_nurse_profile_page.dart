import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:testing/doctor/model/Nurse.dart';

class EditNurseProfilePage extends StatefulWidget {
  final Nurse nurse;
  const EditNurseProfilePage({super.key, required this.nurse});

  @override
  State<EditNurseProfilePage> createState() => _EditNurseProfilePageState();
}

class _EditNurseProfilePageState extends State<EditNurseProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('Nurses');
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
  late String _yearsOfExperience;
  late String _profileImageBase64;
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _firstName = widget.nurse.firstName;
    _lastName = widget.nurse.lastName;
    _phoneNumber = widget.nurse.phoneNumber;
    _city = widget.nurse.city;
    _qualification = widget.nurse.qualification;
    _yearsOfExperience = widget.nurse.yearsOfExperience;
    _profileImageBase64 = widget.nurse.profileImageBase64 ?? '';
    _latitude = widget.nurse.latitude;
    _longitude = widget.nurse.longitude;
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
          await _database.child(user.uid).update({
            'firstName': _firstName,
            'lastName': _lastName,
            'phoneNumber': _phoneNumber,
            'city': _city,
            'qualification': _qualification,
            'yearsOfExperience': _yearsOfExperience,
            'profileImageBase64': _profileImageBase64,
            'latitude': _latitude,
            'longitude': _longitude,
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
              // Profile Picture Section
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

              // Form Fields
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
              _buildCityDropdown(),
              const SizedBox(height: 20),

              // Location Section
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
    required String? Function(String?) validator,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(fontSize: 18),
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
}