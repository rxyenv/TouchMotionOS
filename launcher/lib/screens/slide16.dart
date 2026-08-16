import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../onboarding_state.dart';
import '../widgets/focusable_tap.dart';
import 'organisation_screen.dart';

class Slide16Screen extends StatelessWidget {
  const Slide16Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const figmaW = 1920.0;
    const figmaH = 1080.0;
    double sx(double val) => val * (screenW / figmaW);
    double sy(double val) => val * (screenH / figmaH);

    return Container(
      color: Colors.white,
      width: screenW,
      height: screenH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          //Headline
          Positioned(
            top: sy(342),
            left: sx(450),
            child: SvgPicture.asset(
              'assets/slide16/Great16.svg',
              width: sx(1096),
              height: sy(333),
              fit: BoxFit.contain,
            ),
          ),

          //Continue Button
          Positioned(
            top: sy(707),
            left: sx(843),
            child: FocusableTap(
              autofocus: true,
              borderRadius: BorderRadius.circular(sy(12)),
              onTap: () {
                OnboardingState.markDone();
                // Same entry point the app boots into once onboarding is
                // done: organisation login, profile, then home.
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrganisationScreen()),
                );
              },
              child: SvgPicture.asset(
                'assets/slide16/Continue16.svg',
                width: sx(230.45),
                height: sy(55.92),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
