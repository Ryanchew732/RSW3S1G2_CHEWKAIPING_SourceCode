import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
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
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF0EFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Welcome to the Help & Support section of our EASS Doctor Appointment App. '
                    'If you have any questions or issues while using our application, please refer to the following information:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Sections
            _buildSection(
              icon: Icons.calendar_today,
              title: 'Booking Appointments',
              points: [
                'Sign in to your account',
                'Select a doctor based on specialty or availability',
                'Choose your preferred date and time',
                'Confirm your appointment',
              ],
            ),

            _buildSection(
              icon: Icons.cancel,
              title: 'Cancellations',
              points: [
                'Go to your appointment history',
                'Select the appointment to modify',
                'Choose "Cancel" or "Reschedule"',
                'Follow the instructions',
              ],
            ),

            _buildSection(
              icon: Icons.payment,
              title: 'Payments',
              points: [
                'Multiple payment methods accepted',
                'Contact support for billing issues',
                'Refunds processed per clinic policy',
              ],
            ),

            _buildSection(
              icon: Icons.phone_android,
              title: 'Technical Support',
              points: [
                'Restart app if crashes occur',
                'Update to latest version',
                'Contact tech support if issues persist',
              ],
            ),
            const SizedBox(height: 24),

            // Contact Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffC8C4FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_center, color: Color(0xff0064FA), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Need More Help?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0064FA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildContactTile(
                      icon: Icons.email,
                      title: 'Email Support',
                      subtitle: 'EASS@gmail.com',
                    ),
                    _buildContactTile(
                      icon: Icons.phone,
                      title: 'Phone Support',
                      subtitle: '+6016-770 288',
                    ),
                    _buildContactTile(
                      icon: Icons.chat,
                      title: 'Live Chat',
                      subtitle: '9 AM - 6 PM (MYT)',
                      isAvailable: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff0064FA)), // Fixed the missing parenthesis here
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Icon(Icons.circle, size: 8, color: Color(0xff0064FA)),
              ),
              Expanded(
                child: Text(
                  point,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 20),
      ],
    );
  }


  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isAvailable = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xffF0EFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xff0064FA), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: isAvailable
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Available',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.green,
          ),
        ),
      )
          : null,
    );
  }
}