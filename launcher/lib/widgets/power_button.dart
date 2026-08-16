import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Power control for the kiosk. Opens a centered dialog instead of a
/// [PopupMenuButton]: the button sits in the top-right corner, where a
/// popup menu gets clipped against the screen edge, and a dialog keeps the
/// actions clear and keyboard-accessible.
class PowerButton extends StatelessWidget {
  const PowerButton({super.key, this.size = 44});

  /// Diameter of the circular button, in logical pixels.
  final double size;

  static const _ink = Color(0xFF1C1C1E);

  Future<void> _run(String action) => Process.run('systemctl', [action]);

  Future<void> _showPowerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.power,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.powerQuestion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.55),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _PowerAction(
                  icon: Icons.restart_alt_rounded,
                  label: l10n.restart,
                  onTap: () => Navigator.of(context).pop('reboot'),
                ),
                const SizedBox(height: 14),
                _PowerAction(
                  icon: Icons.power_settings_new_rounded,
                  label: l10n.powerOff,
                  filled: true,
                  onTap: () => Navigator.of(context).pop('poweroff'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: _ink.withValues(alpha: 0.55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action != null) await _run(action);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)?.power ?? 'Power',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showPowerDialog(context),
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
              Icons.power_settings_new_rounded,
              size: size * 0.5,
              color: _ink.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerAction extends StatelessWidget {
  const _PowerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _ink : _lavender,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 26, color: filled ? Colors.white : _ink),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
