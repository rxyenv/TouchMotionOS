import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../store_client.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);
  static const _accentGreen = Color(0xFF34C759);

  // Backend URL — injected via env at build time; fallback for dev.
  static final _backendUrl =
      Platform.environment['TOMORO_BACKEND'] ?? 'http://localhost:8000';

  List<Map<String, dynamic>> _catalog = [];
  bool _loading = true;
  String? _error;

  // id → install progress pct (null = not installing)
  final Map<String, int?> _installing = {};
  // ids that daemon confirmed installed this session
  final Set<String> _installed = {};

  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = StoreClient.instance.events.listen(_onEvent);
    _fetchCatalog();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request =
          await client.getUrl(Uri.parse('$_backendUrl/catalog'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _catalog = List<Map<String, dynamic>>.from(
            (data['games'] as List? ?? []).map((g) => Map<String, dynamic>.from(g as Map)),
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onEvent(Map<String, dynamic> ev) {
    if (!mounted) return;
    final type = ev['type'] as String?;
    final id = ev['id'] as String?;
    setState(() {
      if (type == 'progress' && id != null) {
        _installing[id] = ev['pct'] as int? ?? 0;
      } else if (type == 'installed' && id != null) {
        _installing.remove(id);
        _installed.add(id);
      } else if (type == 'error' && id != null) {
        _installing.remove(id);
      }
    });
  }

  void _install(String id) {
    if (_installing.containsKey(id) || _installed.contains(id)) return;
    setState(() => _installing[id] = 0);
    StoreClient.instance.send({'cmd': 'install', 'id': id});
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const figmaW = 1920.0;
    const figmaH = 1080.0;
    double sx(double v) => v * (screenW / figmaW);
    double sy(double v) => v * (screenH / figmaH);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _ink));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load store',
              style: TextStyle(
                color: _ink,
                fontSize: sy(28),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: sy(16)),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.5),
                fontSize: sy(18),
              ),
            ),
            SizedBox(height: sy(32)),
            ElevatedButton(
              onPressed: _fetchCatalog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: sx(40),
                  vertical: sy(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sy(14)),
                ),
              ),
              child: Text('Retry', style: TextStyle(fontSize: sy(20))),
            ),
          ],
        ),
      );
    }

    if (_catalog.isEmpty) {
      return Center(
        child: Text(
          'No games in store yet.',
          style: TextStyle(
            color: _ink.withValues(alpha: 0.45),
            fontSize: sy(24),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: sx(96), vertical: sy(32)),
      child: Wrap(
        spacing: sx(48),
        runSpacing: sy(48),
        children: [
          for (final g in _catalog) _storeCard(g, sx, sy),
        ],
      ),
    );
  }

  Widget _storeCard(
    Map<String, dynamic> game,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final id = game['id'] as String;
    final name = game['name'] as String? ?? id;
    final desc = game['description'] as String? ?? '';
    final sizeMb = ((game['size_bytes'] as int? ?? 0) / 1024 / 1024).round();
    final pct = _installing[id];
    final isInstalling = pct != null;
    final isInstalled = _installed.contains(id);

    return SizedBox(
      width: sx(520),
      height: sy(340),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sy(28)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sy(28)),
            side: BorderSide(color: _ink.withValues(alpha: 0.1), width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_lavender, _lavenderDeep],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.sports_esports_rounded,
                          size: sy(80),
                          color: _ink.withValues(alpha: 0.2),
                        ),
                      ),
                      if (isInstalling)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: (pct ?? 0) / 100.0,
                            backgroundColor: _lavenderDeep,
                            color: _ink,
                            minHeight: sy(6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(sx(32), sy(18), sx(24), sy(18)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: _ink,
                              fontSize: sy(26),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (desc.isNotEmpty) ...[
                            SizedBox(height: sy(4)),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ink.withValues(alpha: 0.5),
                                fontSize: sy(17),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                          SizedBox(height: sy(6)),
                          Text(
                            '${sizeMb} MB',
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.35),
                              fontSize: sy(15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: sx(16)),
                    _actionButton(id, isInstalling, isInstalled, pct, sy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String id,
    bool isInstalling,
    bool isInstalled,
    int? pct,
    double Function(double) sy,
  ) {
    if (isInstalled) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: sy(16),
          vertical: sy(10),
        ),
        decoration: BoxDecoration(
          color: _accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(sy(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: _accentGreen, size: sy(18)),
            SizedBox(width: sy(6)),
            Text(
              'Installed',
              style: TextStyle(
                color: _accentGreen,
                fontSize: sy(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (isInstalling) {
      return SizedBox(
        width: sy(40),
        height: sy(40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: (pct ?? 0) / 100.0,
              strokeWidth: 2.5,
              color: _ink,
            ),
            Text(
              '${pct ?? 0}%',
              style: TextStyle(
                color: _ink,
                fontSize: sy(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _install(id),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: sy(20),
          vertical: sy(10),
        ),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(sy(12)),
        ),
        child: Text(
          'Get',
          style: TextStyle(
            color: Colors.white,
            fontSize: sy(17),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
