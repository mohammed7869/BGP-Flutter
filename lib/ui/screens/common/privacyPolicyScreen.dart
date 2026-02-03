import 'package:flutter/material.dart';

/// Privacy Policy screen with content similar to standard app privacy pages.
/// Accessible from welcome screen and member drawer.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('1. Introduction'),
                  const SizedBox(height: 8),
                  const Text(
                    'Burhani Guards Pune values your privacy and is committed to protecting your personal information. This policy outlines how we collect, use, and safeguard your data when you use our app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('2. Information We Collect'),
                  const SizedBox(height: 8),
                  _buildBullet(
                    'Personal Information: Name, email, phone number, and payment details.',
                  ),
                  _buildBullet(
                    'Usage Data: Information about how you use the app, including device type and interaction with features.',
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('3. How We Use Your Information'),
                  const SizedBox(height: 8),
                  _buildBullet('To provide and improve app functionality.'),
                  _buildBullet('To process transactions and send notifications.'),
                  _buildBullet('To secure your account and prevent fraud.'),
                  const SizedBox(height: 20),

                  _buildSectionHeading('4. Sharing Your Information'),
                  const SizedBox(height: 8),
                  const Text(
                    'We do not sell your personal data. Information may be shared with third-party service providers for payment processing and security purposes, always under strict confidentiality agreements.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('5. Data Security'),
                  const SizedBox(height: 8),
                  const Text(
                    'We use industry-standard encryption and security measures to protect your data from unauthorized access and breaches.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('6. Your Rights'),
                  const SizedBox(height: 8),
                  const Text(
                    'You can access, update, or delete your personal information at any time by contacting our support team.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('7. Changes to This Policy'),
                  const SizedBox(height: 8),
                  const Text(
                    'We may update this policy periodically. Any changes will be notified through the app or email.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeading('8. Contact Us'),
                  const SizedBox(height: 8),
                  const Text(
                    'For any questions or concerns regarding your privacy, please contact us at clearconceptssolutions@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
