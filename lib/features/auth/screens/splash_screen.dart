import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../widgets/carbon_badge.dart';
import '../widgets/green_logo.dart';
import '../../auth/screens/registration_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: _SplashContainer(
                isLandscape: isLandscape,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashContainer extends StatelessWidget {
  final bool isLandscape;

  const _SplashContainer({
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final containerWidth = isLandscape
        ? screenWidth * 0.92
        : screenWidth > 430
            ? 402.0
            : screenWidth * 0.90;

    return Container(
      width: containerWidth,
      constraints: const BoxConstraints(
        maxWidth: 900,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: isLandscape
          ? const _LandscapeSplashContent()
          : const _PortraitSplashContent(),
    );
  }
}

class _PortraitSplashContent extends StatelessWidget {
  const _PortraitSplashContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.vertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Carbon Zero badge
            const CarbonBadge(),

            const SizedBox(height: 30),

            // GreenOffice logo
            const GreenLogo(),

            const SizedBox(height: 20),

            // Application name
            const Text(
              'GreenOffice 360',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),

            const SizedBox(height: 10),

            // Tagline
            const Text(
              'Small actions. Greener workplace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 30),

            // Get Started
            AppButton(
              text: 'Get Started',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegistrationScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // How it works
            TextButton(
              onPressed: () {
                // Navigate to How It Works
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textDark,
                padding: EdgeInsets.zero,
                minimumSize: const Size(140, 32),
              ),
              child: const Text(
                'How it works',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _LandscapeSplashContent extends StatelessWidget {
  const _LandscapeSplashContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 350,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // =========================
            // LEFT SIDE - LOGO
            // =========================
            Expanded(
              flex: 4,
              child: Center(
                child: const GreenLogo(
                  size: 190,
                ),
              ),
            ),

            const SizedBox(width: 35),

            // =========================
            // RIGHT SIDE - CONTENT
            // =========================
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carbon Zero badge
                  const CarbonBadge(),

                  const SizedBox(height: 20),

                  // Application name
                  const Text(
                    'GreenOffice 360',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  const Text(
                    'Small actions. Greener workplace.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Get Started
                  AppButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegistrationScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // How it works
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to How It Works
                      },
                      child: const Text(
                        'How it works',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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