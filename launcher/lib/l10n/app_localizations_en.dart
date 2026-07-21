// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get power => 'Power';

  @override
  String get powerQuestion => 'What would you like to do?';

  @override
  String get restart => 'Restart';

  @override
  String get powerOff => 'Power off';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get continueLabel => 'Continue';

  @override
  String get goodMorning => 'Good morning!';

  @override
  String get goodAfternoon => 'Good afternoon!';

  @override
  String get goodEvening => 'Good evening!';

  @override
  String get pickAGame => 'Pick a game and get moving';

  @override
  String get library => 'Library';

  @override
  String get tapCardToPlay => 'Tap a card to play';

  @override
  String notInstalled(String gameTitle) {
    return '$gameTitle is not installed yet';
  }

  @override
  String get contactPhysio => 'Contact my physio';

  @override
  String get settings => 'Settings';

  @override
  String get taglineSkyHopper => 'Flap through the city — one hop at a time';

  @override
  String get taglineCatNap => 'Keep the cat awake with your best moves';

  @override
  String get taglineYogaFlow => 'Flow through poses — move at your own pace';

  @override
  String get whoIsPlaying => 'Who is playing today?';

  @override
  String get chooseYourName =>
      'Choose your name, then enter the code from your caregiver';

  @override
  String get selectPatient => 'Select patient';

  @override
  String get otpError => 'That code didn\'t match. Try again.';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get voiceGuideHint =>
      'The voice guide will speak to you in this language';

  @override
  String goodMorningName(String name) {
    return 'Good morning, $name!';
  }

  @override
  String goodAfternoonName(String name) {
    return 'Good afternoon, $name!';
  }

  @override
  String goodEveningName(String name) {
    return 'Good evening, $name!';
  }

  @override
  String get somethingBeautiful =>
      'Something beautiful is waiting for you today';

  @override
  String get yourWeek => 'Your week';

  @override
  String get todaysRoutine => 'Today\'s routine';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get startToday => 'Start Today';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get presSkyHopper => '10 minutes — arm raises';

  @override
  String get presCatNap => '5 minutes — balance and reach';

  @override
  String get presYogaFlow => '10 minutes — yoga flow poses';

  @override
  String get sugg1 => 'Great streak! Two days in a row.';

  @override
  String get sugg2 => 'Try slower, fuller arm raises today.';

  @override
  String get sugg3 => 'Drink water before you start.';

  @override
  String get physioAssigned =>
      'Dr. Priya Sharma — your assigned physiotherapist';

  @override
  String get consultNow => 'Consult now';

  @override
  String get consultNowSub => 'Ask a question or report how you feel';

  @override
  String get bookAppointment => 'Book appointment';

  @override
  String get bookAppointmentSub => 'Pick a time that suits you';

  @override
  String get consultRequested => 'Consult requested';

  @override
  String get appointmentRequested => 'Appointment requested';

  @override
  String physioNotified(String action) {
    return '$action — your physio will be notified';
  }

  @override
  String get language => 'Language';

  @override
  String get network => 'Network';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get cableUnplugged => 'Cable unplugged';

  @override
  String get linkUpNoAddress => 'Link up, no address';

  @override
  String get scan => 'Scan';

  @override
  String get scanning => 'Scanning for networks…';

  @override
  String get noNetworksFound => 'No networks found';

  @override
  String get noNetworkHardware => 'No network hardware detected';

  @override
  String get networkServiceUnavailable => 'Network service unavailable';

  @override
  String get scanFailed => 'Scan failed — network service unavailable';

  @override
  String get connectionFailed =>
      'Connection failed — network service unavailable';

  @override
  String get enterPassword => 'Enter password';

  @override
  String passwordFor(String ssid) {
    return 'Password for \"$ssid\"';
  }

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get ethernet => 'Ethernet';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get hour12 => '12-hour';

  @override
  String get hour24 => '24-hour';

  @override
  String get changeTimeZone => 'Change';

  @override
  String get selectTimeZone => 'Select time zone';

  @override
  String get searchTimeZones => 'Search time zones…';
}
