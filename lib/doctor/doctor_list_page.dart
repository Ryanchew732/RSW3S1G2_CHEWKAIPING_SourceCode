import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/doctor/doctor_details_page.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/doctor/widget/doctor_card.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  final DatabaseReference _database =
  FirebaseDatabase.instance.ref().child('Doctors');
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'General',
    'Dentist',
    'Cardiology',
    'Oncology',
    'Surgeon',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final DatabaseEvent event = await _database.once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) {
        setState(() {
          _doctors = [];
          _filteredDoctors = [];
          _isLoading = false;
        });
        return;
      }

      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      final List<Doctor> tmpDoctors = [];

      values.forEach((key, value) {
        try {
          final doctor = Doctor.fromMap(value, key);
          tmpDoctors.add(doctor);
        } catch (e) {
          debugPrint('Error parsing doctor data: $e');
        }
      });

      setState(() {
        _doctors = tmpDoctors;
        _filteredDoctors = tmpDoctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _filterDoctors() {
    final String searchTerm = _searchController.text.toLowerCase();

    List<Doctor> filtered = _doctors;

    // Apply search filter
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((doctor) {
        return doctor.firstName.toLowerCase().contains(searchTerm) ||
            doctor.lastName.toLowerCase().contains(searchTerm) ||
            doctor.category.toLowerCase().contains(searchTerm) ||
            doctor.qualification.toLowerCase().contains(searchTerm) ||
            doctor.city.toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((doctor) => doctor.category == _selectedCategory).toList();
    }

    setState(() {
      _filteredDoctors = filtered;
    });
  }

  void _filterDoctorsByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Find Your Doctor',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
          strokeWidth: 4,
        ),
      )
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load doctors',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDoctors,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by name, specialty, or location',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category filter chips
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      _filterDoctorsByCategory(selected ? category : 'All');
                    },
                    selectedColor: const Color(0xFF1A73E8),
                    backgroundColor: Colors.grey[200],
                    labelStyle: GoogleFonts.poppins(
                      color: _selectedCategory == category
                          ? Colors.white
                          : Colors.black,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Title with doctor count
            Row(
              children: [
                Text(
                  'Available Doctors',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredDoctors.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A73E8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Doctor List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDoctors,
                color: const Color(0xFF1A73E8),
                child: _filteredDoctors.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medication_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty &&
                            _selectedCategory == 'All'
                            ? 'No doctors available'
                            : 'No matching doctors found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_searchController.text.isNotEmpty ||
                          _selectedCategory != 'All')
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterDoctorsByCategory('All');
                          },
                          child: Text(
                            'Clear filters',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1A73E8),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: _filteredDoctors.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorDetailPage(
                                doctor: _filteredDoctors[index]),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'doctor-${_filteredDoctors[index].uid}',
                        child: DoctorCard(
                            doctor: _filteredDoctors[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}