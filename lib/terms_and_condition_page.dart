import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff0064FA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last Updated: 30/4/2025',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              number: '1.',
              title: 'Introduction',
              content: 'Welcome to EASS Doctor Appointment App. By using our application, '
                  'you agree to the following terms and conditions. Please read them carefully.',
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '2.',
              title: 'User Registration',
              points: [
                'Users must provide accurate and complete information during registration',
                'You are responsible for maintaining the confidentiality of your account details',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '3.',
              title: 'Appointment Booking & Cancellation',
              points: [
                'Users can book, reschedule, or cancel appointments subject to the doctor\'s availability',
                'Late cancellations may be subject to charges as per clinic policies',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '4.',
              title: 'Payments & Refunds',
              points: [
                'Payments must be made through the available methods within the app',
                'Refunds, if applicable, will be processed as per the clinic\'s refund policy',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '5.',
              title: 'Privacy Policy',
              points: [
                'Your personal data is securely stored and handled in compliance with data protection laws',
                'We do not share your data with third parties without your consent',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '6.',
              title: 'User Responsibilities',
              points: [
                'Users must use the app for lawful purposes only',
                'Any misuse or fraudulent activity may result in account suspension',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '7.',
              title: 'Disclaimer & Limitation of Liability',
              points: [
                'The app provides appointment scheduling services but does not guarantee medical outcomes',
                'We are not responsible for any medical advice or treatment provided by doctors',
              ],
            ),
            const SizedBox(height: 25),

            _buildSection(
              number: '8.',
              title: 'Changes to Terms & Conditions',
              content: 'We reserve the right to update these terms at any time. '
                  'Continued use of the app after updates signifies your acceptance of the revised terms.',
            ),
            const SizedBox(height: 30),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF0EFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffC8C4FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For further inquiries, please contact our support team:',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20, color: Color(0xff0064FA)),
                      const SizedBox(width: 10),
                      Text(
                        'EASS@gmail.com',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    String? content,
    List<String>? points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0064FA),
            ),
            children: [
              TextSpan(text: '$number '),
              TextSpan(text: title),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (content != null)
          Text(
            content,
            style: GoogleFonts.poppins(),
          ),

        if (points != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(Icons.circle, size: 6, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }
}