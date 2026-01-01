import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class BaawanErpDialog extends StatelessWidget {
  final VoidCallback? onWebsiteVisited;

  const BaawanErpDialog({Key? key, this.onWebsiteVisited}) : super(key: key);

  Future<void> _launchWebsite(BuildContext context) async {
    try {
      final Uri url = Uri.parse('https://www.baawanerp.com/');
      
      // Check if URL can be launched
      if (!await canLaunchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open the website. Please check your internet connection.'),
            ),
          );
        }
        return;
      }
      
      // Launch URL in external browser
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      // Call the callback to indicate website was visited (before closing dialog)
      if (onWebsiteVisited != null && launched) {
        onWebsiteVisited!();
      }
      
      // Close dialog after launching URL
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // If URL launching fails, show error and close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening website: ${e.toString()}'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business_center,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baawan ERP',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Complete Business Solution',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Benefits Section
              // Text(
              //   'Transform Your Business with ERP Software',
              //   style: GoogleFonts.poppins(
              //     fontSize: 18,
              //     fontWeight: FontWeight.w600,
              //     color: Colors.black87,
              //   ),
              // ),
              const SizedBox(height: 16),

              // Benefits List
              _buildBenefitItem(
                Icons.speed,
                'Streamlined Operations',
                '',
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.insights,
                'Real-time Analytics',
                '',
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.account_tree,
                'Centralized Management',
                '',
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.security,
                'Enhanced Security',
                '',
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.trending_up,
                'Scalable Growth',
                '',
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.calculate,
                'Cost Reduction',
                '',
              ),
              const SizedBox(height: 24),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _launchWebsite(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Visit Website',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
