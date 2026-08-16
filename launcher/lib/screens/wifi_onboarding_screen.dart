import 'package:flutter/material.dart';

import '../widgets/focusable_tap.dart';
import '../widgets/power_button.dart';

class WifiOnboardingScreen extends StatefulWidget {
  const WifiOnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<WifiOnboardingScreen> createState() => _WifiOnboardingScreenState();
}

class _WifiOnboardingScreenState extends State<WifiOnboardingScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);
  static const _networks = <(String, int)>[
    ('Tomoro Home', 4),
    ('JioFiber_5G', 4),
    ('Airtel_2.4G', 3),
    ('Physio Clinic', 3),
    ('Guest Wi-Fi', 2),
  ];
  static const _rows = <String>[
    '1234567890',
    'QWERTYUIOP',
    'ASDFGHJKL',
    'ZXCVBNM',
  ];

  String? _selectedNetwork;
  String? _connectedNetwork;
  String _password = '';
  bool _connecting = false;

  void _chooseNetwork(String name) {
    setState(() {
      _selectedNetwork = name;
      _password = '';
    });
  }

  Future<void> _connect() async {
    if (_password.isEmpty || _connecting) return;
    setState(() => _connecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _connectedNetwork = _selectedNetwork;
      _selectedNetwork = null;
      _connecting = false;
      _password = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    double sx(double value) => value * size.width / 1920;
    double sy(double value) => value * size.height / 1080;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: sy(16), right: sx(16), child: const PowerButton()),
          Padding(
            padding: EdgeInsets.fromLTRB(sx(104), sy(74), sx(104), sy(64)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: _networkList(sx, sy)),
                SizedBox(width: sx(72)),
                Expanded(flex: 11, child: _rightPanel(sx, sy)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkList(double Function(double) sx, double Function(double) sy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect to Wi-Fi',
          style: TextStyle(
            color: _ink,
            fontSize: sy(58),
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: sy(12)),
        Text(
          'Choose a network to get your Tomoro ready.',
          style: TextStyle(
            color: _ink.withValues(alpha: 0.55),
            fontSize: sy(23),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: sy(38)),
        for (final network in _networks) ...[
          _networkTile(network.$1, network.$2, sx, sy),
          SizedBox(height: sy(14)),
        ],
      ],
    );
  }

  Widget _networkTile(
    String name,
    int strength,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final connected = name == _connectedNetwork;
    return FocusableTap(
      autofocus: name == _networks.first.$1,
      borderRadius: BorderRadius.circular(sy(20)),
      onTap: () => _chooseNetwork(name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sx(24), vertical: sy(20)),
        decoration: BoxDecoration(
          color: connected ? _lavenderDeep : _lavender,
          borderRadius: BorderRadius.circular(sy(20)),
          border: Border.all(color: _ink.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_rounded, size: sy(32), color: _ink),
            SizedBox(width: sx(18)),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: _ink,
                  fontSize: sy(24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (connected)
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF2E9E5B),
                size: sy(30),
              )
            else
              Icon(
                Icons.lock_rounded,
                color: _ink.withValues(alpha: 0.42),
                size: sy(24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rightPanel(double Function(double) sx, double Function(double) sy) {
    if (_selectedNetwork != null) return _passwordPanel(sx, sy);
    final connected = _connectedNetwork != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: sy(112),
          height: sy(112),
          decoration: const BoxDecoration(
            color: _lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(
            connected ? Icons.wifi_rounded : Icons.wifi_find_rounded,
            color: _ink,
            size: sy(56),
          ),
        ),
        SizedBox(height: sy(28)),
        Text(
          connected
              ? 'Connected to $_connectedNetwork'
              : 'Select a Wi-Fi network',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: sy(32),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: sy(12)),
        Text(
          connected
              ? 'You are ready to continue.'
              : 'Available networks appear on the left.',
          style: TextStyle(
            color: _ink.withValues(alpha: 0.5),
            fontSize: sy(21),
          ),
        ),
        SizedBox(height: sy(54)),
        if (connected) _actionButton('Continue', widget.onContinue, sx, sy),
      ],
    );
  }

  Widget _passwordPanel(
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter password',
          style: TextStyle(
            color: _ink,
            fontSize: sy(36),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: sy(6)),
        Text(
          _selectedNetwork!,
          style: TextStyle(
            color: _ink.withValues(alpha: 0.55),
            fontSize: sy(22),
          ),
        ),
        SizedBox(height: sy(22)),
        Container(
          height: sy(68),
          padding: EdgeInsets.symmetric(horizontal: sx(24)),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(sy(16)),
            border: Border.all(color: _ink.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            _password.isEmpty ? 'Wi-Fi password' : '•' * _password.length,
            style: TextStyle(
              color: _password.isEmpty ? _ink.withValues(alpha: 0.35) : _ink,
              fontSize: sy(25),
              letterSpacing: _password.isEmpty ? 0 : 4,
            ),
          ),
        ),
        SizedBox(height: sy(22)),
        for (final row in _rows) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final key in row.characters) _key(key, sx, sy)],
          ),
          SizedBox(height: sy(10)),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _wideKey(
              'Space',
              () => setState(() => _password += ' '),
              sx(250),
              sx,
              sy,
            ),
            _wideKey(
              '⌫',
              () {
                if (_password.isNotEmpty) {
                  setState(
                    () => _password = _password.substring(
                      0,
                      _password.length - 1,
                    ),
                  );
                }
              },
              sx(110),
              sx,
              sy,
            ),
          ],
        ),
        SizedBox(height: sy(24)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _secondaryButton(
              'Cancel',
              () => setState(() => _selectedNetwork = null),
              sx,
              sy,
            ),
            SizedBox(width: sx(14)),
            _actionButton(
              _connecting ? 'Connecting…' : 'Connect',
              _password.isEmpty ? null : _connect,
              sx,
              sy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(
    String label,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sx(4)),
      child: _wideKey(
        label,
        () => setState(() => _password += label),
        sx(57),
        sx,
        sy,
      ),
    );
  }

  Widget _wideKey(
    String label,
    VoidCallback onTap,
    double width,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return FocusableTap(
      borderRadius: BorderRadius.circular(sy(10)),
      onTap: onTap,
      child: Container(
        width: width,
        height: sy(52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _lavender,
          borderRadius: BorderRadius.circular(sy(10)),
          border: Border.all(color: _ink.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _ink,
            fontSize: sy(18),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    VoidCallback? onTap,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return FocusableTap(
      borderRadius: BorderRadius.circular(sy(30)),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sx(44), vertical: sy(17)),
        decoration: BoxDecoration(
          color: onTap == null ? _ink.withValues(alpha: 0.3) : _ink,
          borderRadius: BorderRadius.circular(sy(30)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: sy(21),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(
    String label,
    VoidCallback onTap,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return FocusableTap(
      borderRadius: BorderRadius.circular(sy(30)),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sx(34), vertical: sy(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sy(30)),
          border: Border.all(color: _ink.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _ink,
            fontSize: sy(21),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
