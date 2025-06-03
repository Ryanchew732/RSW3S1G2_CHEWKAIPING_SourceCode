import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testing/doctor/model/patient.dart';

class EditProfilePage extends StatefulWidget {
  final Patient patient;
  const EditProfilePage({super.key, required this.patient});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;

  late String _firstName;
  late String _lastName;
  late String _phoneNumber;
  late String _city;
  late String _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _firstName = widget.patient.firstName;
    _lastName = widget.patient.lastName;
    _phoneNumber = widget.patient.phoneNumber;
    _city = widget.patient.city;
    _profileImageBase64 = widget.patient.profileImageBase64 ?? '';
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _database.child('Patients').child(user.uid).update({
            'firstName': _firstName,
            'lastName': _lastName,
            'phoneNumber': _phoneNumber,
            'city': _city,
            'profileImageBase64': _profileImageBase64,
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

              // Form Fields with always-visible borders
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
              _buildCityDropdown(),
              const SizedBox(height: 36),
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
          borderSide: BorderSide(color: Colors.grey.shade400), // Always visible border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade400), // Same as default border
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
        border: Border.all(color: Colors.grey.shade400), // Always visible border
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
          border: InputBorder.none, // Remove default border since we have container border
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