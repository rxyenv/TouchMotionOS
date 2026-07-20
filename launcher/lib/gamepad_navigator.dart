import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

/// Translates gamepad input into Flutter focus traversal so the whole
/// launcher is navigable with an Xbox-style controller:
///
///   dpad / left stick  -> move focus (arrow-key equivalent)
///   A (south)          -> activate focused widget
///   B (east)           -> pop current route
///
/// Axes are edge-triggered: one focus move per push past the threshold,
/// re-armed when the stick returns to the deadzone, so holding the stick
/// doesn't machine-gun through the UI.
class GamepadNavigator {
  GamepadNavigator._(this._navigatorKey);

  static GamepadNavigator? _instance;
  StreamSubscription<GamepadEvent>? _sub;
  final GlobalKey<NavigatorState> _navigatorKey;

  /// Axis id -> last emitted direction (-1, 0, 1), for edge triggering.
  final _axisState = <String, int>{};

  static const _threshold = 0.5;

  /// Linux (joydev) ids for Xbox pads: left stick 0/1, dpad hat 6/7.
  static const _horizontalAxes = {'axis-0', 'axis-6', 'dwXpos', 'pov'};
  static const _verticalAxes = {'axis-1', 'axis-7', 'dwYpos'};

  /// A / B across backends (joydev numbers buttons; other platforms name
  /// them). Keep both spellings — unknown keys are simply ignored.
  static const _activateButtons = {'button-0', 'a.circle', 'button.south'};
  static const _backButtons = {'button-1', 'b.circle', 'button.east'};

  static void start(GlobalKey<NavigatorState> navigatorKey) {
    _instance ??= GamepadNavigator._(navigatorKey);
    _instance!._listen();
  }

  void _listen() {
    // Paint focus rings even though the device is touch-first.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    _sub ??= Gamepads.events.listen(
      _onEvent,
      onError: (Object _) {
        // No gamepad support / device disappeared: navigation by touch
        // still works, so swallow and keep the launcher alive.
      },
    );
  }

  void _onEvent(GamepadEvent event) {
    if (event.type == KeyType.button) {
      if (event.value < _threshold) return; // Ignore releases.
      if (_activateButtons.contains(event.key)) {
        _activate();
      } else if (_backButtons.contains(event.key)) {
        _back();
      }
      return;
    }

    // Analog: normalize joydev's 16-bit range to [-1, 1] if needed.
    var value = event.value;
    if (value.abs() > 1.5) value /= 32767.0;

    final direction = value <= -_threshold
        ? -1
        : value >= _threshold
        ? 1
        : 0;
    if (_axisState[event.key] == direction) return;
    _axisState[event.key] = direction;
    if (direction == 0) return;

    if (_horizontalAxes.contains(event.key)) {
      _moveFocus(
        direction < 0 ? TraversalDirection.left : TraversalDirection.right,
      );
    } else if (_verticalAxes.contains(event.key)) {
      _moveFocus(
        direction < 0 ? TraversalDirection.up : TraversalDirection.down,
      );
    }
  }

  void _moveFocus(TraversalDirection direction) {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context ?? _navigatorKey.currentContext;
    if (context == null) return;
    // Nothing focused yet: land on the first focusable instead of moving.
    if (focus == null || focus == FocusManager.instance.rootScope) {
      FocusScope.of(context).nextFocus();
      return;
    }
    focus.focusInDirection(direction);
  }

  void _activate() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (context == null) return;
    Actions.maybeInvoke(context, const ActivateIntent());
  }

  void _back() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) navigator.pop();
  }
}
