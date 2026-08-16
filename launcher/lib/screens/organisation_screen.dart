import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../session.dart';
import '../widgets/focusable_tap.dart';
import '../widgets/power_button.dart';
import 'patient_profile_screen.dart';

/// Organisation login: pick a patient from the dropdown, then verify with a
/// 4-digit OTP. Template only — patient list and OTP check are placeholders
/// until the backend API is wired in.
class OrganisationScreen extends StatefulWidget {
  const OrganisationScreen({super.key});

  @override
  State<OrganisationScreen> createState() => _OrganisationScreenState();
}

class _OrganisationScreenState extends State<OrganisationScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);

  // TODO(backend): fetch patients for this organisation from the API.
  static const _patients = <String>[
    'Aman Kumar M',
    'Puviyarasu P',
    'Aswin R',
    'Karthick S',
    'Sharon Rose L',
    'Vishnu T U',
    'Niveditha R',
    'Eswar R M',
    'Gowtham Raj VP',
  ];

  String? _selected;
  final _otp = <String>[];
  String? _error;

  void _pressDigit(String d) {
    if (_otp.length >= 4) return;
    setState(() {
      _otp.add(d);
      _error = null;
    });
    if (_otp.length == 4) _verify();
  }

  void _backspace() {
    if (_otp.isEmpty) return;
    setState(() => _otp.removeLast());
  }

  void _verify() {
    // TODO(backend): verify OTP against the API. Placeholder accepts 0000.
    if (_otp.join() == '0000') {
      Session.patientName = _selected;
      setState(() => _otp.clear());
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
    } else {
      setState(() {
        _otp.clear();
        _error = AppLocalizations.of(context)!.otpError;
      });
    }
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
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: sx(720)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.whoIsPlaying,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: sy(56),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: sy(12)),
                  Text(
                    l10n.chooseYourName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.55),
                      fontSize: sy(24),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: sy(48)),

                  // Patient dropdown.
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sx(28)),
                    decoration: BoxDecoration(
                      color: _lavender,
                      borderRadius: BorderRadius.circular(sy(20)),
                      border: Border.all(
                        color: _ink.withValues(alpha: 0.12),
                        width: 1.3,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selected,
                        isExpanded: true,
                        hint: Text(
                          l10n.selectPatient,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.45),
                            fontSize: sy(26),
                          ),
                        ),
                        style: TextStyle(
                          color: _ink,
                          fontSize: sy(26),
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          for (final p in _patients)
                            DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) => setState(() => _selected = v),
                      ),
                    ),
                  ),

                  if (_selected != null) ...[
                    SizedBox(height: sy(48)),

                    // OTP boxes.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _otp.length;
                        return Container(
                          width: sx(88),
                          height: sy(104),
                          margin: EdgeInsets.symmetric(horizontal: sx(10)),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled ? _lavenderDeep : _lavender,
                            borderRadius: BorderRadius.circular(sy(18)),
                            border: Border.all(
                              color: _ink.withValues(alpha: 0.12),
                              width: 1.3,
                            ),
                          ),
                          child: Text(
                            filled ? _otp[i] : '',
                            style: TextStyle(
                              color: _ink,
                              fontSize: sy(44),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }),
                    ),

                    if (_error != null) ...[
                      SizedBox(height: sy(16)),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: sy(22),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    SizedBox(height: sy(32)),
                    _keypad(sx, sy),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad(double Function(double) sx, double Function(double) sy) {
    Widget key(String label, {VoidCallback? onTap}) {
      return FocusableTap(
        onTap: onTap ?? () => _pressDigit(label),
        borderRadius: BorderRadius.circular(sy(16)),
        child: Container(
          width: sx(140),
          height: sy(88),
          margin: EdgeInsets.all(sy(6)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sy(16)),
            border: Border.all(color: _ink.withValues(alpha: 0.15), width: 1.3),
          ),
          child: label == '<'
              ? Icon(Icons.backspace_outlined, color: _ink, size: sy(30))
              : Text(
                  label,
                  style: TextStyle(
                    color: _ink,
                    fontSize: sy(32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: sx(152)),
            key('0'),
            key('<', onTap: _backspace),
          ],
        ),
      ],
    );
  }
}
