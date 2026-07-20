import 'package:flutter/material.dart';
import 'gamepad_navigator.dart';
import 'l10n/app_localizations.dart';
import 'onboarding_state.dart';
import 'session.dart';
import 'widgets/power_button.dart';
import 'screens/organisation_screen.dart';
import 'screens/slide1.dart';
import 'screens/slide2.dart';
import 'screens/slide3.dart';
import 'screens/slide4.dart';
import 'screens/slide5.dart';
import 'screens/slide6.dart';
import 'screens/slide7.dart';
import 'screens/slide8.dart';
import 'screens/slide9.dart';
import 'screens/slide10.dart';
import 'screens/slide11.dart';
import 'screens/slide12.dart';
import 'screens/slide13.dart';
import 'screens/slide14.dart';
import 'screens/slide15.dart';
import 'screens/slide16.dart';

/// Root navigator handle: GamepadNavigator pops routes through it.
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GamepadNavigator.start(navigatorKey);
  runApp(const MyApp());
}

/// Fade + gentle horizontal slide for every route push/pop. The incoming
/// page drifts in from the right while the outgoing one recedes slightly,
/// so forward and back both read as one fluid motion on the kiosk.
class _FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      // Recede left as the next page covers this one.
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.06, 0),
      ).animate(secondaryCurved),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Bundled Noto Sans with per-script fallbacks so every supported
  /// language renders from known font files instead of whatever fontconfig
  /// resolves on the device.
  static const _fontFallback = <String>[
    'NotoSansDevanagari',
    'NotoSansTamil',
    'NotoSansTelugu',
    'NotoSansMalayalam',
    'NotoSansKannada',
  ];

  static ThemeData _theme() {
    final base = ThemeData(useMaterial3: true, fontFamily: 'NotoSans');
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: _fontFallback),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamilyFallback: _fontFallback,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.linux: _FadeSlideTransitionsBuilder(),
          TargetPlatform.android: _FadeSlideTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: Session.locale,
      builder: (context, locale, _) => MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _theme(),
        home: OnboardingState.isDone
            ? const OrganisationScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 16;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (page) => setState(() => _page = page),
            children: const [
              Slide1Screen(),
              Slide2Screen(),
              Slide3Screen(),
              Slide4Screen(),
              Slide5Screen(),
              Slide6Screen(),
              Slide7Screen(),
              Slide8Screen(),
              Slide9Screen(),
              Slide10Screen(),
              Slide11Screen(),
              Slide12Screen(),
              Slide13Screen(),
              Slide14Screen(),
              Slide15Screen(),
              Slide16Screen(),
            ],
          ),

          // Power button
          Positioned(top: 16, right: 16, child: const PowerButton()),

          // Back arrow
          if (_page > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 36),
                  onPressed: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),

          // Next arrow
          if (_page < _pageCount - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 36),
                  onPressed: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),

          // Page dots
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
