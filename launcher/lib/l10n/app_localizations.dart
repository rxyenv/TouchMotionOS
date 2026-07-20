import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @powerQuestion.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get powerQuestion;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @powerOff.
  ///
  /// In en, this message translates to:
  /// **'Power off'**
  String get powerOff;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// No description provided for @pickAGame.
  ///
  /// In en, this message translates to:
  /// **'Pick a game and get moving'**
  String get pickAGame;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @tapCardToPlay.
  ///
  /// In en, this message translates to:
  /// **'Tap a card to play'**
  String get tapCardToPlay;

  /// No description provided for @notInstalled.
  ///
  /// In en, this message translates to:
  /// **'{gameTitle} is not installed yet'**
  String notInstalled(String gameTitle);

  /// No description provided for @contactPhysio.
  ///
  /// In en, this message translates to:
  /// **'Contact my physio'**
  String get contactPhysio;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @taglineSkyHopper.
  ///
  /// In en, this message translates to:
  /// **'Flap through the city — one hop at a time'**
  String get taglineSkyHopper;

  /// No description provided for @taglineCatNap.
  ///
  /// In en, this message translates to:
  /// **'Keep the cat awake with your best moves'**
  String get taglineCatNap;

  /// No description provided for @taglineYogaFlow.
  ///
  /// In en, this message translates to:
  /// **'Dash, jump, and race across the lands'**
  String get taglineYogaFlow;

  /// No description provided for @whoIsPlaying.
  ///
  /// In en, this message translates to:
  /// **'Who is playing today?'**
  String get whoIsPlaying;

  /// No description provided for @chooseYourName.
  ///
  /// In en, this message translates to:
  /// **'Choose your name, then enter the code from your caregiver'**
  String get chooseYourName;

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Select patient'**
  String get selectPatient;

  /// No description provided for @otpError.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t match. Try again.'**
  String get otpError;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @voiceGuideHint.
  ///
  /// In en, this message translates to:
  /// **'The voice guide will speak to you in this language'**
  String get voiceGuideHint;

  /// No description provided for @goodMorningName.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String goodMorningName(String name);

  /// No description provided for @goodAfternoonName.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}!'**
  String goodAfternoonName(String name);

  /// No description provided for @goodEveningName.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}!'**
  String goodEveningName(String name);

  /// No description provided for @somethingBeautiful.
  ///
  /// In en, this message translates to:
  /// **'Something beautiful is waiting for you today'**
  String get somethingBeautiful;

  /// No description provided for @yourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get yourWeek;

  /// No description provided for @todaysRoutine.
  ///
  /// In en, this message translates to:
  /// **'Today\'s routine'**
  String get todaysRoutine;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @startToday.
  ///
  /// In en, this message translates to:
  /// **'Start Today'**
  String get startToday;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @presSkyHopper.
  ///
  /// In en, this message translates to:
  /// **'10 minutes — arm raises'**
  String get presSkyHopper;

  /// No description provided for @presCatNap.
  ///
  /// In en, this message translates to:
  /// **'5 minutes — balance and reach'**
  String get presCatNap;

  /// No description provided for @presYogaFlow.
  ///
  /// In en, this message translates to:
  /// **'10 minutes — step in place'**
  String get presYogaFlow;

  /// No description provided for @sugg1.
  ///
  /// In en, this message translates to:
  /// **'Great streak! Two days in a row.'**
  String get sugg1;

  /// No description provided for @sugg2.
  ///
  /// In en, this message translates to:
  /// **'Try slower, fuller arm raises today.'**
  String get sugg2;

  /// No description provided for @sugg3.
  ///
  /// In en, this message translates to:
  /// **'Drink water before you start.'**
  String get sugg3;

  /// No description provided for @physioAssigned.
  ///
  /// In en, this message translates to:
  /// **'Dr. Priya Sharma — your assigned physiotherapist'**
  String get physioAssigned;

  /// No description provided for @consultNow.
  ///
  /// In en, this message translates to:
  /// **'Consult now'**
  String get consultNow;

  /// No description provided for @consultNowSub.
  ///
  /// In en, this message translates to:
  /// **'Ask a question or report how you feel'**
  String get consultNowSub;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get bookAppointment;

  /// No description provided for @bookAppointmentSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a time that suits you'**
  String get bookAppointmentSub;

  /// No description provided for @consultRequested.
  ///
  /// In en, this message translates to:
  /// **'Consult requested'**
  String get consultRequested;

  /// No description provided for @appointmentRequested.
  ///
  /// In en, this message translates to:
  /// **'Appointment requested'**
  String get appointmentRequested;

  /// No description provided for @physioNotified.
  ///
  /// In en, this message translates to:
  /// **'{action} — your physio will be notified'**
  String physioNotified(String action);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @cableUnplugged.
  ///
  /// In en, this message translates to:
  /// **'Cable unplugged'**
  String get cableUnplugged;

  /// No description provided for @linkUpNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Link up, no address'**
  String get linkUpNoAddress;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for networks…'**
  String get scanning;

  /// No description provided for @noNetworksFound.
  ///
  /// In en, this message translates to:
  /// **'No networks found'**
  String get noNetworksFound;

  /// No description provided for @noNetworkHardware.
  ///
  /// In en, this message translates to:
  /// **'No network hardware detected'**
  String get noNetworkHardware;

  /// No description provided for @networkServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network service unavailable'**
  String get networkServiceUnavailable;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed — network service unavailable'**
  String get scanFailed;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed — network service unavailable'**
  String get connectionFailed;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @passwordFor.
  ///
  /// In en, this message translates to:
  /// **'Password for \"{ssid}\"'**
  String passwordFor(String ssid);

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @ethernet.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get ethernet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'ml',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
