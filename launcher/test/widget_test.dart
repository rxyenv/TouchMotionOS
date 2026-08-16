import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:tomoro_launcher/l10n/app_localizations.dart';
import 'package:tomoro_launcher/screens/home_screen.dart';

void main() {
  testWidgets('home screen shows the empty library state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Library'), findsOneWidget);
    expect(
      find.text('No games installed yet.\nBrowse the Store to download.'),
      findsOneWidget,
    );
  });
}
