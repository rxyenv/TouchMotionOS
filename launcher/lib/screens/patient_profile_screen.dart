import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../session.dart';
import '../widgets/focusable_tap.dart';
import '../widgets/power_button.dart';
import 'home_screen.dart';
import 'physio_screen.dart';

/// Patient profile: routine calendar for the week, today's prescription
/// ("what is beautiful waiting for you"), suggestions, and the Start Today
/// call to action. Template only — all data is placeholder until the
/// backend API is wired in.
class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);

  // TODO(backend): fetch routine, prescription and suggestions from the API.
  static const _routineDone = [true, true, false, false, false, false, false];

  static List<String> _weekdays(AppLocalizations l10n) => [
    l10n.mon,
    l10n.tue,
    l10n.wed,
    l10n.thu,
    l10n.fri,
    l10n.sat,
    l10n.sun,
  ];

  static List<(String, String)> _prescription(AppLocalizations l10n) => [
    ('Sky Hopper', l10n.presSkyHopper),
    ('Cat Nap Chase', l10n.presCatNap),
    ('YogaFlow', l10n.presYogaFlow),
  ];

  static List<String> _suggestions(AppLocalizations l10n) => [
    l10n.sugg1,
    l10n.sugg2,
    l10n.sugg3,
  ];

  static String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorningName(name);
    if (hour < 17) return l10n.goodAfternoonName(name);
    return l10n.goodEveningName(name);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    double sx(double val) => val * (screenW / 1920.0);
    double sy(double val) => val * (screenH / 1080.0);

    final today = DateTime.now().weekday - 1;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header.
          Positioned(
            top: sy(64),
            left: sx(96),
            right: sx(96),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop()) ...[
                  Padding(
                    padding: EdgeInsets.only(top: sy(20)),
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, size: sy(44), color: _ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: sx(16)),
                ],
                CircleAvatar(
                  radius: sy(44),
                  backgroundColor: _lavenderDeep,
                  child: Icon(Icons.person, color: _ink, size: sy(48)),
                ),
                SizedBox(width: sx(28)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(l10n, Session.firstName),
                        style: TextStyle(
                          color: _ink,
                          fontSize: sy(56),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        l10n.somethingBeautiful,
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.55),
                          fontSize: sy(24),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PowerButton(),
              ],
            ),
          ),

          // Left column: week calendar above today's routine, flowing so
          // neither card can overlap the other regardless of content height.
          Positioned(
            top: sy(240),
            left: sx(96),
            width: sx(1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  sx,
                  sy,
                  title: l10n.yourWeek,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final done = _routineDone[i];
                      final isToday = i == today;
                      return Column(
                        children: [
                          Text(
                            _weekdays(l10n)[i],
                            style: TextStyle(
                              color: _ink.withValues(alpha: isToday ? 1 : 0.45),
                              fontSize: sy(22),
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: sy(12)),
                          Container(
                            width: sy(64),
                            height: sy(64),
                            decoration: BoxDecoration(
                              color: done ? _ink : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isToday
                                    ? _ink
                                    : _ink.withValues(alpha: 0.15),
                                width: isToday ? 2.2 : 1.3,
                              ),
                            ),
                            child: done
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: sy(32),
                                  )
                                : null,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                SizedBox(height: sy(28)),

                // Today's prescription.
                _card(
                  sx,
                  sy,
                  title: l10n.todaysRoutine,
                  child: Column(
                    children: [
                      for (final (name, detail) in _prescription(l10n))
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: sy(10)),
                          child: Row(
                            children: [
                              Container(
                                width: sy(48),
                                height: sy(48),
                                decoration: const BoxDecoration(
                                  color: _lavenderDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.sports_esports_outlined,
                                  color: _ink,
                                  size: sy(26),
                                ),
                              ),
                              SizedBox(width: sx(24)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: _ink,
                                        fontSize: sy(26),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      detail,
                                      style: TextStyle(
                                        color: _ink.withValues(alpha: 0.55),
                                        fontSize: sy(20),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right column: suggestions + physio.
          Positioned(
            top: sy(240),
            left: sx(1194),
            width: sx(630),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  sx,
                  sy,
                  title: l10n.suggestions,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in _suggestions(l10n))
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: sy(8)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: _ink.withValues(alpha: 0.4),
                                size: sy(24),
                              ),
                              SizedBox(width: sx(16)),
                              Expanded(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: sy(22),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: sy(32)),
                FocusableTap(
                  borderRadius: BorderRadius.circular(sy(24)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PhysioScreen()),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(sy(28)),
                    decoration: BoxDecoration(
                      color: _lavender,
                      borderRadius: BorderRadius.circular(sy(24)),
                      border: Border.all(
                        color: _ink.withValues(alpha: 0.12),
                        width: 1.3,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.support_agent, color: _ink, size: sy(40)),
                        SizedBox(width: sx(20)),
                        Expanded(
                          child: Text(
                            l10n.contactPhysio,
                            style: TextStyle(
                              color: _ink,
                              fontSize: sy(26),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _ink, size: sy(32)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Start Today CTA.
          Positioned(
            bottom: sy(48),
            left: sx(96),
            right: sx(96),
            child: Center(
              child: FocusableTap(
                autofocus: true,
                borderRadius: BorderRadius.circular(sy(44)),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const HomeScreen())),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sx(96),
                    vertical: sy(26),
                  ),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(sy(44)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: sy(36),
                      ),
                      SizedBox(width: sx(16)),
                      Text(
                        l10n.startToday,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sy(30),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    double Function(double) sx,
    double Function(double) sy, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(sy(32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sy(24)),
        border: Border.all(color: _ink.withValues(alpha: 0.12), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: sy(30),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: sy(20)),
          child,
        ],
      ),
    );
  }
}
