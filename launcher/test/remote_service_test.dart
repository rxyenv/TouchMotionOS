import 'package:flutter_test/flutter_test.dart';
import 'package:tomoro_launcher/remote_service.dart';

void main() {
  test('remote status distinguishes a trusted disconnected remote', () {
    final status = RemoteStatus.fromJson({
      'paired': true,
      'connected': false,
    });

    expect(status.paired, isTrue);
    expect(status.connected, isFalse);
  });

}
