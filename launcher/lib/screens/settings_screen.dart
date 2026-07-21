import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../languages.dart';
import '../session.dart';
import '../widgets/onscreen_keyboard.dart';

// ---------------------------------------------------------------------------
// Timezone picker dialog
// ---------------------------------------------------------------------------

class _TzPickerDialog extends StatefulWidget {
  const _TzPickerDialog({required this.current});
  final String current;

  @override
  State<_TzPickerDialog> createState() => _TzPickerDialogState();
}

class _TzPickerDialogState extends State<_TzPickerDialog> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);

  List<String>? _allZones;
  String _query = '';
  bool _loading = true;
  String? _applying;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Process.run('timedatectl', ['list-timezones']);
      final zones = (result.stdout as String)
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (mounted) setState(() { _allZones = zones; _loading = false; });
    } on Exception {
      if (mounted) setState(() { _allZones = []; _loading = false; });
    }
  }

  List<String> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _allZones ?? [];
    return (_allZones ?? []).where((z) => z.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    double sy(double v) => v * (screenH / 1080.0);
    double sx(double v) => v * (screenW / 1920.0);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sy(28))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sx(900), maxHeight: sy(800)),
        child: Padding(
          padding: EdgeInsets.all(sy(32)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectTimeZone,
                style: TextStyle(color: _ink, fontSize: sy(36), fontWeight: FontWeight.w800),
              ),
              SizedBox(height: sy(20)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: sx(24), vertical: sy(12)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(sy(14)),
                  border: Border.all(color: _ink.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: _ink.withValues(alpha: 0.45), size: sy(28)),
                    SizedBox(width: sx(16)),
                    Expanded(
                      child: Text(
                        _query.isEmpty
                            ? AppLocalizations.of(context)!.searchTimeZones
                            : _query,
                        style: TextStyle(
                          color: _query.isEmpty ? _ink.withValues(alpha: 0.35) : _ink,
                          fontSize: sy(24),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _query = ''),
                        child: Icon(Icons.close_rounded, size: sy(26), color: _ink.withValues(alpha: 0.45)),
                      ),
                  ],
                ),
              ),
              SizedBox(height: sy(8)),
              OnscreenKeyboard(
                onKey: (k) => setState(() => _query += k),
                onBackspace: () => setState(() {
                  if (_query.isNotEmpty) _query = _query.substring(0, _query.length - 1);
                }),
                onSubmit: () {},
              ),
              SizedBox(height: sy(16)),
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: sy(8)),
                  child: Text(_error!, style: TextStyle(color: Colors.redAccent, fontSize: sy(20))),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _ink))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final tz = _filtered[i];
                          final isCurrent = tz == widget.current;
                          final applying = _applying == tz;
                          return InkWell(
                            borderRadius: BorderRadius.circular(sy(12)),
                            onTap: applying || isCurrent
                                ? null
                                : () async {
                                    setState(() { _applying = tz; _error = null; });
                                    final ok = await Session.setTimeZone(tz);
                                    if (!mounted) return;
                                    if (ok) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pop();
                                    } else {
                                      setState(() { _applying = null; _error = 'Failed to set timezone'; });
                                    }
                                  },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: sx(16), vertical: sy(14)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tz,
                                      style: TextStyle(
                                        color: isCurrent ? const Color(0xFF7C3AED) : _ink,
                                        fontSize: sy(24),
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (applying)
                                    SizedBox(width: sy(24), height: sy(24),
                                      child: const CircularProgressIndicator(strokeWidth: 3, color: _ink))
                                  else if (isCurrent)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: sx(16), vertical: sy(6)),
                                      decoration: BoxDecoration(
                                        color: _lavender,
                                        borderRadius: BorderRadius.circular(sy(20)),
                                      ),
                                      child: Text('Current',
                                        style: TextStyle(color: const Color(0xFF7C3AED), fontSize: sy(20), fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: sy(8)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(color: _ink.withValues(alpha: 0.55), fontSize: sy(22)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings screen matching the home screen aesthetic: white canvas, ink
/// headlines, lavender accents. Currently hosts the Network section, which
/// polls the `tomoro-net` Rust binary for ethernet/wifi state.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _NetworkInterface {
  const _NetworkInterface({
    required this.name,
    required this.kind,
    required this.up,
    required this.carrier,
    required this.ipv4,
    this.mac,
    this.ssid,
    this.signalDbm,
  });

  factory _NetworkInterface.fromJson(Map<String, dynamic> json) {
    return _NetworkInterface(
      name: json['name'] as String,
      kind: json['kind'] as String,
      up: json['up'] as bool,
      carrier: json['carrier'] as bool,
      ipv4: (json['ipv4'] as List<dynamic>).cast<String>(),
      mac: json['mac'] as String?,
      ssid: json['ssid'] as String?,
      signalDbm: json['signal_dbm'] as int?,
    );
  }

  final String name;
  final String kind; // 'ethernet' | 'wifi'
  final bool up;
  final bool carrier;
  final List<String> ipv4;
  final String? mac;
  final String? ssid;
  final int? signalDbm;

  bool get isWifi => kind == 'wifi';
  bool get connected => carrier && ipv4.isNotEmpty;
}

class _WifiNetwork {
  const _WifiNetwork({
    required this.ssid,
    required this.signalDbm,
    required this.secured,
  });

  factory _WifiNetwork.fromJson(Map<String, dynamic> json) => _WifiNetwork(
    ssid: json['ssid'] as String,
    signalDbm: json['signal_dbm'] as int,
    secured: json['secured'] as bool,
  );

  final String ssid;
  final int signalDbm;
  final bool secured;
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);

  List<_NetworkInterface>? _interfaces;
  bool _online = false;
  String? _error;
  Timer? _pollTimer;

  // Wifi scan state, keyed to the interface whose panel is expanded.
  String? _scanIface;
  List<_WifiNetwork>? _scanResults;
  bool _scanning = false;
  String? _connectingSsid;
  String? _wifiError;

  @override
  void initState() {
    super.initState();
    Session.loadTimeSettings();
    Session.use24h.addListener(_onTimeSettingChange);
    Session.timeZone.addListener(_onTimeSettingChange);
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  void _onTimeSettingChange() => setState(() {});

  @override
  void dispose() {
    _pollTimer?.cancel();
    Session.use24h.removeListener(_onTimeSettingChange);
    Session.timeZone.removeListener(_onTimeSettingChange);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final result = await Process.run('tomoro-net', const ['status']);
      if (result.exitCode != 0) {
        throw ProcessException(
          'tomoro-net',
          const ['status'],
          result.stderr as String,
          result.exitCode,
        );
      }
      final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _interfaces = (data['interfaces'] as List<dynamic>)
            .map((e) => _NetworkInterface.fromJson(e as Map<String, dynamic>))
            .toList();
        _online = data['online'] as bool;
        _error = null;
      });
    } on Exception {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context)!.networkServiceUnavailable,
      );
    }
  }

  Future<void> _scan(String iface) async {
    setState(() {
      _scanIface = iface;
      _scanning = true;
      _wifiError = null;
    });
    try {
      final result = await Process.run('tomoro-net', ['scan', iface]);
      final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _scanning = false;
        if (data['error'] != null) {
          _wifiError = data['error'] as String;
          _scanResults = null;
        } else {
          _scanResults = (data['networks'] as List<dynamic>)
              .map((e) => _WifiNetwork.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _wifiError = AppLocalizations.of(context)!.scanFailed;
      });
    }
  }

  Future<void> _connect(String iface, _WifiNetwork net) async {
    String? psk;
    if (net.secured) {
      psk = await _promptPassword(net.ssid);
      if (psk == null || psk.isEmpty) return;
    }
    setState(() {
      _connectingSsid = net.ssid;
      _wifiError = null;
    });
    try {
      final result = await Process.run('tomoro-net', [
        'connect',
        iface,
        net.ssid,
        ?psk,
      ]);
      final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _connectingSsid = null;
        if (data['error'] != null) {
          _wifiError = data['error'] as String;
        } else {
          _scanResults = null;
          _scanIface = null;
        }
      });
      unawaited(_refresh());
    } on Exception {
      if (!mounted) return;
      setState(() {
        _connectingSsid = null;
        _wifiError = AppLocalizations.of(context)!.connectionFailed;
      });
    }
  }

  Future<String?> _promptPassword(String ssid) {
    var value = '';
    var obscure = true;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.passwordFor(ssid),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _ink.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value.isEmpty
                                ? AppLocalizations.of(context)!.enterPassword
                                : obscure
                                ? '•' * value.length
                                : value,
                            style: TextStyle(
                              color: value.isEmpty
                                  ? _ink.withValues(alpha: 0.35)
                                  : _ink,
                              fontSize: 24,
                              letterSpacing: obscure ? 3 : 0,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: _ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OnscreenKeyboard(
                    onKey: (k) => setDialogState(() => value += k),
                    onBackspace: () => setDialogState(() {
                      if (value.isNotEmpty) {
                        value = value.substring(0, value.length - 1);
                      }
                    }),
                    onSubmit: () => Navigator.of(context).pop(value),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.55),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sx(96), vertical: sy(64)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: sy(44),
                  icon: Icon(Icons.arrow_back_rounded, color: _ink),
                ),
                SizedBox(width: sx(24)),
                Text(
                  l10n.settings,
                  style: TextStyle(
                    color: _ink,
                    fontSize: sy(72),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                _onlineBadge(sx, sy),
              ],
            ),
            SizedBox(height: sy(32)),
            Container(height: 1.3, color: Colors.black.withValues(alpha: 0.15)),
            SizedBox(height: sy(40)),
            _sectionTitle(l10n.language, sy),
            SizedBox(height: sy(24)),
            _languagePicker(sx, sy),
            SizedBox(height: sy(40)),
            _sectionTitle(l10n.timeFormat, sy),
            SizedBox(height: sy(20)),
            _clockFormatPicker(sx, sy, l10n),
            SizedBox(height: sy(20)),
            _timeZoneRow(sx, sy, l10n),
            SizedBox(height: sy(40)),
            _sectionTitle(l10n.network, sy),
            SizedBox(height: sy(28)),
            Expanded(child: _networkBody(sx, sy)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, double Function(double) sy) {
    return Text(
      text,
      style: TextStyle(
        color: _ink,
        fontSize: sy(44),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _languagePicker(
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final current = Session.locale.value.languageCode;
    return Wrap(
      spacing: sx(20),
      runSpacing: sy(16),
      children: [
        for (final lang in appLanguages)
          _languagePill(lang, lang.code == current, sx, sy),
      ],
    );
  }

  Widget _languagePill(
    AppLanguage lang,
    bool selected,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Material(
      color: selected ? _ink : _lavender,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sy(40)),
        side: BorderSide(
          color: selected ? _ink : _ink.withValues(alpha: 0.12),
          width: 1.3,
        ),
      ),
      child: InkWell(
        // MaterialApp listens to Session.locale, so the whole app —
        // including this screen — re-renders in the new language.
        onTap: () => Session.locale.value = Locale(lang.code),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sx(36), vertical: sy(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: sy(26), color: Colors.white),
                SizedBox(width: sx(12)),
              ],
              Text(
                lang.native,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: sy(24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clockFormatPicker(
    double Function(double) sx,
    double Function(double) sy,
    AppLocalizations l10n,
  ) {
    final is24 = Session.use24h.value;
    return Wrap(
      spacing: sx(20),
      children: [
        _formatPill(l10n.hour12, !is24, () => Session.setUse24h(false), sx, sy),
        _formatPill(l10n.hour24, is24, () => Session.setUse24h(true), sx, sy),
      ],
    );
  }

  Widget _formatPill(
    String label,
    bool selected,
    VoidCallback onTap,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Material(
      color: selected ? _ink : _lavender,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sy(40)),
        side: BorderSide(
          color: selected ? _ink : _ink.withValues(alpha: 0.12),
          width: 1.3,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sx(36), vertical: sy(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: sy(26), color: Colors.white),
                SizedBox(width: sx(12)),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: sy(24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeZoneRow(
    double Function(double) sx,
    double Function(double) sy,
    AppLocalizations l10n,
  ) {
    final tz = Session.timeZone.value;
    return Row(
      children: [
        Icon(Icons.public_rounded, size: sy(36), color: _ink.withValues(alpha: 0.55)),
        SizedBox(width: sx(20)),
        Text(
          tz.isEmpty ? '—' : tz,
          style: TextStyle(color: _ink, fontSize: sy(26), fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            padding: EdgeInsets.symmetric(horizontal: sx(28), vertical: sy(14)),
          ),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _TzPickerDialog(current: tz),
          ),
          child: Text(
            l10n.changeTimeZone,
            style: TextStyle(fontSize: sy(22), fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _onlineBadge(double Function(double) sx, double Function(double) sy) {
    final color = _online ? const Color(0xFF2E9E5B) : Colors.redAccent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sx(24), vertical: sy(10)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(sy(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: sy(14), color: color),
          SizedBox(width: sx(10)),
          Text(
            _online
                ? AppLocalizations.of(context)!.online
                : AppLocalizations.of(context)!.offline,
            style: TextStyle(
              color: color,
              fontSize: sy(22),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkBody(double Function(double) sx, double Function(double) sy) {
    if (_error != null) {
      return _message(Icons.error_outline_rounded, _error!, sy);
    }
    final interfaces = _interfaces;
    if (interfaces == null) {
      return const Center(child: CircularProgressIndicator(color: _ink));
    }
    if (interfaces.isEmpty) {
      return _message(
        Icons.wifi_off_rounded,
        AppLocalizations.of(context)!.noNetworkHardware,
        sy,
      );
    }
    return ListView.separated(
      itemCount: interfaces.length,
      separatorBuilder: (_, _) => SizedBox(height: sy(24)),
      itemBuilder: (_, i) => _interfaceCard(interfaces[i], sx, sy),
    );
  }

  Widget _message(IconData icon, String text, double Function(double) sy) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sy(64), color: _ink.withValues(alpha: 0.35)),
          SizedBox(height: sy(16)),
          Text(
            text,
            style: TextStyle(
              color: _ink.withValues(alpha: 0.55),
              fontSize: sy(26),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interfaceCard(
    _NetworkInterface iface,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statusText = iface.connected
        ? l10n.connected
        : iface.carrier
        ? l10n.linkUpNoAddress
        : iface.isWifi
        ? l10n.notConnected
        : l10n.cableUnplugged;
    final details = <String>[
      if (iface.isWifi && iface.ssid != null) iface.ssid!,
      if (iface.ipv4.isNotEmpty) iface.ipv4.join(', '),
      if (iface.isWifi && iface.signalDbm != null) '${iface.signalDbm} dBm',
      if (iface.mac != null) iface.mac!,
    ];

    final expanded = _scanIface == iface.name;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sx(36), vertical: sy(28)),
      decoration: BoxDecoration(
        color: iface.connected ? _lavender : Colors.white,
        borderRadius: BorderRadius.circular(sy(28)),
        border: Border.all(color: _ink.withValues(alpha: 0.12), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _interfaceHeader(iface, statusText, details, sx, sy),
          if (iface.isWifi && expanded) _scanPanel(iface, sx, sy),
        ],
      ),
    );
  }

  Widget _interfaceHeader(
    _NetworkInterface iface,
    String statusText,
    List<String> details,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Row(
      children: [
        Icon(
          iface.isWifi ? _wifiIcon(iface) : Icons.settings_ethernet_rounded,
          size: sy(48),
          color: iface.connected ? _ink : _ink.withValues(alpha: 0.35),
        ),
        SizedBox(width: sx(32)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${iface.isWifi ? AppLocalizations.of(context)!.wifi : AppLocalizations.of(context)!.ethernet}  ·  ${iface.name}',
                style: TextStyle(
                  color: _ink,
                  fontSize: sy(30),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (details.isNotEmpty) ...[
                SizedBox(height: sy(6)),
                Text(
                  details.join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.55),
                    fontSize: sy(22),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: sx(24)),
        Text(
          statusText,
          style: TextStyle(
            color: iface.connected
                ? const Color(0xFF2E9E5B)
                : _ink.withValues(alpha: 0.45),
            fontSize: sy(24),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (iface.isWifi) ...[
          SizedBox(width: sx(24)),
          _scanIface == iface.name
              ? IconButton(
                  tooltip: AppLocalizations.of(context)!.close,
                  onPressed: () => setState(() {
                    _scanIface = null;
                    _scanResults = null;
                    _wifiError = null;
                  }),
                  icon: Icon(
                    Icons.expand_less_rounded,
                    size: sy(36),
                    color: _ink,
                  ),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    padding: EdgeInsets.symmetric(
                      horizontal: sx(28),
                      vertical: sy(14),
                    ),
                  ),
                  onPressed: () => _scan(iface.name),
                  icon: Icon(Icons.radar_rounded, size: sy(26)),
                  label: Text(
                    AppLocalizations.of(context)!.scan,
                    style: TextStyle(
                      fontSize: sy(22),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  Widget _scanPanel(
    _NetworkInterface iface,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: sy(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: _ink.withValues(alpha: 0.1)),
          SizedBox(height: sy(16)),
          if (_wifiError != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: sy(8)),
              child: Text(
                _wifiError!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: sy(22),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_scanning)
            Padding(
              padding: EdgeInsets.symmetric(vertical: sy(20)),
              child: Row(
                children: [
                  SizedBox(
                    width: sy(28),
                    height: sy(28),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _ink,
                    ),
                  ),
                  SizedBox(width: sx(20)),
                  Text(
                    AppLocalizations.of(context)!.scanning,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.55),
                      fontSize: sy(24),
                    ),
                  ),
                ],
              ),
            )
          else if (_scanResults != null && _scanResults!.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: sy(12)),
              child: Text(
                AppLocalizations.of(context)!.noNetworksFound,
                style: TextStyle(
                  color: _ink.withValues(alpha: 0.55),
                  fontSize: sy(24),
                ),
              ),
            )
          else if (_scanResults != null)
            for (final net in _scanResults!) _networkRow(iface, net, sx, sy),
        ],
      ),
    );
  }

  Widget _networkRow(
    _NetworkInterface iface,
    _WifiNetwork net,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final connecting = _connectingSsid == net.ssid;
    final isCurrent = iface.ssid == net.ssid && iface.connected;
    return InkWell(
      borderRadius: BorderRadius.circular(sy(16)),
      onTap: connecting || isCurrent ? null : () => _connect(iface.name, net),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sx(12), vertical: sy(16)),
        child: Row(
          children: [
            Icon(
              net.signalDbm >= -60
                  ? Icons.wifi_rounded
                  : net.signalDbm >= -75
                  ? Icons.wifi_2_bar_rounded
                  : Icons.wifi_1_bar_rounded,
              size: sy(32),
              color: _ink.withValues(alpha: 0.7),
            ),
            SizedBox(width: sx(24)),
            Expanded(
              child: Text(
                net.ssid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: sy(26),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (net.secured)
              Icon(
                Icons.lock_outline_rounded,
                size: sy(24),
                color: _ink.withValues(alpha: 0.45),
              ),
            SizedBox(width: sx(20)),
            if (connecting)
              SizedBox(
                width: sy(26),
                height: sy(26),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _ink,
                ),
              )
            else if (isCurrent)
              Text(
                AppLocalizations.of(context)!.connected,
                style: TextStyle(
                  color: const Color(0xFF2E9E5B),
                  fontSize: sy(22),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: sy(32),
                color: _ink.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }

  IconData _wifiIcon(_NetworkInterface iface) {
    if (!iface.connected) return Icons.wifi_off_rounded;
    final dbm = iface.signalDbm;
    if (dbm == null || dbm >= -60) return Icons.wifi_rounded;
    if (dbm >= -75) return Icons.wifi_2_bar_rounded;
    return Icons.wifi_1_bar_rounded;
  }
}
