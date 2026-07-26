import 'dart:async';

import 'package:flutter/material.dart';

import '../store_client.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _ink = Color(0xFF1C1C1E);
  static const _lavender = Color(0xFFF2E7FA);
  static const _lavenderDeep = Color(0xFFE3CDF6);

  List<Map<String, dynamic>> _games = [];
  final Map<String, double> _launching = {};
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = StoreClient.instance.events.listen(_onEvent);
    StoreClient.instance.send({'cmd': 'list'});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(Map<String, dynamic> ev) {
    final type = ev['type'] as String?;
    if (!mounted) return;
    setState(() {
      if (type == 'list') {
        _games = List<Map<String, dynamic>>.from(
          (ev['games'] as List? ?? []).map((g) => Map<String, dynamic>.from(g as Map)),
        );
      } else if (type == 'launched') {
        _launching.remove(ev['id']);
      } else if (type == 'error') {
        _launching.remove(ev['id']);
      }
    });
  }

  void _launch(String id) {
    if (_launching.containsKey(id)) return;
    setState(() => _launching[id] = 0);
    StoreClient.instance.send({'cmd': 'launch', 'id': id});
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const figmaW = 1920.0;
    const figmaH = 1080.0;
    double sx(double v) => v * (screenW / figmaW);
    double sy(double v) => v * (screenH / figmaH);

    if (_games.isEmpty) {
      return Center(
        child: Text(
          'No games installed yet.\nBrowse the Store to download.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink.withValues(alpha: 0.45),
            fontSize: sy(24),
            fontWeight: FontWeight.w500,
            height: 1.5,
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
          for (final g in _games) _gameCard(g, sx, sy),
        ],
      ),
    );
  }

  Widget _gameCard(
    Map<String, dynamic> game,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final id = game['id'] as String;
    final name = game['name'] as String? ?? id;
    final launching = _launching.containsKey(id);

    return SizedBox(
      width: sx(480),
      height: sy(300),
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
          child: InkWell(
            focusColor: _lavenderDeep.withValues(alpha: 0.45),
            onTap: launching ? null : () => _launch(id),
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
                    child: Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        size: sy(72),
                        color: _ink.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: sx(32),
                    vertical: sy(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: _ink,
                            fontSize: sy(28),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      SizedBox(width: sx(16)),
                      launching
                          ? SizedBox(
                              width: sy(32),
                              height: sy(32),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _ink,
                              ),
                            )
                          : Container(
                              width: sy(50),
                              height: sy(50),
                              decoration: const BoxDecoration(
                                color: _ink,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: sy(32),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
