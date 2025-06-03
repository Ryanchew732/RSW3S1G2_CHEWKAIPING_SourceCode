import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalculationCaloriesPage extends StatefulWidget {
  const CalculationCaloriesPage({super.key});

  @override
  State<CalculationCaloriesPage> createState() => _CalculationCaloriesPageState();
}

class _CalculationCaloriesPageState extends State<CalculationCaloriesPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  double? _calculatedCalories;

  final Map<String, double> _activityLevelMultipliers = {
    'sedentary': 1.2,
    'lightly active': 1.375,
    'moderately active': 1.55,
    'very active': 1.725,
    'extra active': 1.9,
  };

  void _calculateCalories() {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double weight = double.parse(_weightController.text);
    double height = double.parse(_heightController.text);
    int age = int.parse(_ageController.text);

    // Mifflin-St Jeor Equation
    double bmr = _gender == 'male'
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    double calories = bmr * _activityLevelMultipliers[_activityLevel]!;

    setState(() {
      _calculatedCalories = calories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calorie Calculator',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xff0064FA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF0EFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Calculate your daily calorie needs based on your personal information and activity level',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gender Selection
            Text(
              'Gender',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    icon: Icons.male,
                    label: 'Male',
                    isSelected: _gender == 'male',
                    onTap: () => setState(() => _gender = 'male'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderOption(
                    icon: Icons.female,
                    label: 'Female',
                    isSelected: _gender == 'female',
                    onTap: () => setState(() => _gender = 'female'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Fields
            _InputField(
              controller: _weightController,
              label: 'Weight (kg)',
              hintText: 'Enter your weight',
              icon: Icons.monitor_weight,
            ),
            const SizedBox(height: 16),

            _InputField(
              controller: _heightController,
              label: 'Height (cm)',
              hintText: 'Enter your height',
              icon: Icons.height,
            ),
            const SizedBox(height: 16),

            _InputField(
              controller: _ageController,
              label: 'Age',
              hintText: 'Enter your age',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),

            // Activity Level
            Text(
              'Activity Level',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xffF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _activityLevel,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('Sedentary (little or no exercise)'),
                  ),
                  DropdownMenuItem(
                    value: 'lightly active',
                    child: Text('Lightly active (light exercise 1-3 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'moderately active',
                    child: Text('Moderately active (moderate exercise 3-5 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'very active',
                    child: Text('Very active (hard exercise 6-7 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'extra active',
                    child: Text('Extra active (very hard exercise & physical job)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            _ActivityLevelIndicator(activityLevel: _activityLevel),
            const SizedBox(height: 24),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0064FA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _calculateCalories,
                child: Text(
                  'Calculate Calories',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_calculatedCalories != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Calorie Needs',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_calculatedCalories!.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0064FA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This estimate is based on the Mifflin-St Jeor equation and your activity level. For personalized dietary advice, please consult a nutritionist.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
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
}

class _GenderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff0064FA) : const Color(0xffF0EFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xff0064FA) : const Color(0xffC8C4FF),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28,
                color: isSelected ? Colors.white : const Color(0xff0064FA)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF0EFFF),
            hintText: hintText,
            prefixIcon: Icon(icon, color: const Color(0xff0064FA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ActivityLevelIndicator extends StatelessWidget {
  final String activityLevel;

  const _ActivityLevelIndicator({required this.activityLevel});

  int get _starCount {
    switch (activityLevel) {
      case 'sedentary': return 1;
      case 'lightly active': return 2;
      case 'moderately active': return 3;
      case 'very active': return 4;
      case 'extra active': return 5;
      default: return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Icon(
              index < _starCount ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Activity Intensity',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}