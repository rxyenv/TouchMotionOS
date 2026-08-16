import 'dart:async';

import 'package:flutter/material.dart';

import 'gamepad_navigator.dart';
import 'onboarding_state.dart';
import 'remote_service.dart';
import 'screens/organisation_screen.dart';

/// Blocks patient UI until a trusted remote is paired and connected.
class RemoteGate extends StatefulWidget {
  const RemoteGate({super.key, required this.onboarding});
  final Widget onboarding;

  @override
  State<RemoteGate> createState() => _RemoteGateState();
}

class _RemoteGateState extends State<RemoteGate> {
  RemoteStatus? _status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final status = await RemoteService.status();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || !status.paired) {
      if (OnboardingState.remoteSetupSkipped) {
        return OnboardingState.isDone
            ? const OrganisationScreen()
            : widget.onboarding;
      }
      return _PairingScreen(
        onPaired: _refresh,
        onSkip: () => setState(OnboardingState.markRemoteSetupSkipped),
      );
    }
    if (!status.connected) return const _ReconnectScreen();
    if (!OnboardingState.remoteTutorialDone)
      return _RemoteTutorial(onDone: () => setState(() {}));
    return OnboardingState.isDone
        ? const OrganisationScreen()
        : widget.onboarding;
  }
}

class _PairingScreen extends StatefulWidget {
  const _PairingScreen({required this.onPaired, required this.onSkip});
  final Future<void> Function() onPaired;
  final VoidCallback onSkip;

  @override
  State<_PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<_PairingScreen> {
  List<RemoteDevice>? _devices;
  String? _error;
  bool _busy = false;

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _error = null;
      _devices = null;
    });
    final devices = await RemoteService.scan();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _devices = devices;
      if (devices == null) _error = 'Scan failed. Check Bluetooth.';
    });
  }

  Future<void> _pair(RemoteDevice device) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await RemoteService.pair(device.mac);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error != null) _error = error;
    });
    if (error == null) await widget.onPaired();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bluetooth_searching_rounded,
                        size: 84, color: Color(0xFF7C3AED)),
                    const SizedBox(height: 24),
                    const Text('Connect remote',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    const Text(
                      'Put the Irusu remote in pairing mode, then scan nearby Bluetooth devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _busy ? null : _scan,
                      icon: const Icon(Icons.radar_rounded),
                      label: Text(_busy ? 'Scanning…' : 'Scan for remotes'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : widget.onSkip,
                      child: const Text('Skip remote setup for now'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                    if (_devices != null) ...[
                      const SizedBox(height: 18),
                      Text(_devices!.isEmpty
                          ? 'No devices found. Keep the remote in pairing mode and scan again.'
                          : 'Select your Irusu remote:',
                          textAlign: TextAlign.center),
                      for (final device in _devices!)
                        ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.mac),
                          trailing: FilledButton(
                            onPressed: _busy ? null : () => _pair(device),
                            child: const Text('Pair'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ReconnectScreen extends StatelessWidget {
  const _ReconnectScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_disabled_rounded,
            size: 84,
            color: Color(0xFF7C3AED),
          ),
          SizedBox(height: 24),
          Text(
            'Reconnect remote',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 14),
          Text(
            'Turn on the paired Irusu remote and keep it nearby. Your place will be kept.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    ),
  );
}

class _RemoteTutorial extends StatefulWidget {
  const _RemoteTutorial({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_RemoteTutorial> createState() => _RemoteTutorialState();
}

class _RemoteTutorialState extends State<_RemoteTutorial> {
  final _needed = <RemoteAction>{
    RemoteAction.up,
    RemoteAction.down,
    RemoteAction.left,
    RemoteAction.right,
  };
  late final StreamSubscription<RemoteAction> _subscription;
  int _step = 0;
  @override
  void initState() {
    super.initState();
    _subscription = RemoteInput.actions.listen(_input);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _input(RemoteAction action) {
    if (_step == 0 && _needed.remove(action)) {
      if (_needed.isEmpty)
        setState(() => _step = 1);
      else
        setState(() {});
    } else if (_step == 1 && action == RemoteAction.select)
      setState(() => _step = 2);
    else if (_step == 2 && action == RemoteAction.back) {
      OnboardingState.markRemoteTutorialDone();
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = switch (_step) {
      0 => 'Move the stick up, down, left, and right (${4 - _needed.length}/4)',
      1 => 'Press Select on the focused button',
      _ => 'Press Back to return',
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: Focus(
        autofocus: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gamepad_rounded,
                size: 84,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 24),
              const Text(
                'Let’s learn the remote',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 23)),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () {},
                child: const Text('Focused control'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
