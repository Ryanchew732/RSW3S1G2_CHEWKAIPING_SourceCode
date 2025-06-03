import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing/calculation_calories_page.dart';
import 'package:testing/doctor/doctor_list_page.dart';
import 'package:testing/help_and_support_page.dart';
import 'package:testing/patient/favorite_page.dart';
import 'package:testing/patient/my_appointment_page.dart';
import 'package:testing/patient/my_history_page.dart';
import 'package:testing/patient/chat_list_page.dart';
import 'package:testing/profile_page.dart';
import 'package:testing/notification_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testing/doctor/model/doctor.dart';
import 'package:testing/doctor/doctor_details_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _children = [
    _HomeContent(),
    ChatListPage(),
    ProfilePage(),
    HistoryPage(),
    DoctorListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _children.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedItemColor: const Color(0xFF424242),
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu),
              label: 'Appointment',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _HomeContent extends StatefulWidget {
  @override
  __HomeContentState createState() => __HomeContentState();
}

class __HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isSearching = false;
  bool _isLoadingDoctors = false;
  Map<String, Map<String, int>> _cityCategoryCounts = {};
  String? _selectedCity;
  String? _selectedCategory;
  final ScrollController _cityScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cityScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
    });

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Doctors').once();
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> doctorsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<Doctor> tempDoctors = [];
        Map<String, Map<String, int>> tempCityCategoryCounts = {};

        doctorsMap.forEach((key, value) {
          Doctor doctor = Doctor.fromMap(Map<String, dynamic>.from(value), key);
          tempDoctors.add(doctor);

          // Count doctors by city and category
          String city = doctor.city;
          String category = doctor.category;

          if (!tempCityCategoryCounts.containsKey(city)) {
            tempCityCategoryCounts[city] = {};
          }

          tempCityCategoryCounts[city]![category] =
              (tempCityCategoryCounts[city]![category] ?? 0) + 1;
        });

        setState(() {
          _allDoctors = tempDoctors;
          _filteredDoctors = tempDoctors;
          _cityCategoryCounts = tempCityCategoryCounts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoadingDoctors = false;
      });
    }
  }

  void _onSearchChanged() {
    String searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty && _selectedCity == null && _selectedCategory == null) {
      setState(() {
        _filteredDoctors = _allDoctors;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredDoctors = _allDoctors.where((doctor) {
        bool matchesCity = _selectedCity == null ||
            doctor.city.toLowerCase() == _selectedCity!.toLowerCase();

        bool matchesCategory = _selectedCategory == null ||
            doctor.category.toLowerCase() == _selectedCategory!.toLowerCase();

        bool matchesSearch = searchText.isEmpty ||
            doctor.firstName.toLowerCase().contains(searchText) ||
            doctor.lastName.toLowerCase().contains(searchText) ||
            doctor.category.toLowerCase().contains(searchText);

        return matchesCity && matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _searchController.clear();
      _isSearching = false;
      _filteredDoctors = _allDoctors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title with Logo
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/EASS.png',
                        width: 30,
                        height: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'EASS Doctor App',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar with Notification Icon
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search doctors...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        suffixIcon: _isSearching || _selectedCity != null || _selectedCategory != null
                            ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: _clearFilters,
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.notifications_outlined, size: 28, color: Colors.blue.shade700),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter chips for city and category
            if (_cityCategoryCounts.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: Scrollbar(
                      controller: _cityScrollController,
                      child: ListView(
                        controller: _cityScrollController,
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text('All Cities'),
                              selected: _selectedCity == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCity = null;
                                  _selectedCategory = null;
                                  _onSearchChanged();
                                });
                              },
                              selectedColor: Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color: _selectedCity == null ? Colors.blue.shade700 : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          ..._cityCategoryCounts.keys.map((city) {
                            int totalDoctors = _cityCategoryCounts[city]!.values.fold(0, (sum, count) => sum + count);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text('$city ($totalDoctors)'),
                                selected: _selectedCity == city,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCity = selected ? city : null;
                                    _selectedCategory = null;
                                    _onSearchChanged();
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                                labelStyle: TextStyle(
                                  color: _selectedCity == city ? Colors.blue.shade700 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedCity != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specialties in $_selectedCity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: Scrollbar(
                        controller: _categoryScrollController,
                        child: ListView(
                          controller: _categoryScrollController,
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text('All Specialties'),
                                selected: _selectedCategory == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = null;
                                    _onSearchChanged();
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null ? Colors.blue.shade700 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            ..._cityCategoryCounts[_selectedCity]!.keys.map((category) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('$category (${_cityCategoryCounts[_selectedCity]![category]})'),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : null;
                                      _onSearchChanged();
                                    });
                                  },
                                  selectedColor: Colors.blue.shade100,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == category ? Colors.blue.shade700 : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Show search results or normal content
            if (_isSearching || _selectedCity != null || _selectedCategory != null)
              _buildSearchResults()
            else
              Column(
                children: [
                  // Advertisement Banner
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage('assets/images/ad_image.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories Section
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _CategoryBubble(
                        icon: Icons.calendar_today,
                        label: 'Book Appointment',
                        color: Colors.blue.shade50,
                        iconColor: Colors.blue.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DoctorListPage()),
                        ),
                      ),
                      _CategoryBubble(
                        icon: Icons.favorite,
                        label: 'Favorites',
                        color: Colors.pink.shade50,
                        iconColor: Colors.pink.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FavoritePage()),
                        ),
                      ),
                      _CategoryBubble(
                        icon: Icons.calculate,
                        label: 'Calories Calc',
                        color: Colors.green.shade50,
                        iconColor: Colors.green.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CalculationCaloriesPage()),
                        ),
                      ),
                      _CategoryBubble(
                        icon: Icons.help,
                        label: 'Help Center',
                        color: Colors.orange.shade50,
                        iconColor: Colors.orange.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HelpAndSupportPage()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingDoctors) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: Colors.blue.shade700,
          ),
        ),
      );
    }

    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No doctors found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.blue.shade700),
                ),
                child: Text(
                  'Clear all filters',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_filteredDoctors.length} ${_filteredDoctors.length == 1 ? 'Doctor' : 'Doctors'} Found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _filteredDoctors.length,
          itemBuilder: (context, index) {
            final doctor = _filteredDoctors[index];
            return _buildDoctorCard(doctor);
          },
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailPage(doctor: doctor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: doctor.profileImageBase64 != null && doctor.profileImageBase64!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(doctor.profileImageBase64!),
                    fit: BoxFit.cover,
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade200,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.firstName} ${doctor.lastName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.city,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryBubble({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}