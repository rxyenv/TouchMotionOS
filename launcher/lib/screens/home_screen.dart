import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../session.dart';
import '../widgets/power_button.dart';
import 'library_screen.dart';
import 'physio_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';

/// Tomoro home screen, styled after the onboarding slides: white canvas,
/// hand-drawn illustration accents, soft lavender fills and bold dark
/// headlines laid out against the 1920x1080 Figma reference frame.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _ink = Color(0xFF1C1C1E);

  int _tabIndex = 0; // 0 = Library, 1 = Store

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() => _now = DateTime.now());
    });
    Session.use24h.addListener(_onFormatChange);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    Session.use24h.removeListener(_onFormatChange);
    super.dispose();
  }

  void _onFormatChange() => setState(() {});

  String get _clock {
    final m = _now.minute.toString().padLeft(2, '0');
    if (Session.use24h.value) {
      final h = _now.hour.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final ampm = _now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _greeting(AppLocalizations l10n) {
    if (_now.hour < 12) return l10n.goodMorning;
    if (_now.hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const figmaW = 1920.0;
    const figmaH = 1080.0;
    double sx(double val) => val * (screenW / figmaW);
    double sy(double val) => val * (screenH / figmaH);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: screenW,
        height: screenH,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Header: greeting + clock + power.
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
                        icon: Icon(
                          Icons.chevron_left,
                          size: sy(44),
                          color: _ink,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: sx(8)),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: sy(72),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: sy(12)),
                        Text(
                          l10n.pickAGame,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.55),
                            fontSize: sy(26),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clock and controls sit on the greeting's first line.
                  Padding(
                    padding: EdgeInsets.only(top: sy(14)),
                    child: Row(
                      children: [
                        Text(
                          _clock,
                          style: TextStyle(
                            color: _ink,
                            fontSize: sy(30),
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(width: sx(36)),
                        _headerButton(
                          tooltip: l10n.contactPhysio,
                          icon: Icons.support_agent_rounded,
                          size: sy(56),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PhysioScreen(),
                            ),
                          ),
                        ),
                        SizedBox(width: sx(16)),
                        _headerButton(
                          tooltip: l10n.settings,
                          icon: Icons.settings_outlined,
                          size: sy(56),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        SizedBox(width: sx(16)),
                        PowerButton(size: sy(56)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider line, same treatment as the slides.
            Positioned(
              top: sy(252),
              left: sx(96),
              right: sx(96),
              child: Container(
                height: 1.3,
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),

            // Tab bar: Library | Store
            Positioned(
              top: sy(272),
              left: sx(96),
              child: Row(
                children: [
                  _tab(l10n.library, 0, sy),
                  SizedBox(width: sx(8)),
                  _tab('Store', 1, sy),
                ],
              ),
            ),

            // Tab content
            Positioned(
              top: sy(352),
              left: 0,
              right: 0,
              bottom: sy(40),
              child: _tabIndex == 0
                  ? const LibraryScreen()
                  : const StoreScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index, double Function(double) sy) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: sy(28),
          vertical: sy(10),
        ),
        decoration: BoxDecoration(
          color: active ? _ink : Colors.transparent,
          borderRadius: BorderRadius.circular(sy(12)),
          border: active
              ? null
              : Border.all(color: _ink.withValues(alpha: 0.15), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _ink.withValues(alpha: 0.55),
            fontSize: sy(20),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _headerButton({
    required String tooltip,
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _ink.withValues(alpha: 0.15),
                width: 1.3,
              ),
            ),
            child: Icon(
              icon,
              size: size * 0.5,
              color: _ink.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

}
