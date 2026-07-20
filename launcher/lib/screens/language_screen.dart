import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../languages.dart';
import '../session.dart';
import '../widgets/focusable_tap.dart';
import '../widgets/power_button.dart';
import 'patient_profile_screen.dart';

/// Language selection. Picking a card sets [Session.locale], which switches
/// the whole app's language immediately; Continue moves on to the profile.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);

  String get _selected => Session.locale.value.languageCode;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    double sx(double val) => val * (screenW / 1920.0);
    double sy(double val) => val * (screenH / 1080.0);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: 16, right: 16, child: const PowerButton()),
          if (Navigator.of(context).canPop())
            Positioned(
              top: sy(56),
              left: sx(72),
              child: IconButton(
                icon: Icon(Icons.chevron_left, size: sy(44), color: _ink),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: sx(1100)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.chooseLanguage,
                    style: TextStyle(
                      color: _ink,
                      fontSize: sy(56),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: sy(12)),
                  Text(
                    l10n.voiceGuideHint,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.55),
                      fontSize: sy(24),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: sy(56)),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: sx(32),
                    runSpacing: sy(32),
                    children: [
                      for (final lang in appLanguages)
                        FocusableTap(
                          autofocus: lang.code == _selected,
                          borderRadius: BorderRadius.circular(sy(24)),
                          onTap: () => setState(
                            () => Session.locale.value = Locale(lang.code),
                          ),
                          child: Container(
                            width: sx(240),
                            height: sy(220),
                            decoration: BoxDecoration(
                              color: _selected == lang.code
                                  ? _lavenderDeep
                                  : _lavender,
                              borderRadius: BorderRadius.circular(sy(24)),
                              border: Border.all(
                                color: _selected == lang.code
                                    ? _ink
                                    : _ink.withValues(alpha: 0.12),
                                width: _selected == lang.code ? 2.2 : 1.3,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  lang.native,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: sy(40),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: sy(8)),
                                Text(
                                  lang.name,
                                  style: TextStyle(
                                    color: _ink.withValues(alpha: 0.55),
                                    fontSize: sy(22),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: sy(72)),
                  FocusableTap(
                    borderRadius: BorderRadius.circular(sy(40)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientProfileScreen(),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sx(72),
                        vertical: sy(24),
                      ),
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(sy(40)),
                      ),
                      child: Text(
                        l10n.continueLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sy(28),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
