import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/focusable_tap.dart';
import '../widgets/power_button.dart';

/// Contact-my-physio screen: consult a physio or book an appointment.
/// Template only — actions show a confirmation snack until the backend
/// booking API is wired in.
class PhysioScreen extends StatelessWidget {
  const PhysioScreen({super.key});

  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);

  void _notYet(BuildContext context, String action) {
    // TODO(backend): send consult/booking request through the API.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        content: Text(AppLocalizations.of(context)!.physioNotified(action)),
      ),
    );
  }

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
              constraints: BoxConstraints(maxWidth: sx(900)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: sy(64),
                    backgroundColor: _lavenderDeep,
                    child: Icon(Icons.support_agent, color: _ink, size: sy(64)),
                  ),
                  SizedBox(height: sy(32)),
                  Text(
                    l10n.contactPhysio,
                    style: TextStyle(
                      color: _ink,
                      fontSize: sy(56),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: sy(12)),
                  Text(
                    // TODO(backend): show the assigned physio's name.
                    l10n.physioAssigned,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.55),
                      fontSize: sy(24),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: sy(64)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionCard(
                        context,
                        sx,
                        sy,
                        icon: Icons.videocam_outlined,
                        title: l10n.consultNow,
                        subtitle: l10n.consultNowSub,
                        onTap: () => _notYet(context, l10n.consultRequested),
                      ),
                      SizedBox(width: sx(40)),
                      _actionCard(
                        context,
                        sx,
                        sy,
                        icon: Icons.calendar_month_outlined,
                        title: l10n.bookAppointment,
                        subtitle: l10n.bookAppointmentSub,
                        onTap: () =>
                            _notYet(context, l10n.appointmentRequested),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context,
    double Function(double) sx,
    double Function(double) sy, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FocusableTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(sy(28)),
      child: Container(
        width: sx(380),
        padding: EdgeInsets.all(sy(36)),
        decoration: BoxDecoration(
          color: _lavender,
          borderRadius: BorderRadius.circular(sy(28)),
          border: Border.all(color: _ink.withValues(alpha: 0.12), width: 1.3),
        ),
        child: Column(
          children: [
            Icon(icon, color: _ink, size: sy(56)),
            SizedBox(height: sy(20)),
            Text(
              title,
              style: TextStyle(
                color: _ink,
                fontSize: sy(30),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: sy(8)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.55),
                fontSize: sy(20),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
