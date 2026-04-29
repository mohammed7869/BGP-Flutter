import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/survey_service.dart';
import 'package:burhaniguardsapp/ui/screens/survey/survey_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jamaats that should NOT see the survey form
const _excludedJamaats = ['BARAMATI', 'AHMEDNAGAR'];

class SurveyPopup {
  /// Check if the current user's jamaat is eligible for the survey
  static Future<bool> isJamaatEligible() async {
    final userData = await LocalStorageService().getUserData();
    if (userData == null) return false;
    final jamaat = (userData.jamaat ?? '').toUpperCase().trim();
    return !_excludedJamaats.contains(jamaat);
  }

  /// Shows survey popup if user hasn't submitted yet.
  /// Returns true if popup was shown, false otherwise.
  static Future<bool> showIfNeeded(BuildContext context) async {
    try {
      // Check jamaat eligibility first
      final eligible = await isJamaatEligible();
      if (!eligible) {
        debugPrint('[Survey] User jamaat excluded, skipping popup.');
        return false;
      }

      final surveyService = SurveyService();
      debugPrint('[Survey] Calling hasSubmitted API...');
      final hasSubmitted = await surveyService.hasSubmitted();
      debugPrint('[Survey] hasSubmitted result: $hasSubmitted');

      if (hasSubmitted) {
        debugPrint('[Survey] User already submitted, skipping popup.');
        return false;
      }

      if (!context.mounted) {
        debugPrint('[Survey] Context not mounted, skipping popup.');
        return false;
      }

      debugPrint('[Survey] Showing popup dialog...');
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (dialogContext) => _SurveyPopupDialog(),
      );

      return true;
    } catch (e) {
      debugPrint('[Survey] Error: $e');
      // Even on error, show the popup (can't confirm if submitted)
      if (context.mounted) {
        debugPrint('[Survey] Showing popup despite error...');
        await showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (dialogContext) => _SurveyPopupDialog(),
        );
        return true;
      }
      return false;
    }
  }
}

class _SurveyPopupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ashara Mubaraka Poona 1448',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Khidmat Allocation Status',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                children: [
                  Text(
                    'Please fill in your Khidmat allocation details for Ashara Mubaraka 1448.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fill Form Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SurveyFormScreen(isPreview: false),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fill Form',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Skip For Now Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Skip For Now',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
