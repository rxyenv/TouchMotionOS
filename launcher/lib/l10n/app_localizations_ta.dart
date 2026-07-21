// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get power => 'மின்சக்தி';

  @override
  String get powerQuestion => 'என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get restart => 'மறுதொடக்கம்';

  @override
  String get powerOff => 'அணைக்கவும்';

  @override
  String get cancel => 'ரத்து';

  @override
  String get close => 'மூடு';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get goodMorning => 'காலை வணக்கம்!';

  @override
  String get goodAfternoon => 'மதிய வணக்கம்!';

  @override
  String get goodEvening => 'மாலை வணக்கம்!';

  @override
  String get pickAGame =>
      'ஒரு விளையாட்டைத் தேர்ந்தெடுத்து இயங்கத் தொடங்குங்கள்';

  @override
  String get library => 'நூலகம்';

  @override
  String get tapCardToPlay => 'விளையாட அட்டையைத் தட்டவும்';

  @override
  String notInstalled(String gameTitle) {
    return '$gameTitle இன்னும் நிறுவப்படவில்லை';
  }

  @override
  String get contactPhysio => 'என் பிசியோவைத் தொடர்பு கொள்ள';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get taglineSkyHopper =>
      'நகரின் மேல் பறந்து செல்லுங்கள் — ஒவ்வொரு தாவலாக';

  @override
  String get taglineCatNap =>
      'உங்கள் அசைவுகளால் பூனையை விழித்திருக்க வையுங்கள்';

  @override
  String get taglineYogaFlow =>
      'ஓடுங்கள், தாவுங்கள், நிலங்களில் பந்தயம் நடத்துங்கள்';

  @override
  String get whoIsPlaying => 'இன்று யார் விளையாடுகிறார்கள்?';

  @override
  String get chooseYourName =>
      'உங்கள் பெயரைத் தேர்ந்தெடுத்து, பராமரிப்பாளர் தந்த குறியீட்டை உள்ளிடவும்';

  @override
  String get selectPatient => 'நோயாளியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get otpError => 'குறியீடு பொருந்தவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get voiceGuideHint => 'குரல் வழிகாட்டி இந்த மொழியில் உங்களுடன் பேசும்';

  @override
  String goodMorningName(String name) {
    return 'காலை வணக்கம், $name!';
  }

  @override
  String goodAfternoonName(String name) {
    return 'மதிய வணக்கம், $name!';
  }

  @override
  String goodEveningName(String name) {
    return 'மாலை வணக்கம், $name!';
  }

  @override
  String get somethingBeautiful =>
      'இன்று அழகான ஒன்று உங்களுக்காகக் காத்திருக்கிறது';

  @override
  String get yourWeek => 'உங்கள் வாரம்';

  @override
  String get todaysRoutine => 'இன்றைய பயிற்சி';

  @override
  String get suggestions => 'பரிந்துரைகள்';

  @override
  String get startToday => 'இன்று தொடங்கு';

  @override
  String get mon => 'திங்';

  @override
  String get tue => 'செவ்';

  @override
  String get wed => 'புத';

  @override
  String get thu => 'வியா';

  @override
  String get fri => 'வெள்';

  @override
  String get sat => 'சனி';

  @override
  String get sun => 'ஞாயி';

  @override
  String get presSkyHopper => '10 நிமிடம் — கை உயர்த்துதல்';

  @override
  String get presCatNap => '5 நிமிடம் — சமநிலை மற்றும் எட்டுதல்';

  @override
  String get presYogaFlow => '10 நிமிடம் — நின்ற இடத்தில் நடத்தல்';

  @override
  String get sugg1 => 'அருமை! தொடர்ந்து இரண்டு நாட்கள்.';

  @override
  String get sugg2 => 'இன்று மெதுவாக, முழுமையாக கை உயர்த்தி முயற்சிக்கவும்.';

  @override
  String get sugg3 => 'தொடங்கும் முன் தண்ணீர் குடிக்கவும்.';

  @override
  String get physioAssigned => 'டாக்டர் பிரியா சர்மா — உங்கள் பிசியோதெரபிஸ்ட்';

  @override
  String get consultNow => 'இப்போது ஆலோசிக்க';

  @override
  String get consultNowSub =>
      'கேள்வி கேளுங்கள் அல்லது உங்கள் நிலையைத் தெரிவியுங்கள்';

  @override
  String get bookAppointment => 'சந்திப்பு பதிவு';

  @override
  String get bookAppointmentSub =>
      'உங்களுக்கு ஏற்ற நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get consultRequested => 'ஆலோசனை கோரப்பட்டது';

  @override
  String get appointmentRequested => 'சந்திப்பு கோரப்பட்டது';

  @override
  String physioNotified(String action) {
    return '$action — உங்கள் பிசியோவுக்குத் தெரிவிக்கப்படும்';
  }

  @override
  String get language => 'மொழி';

  @override
  String get network => 'நெட்வொர்க்';

  @override
  String get online => 'ஆன்லைன்';

  @override
  String get offline => 'ஆஃப்லைன்';

  @override
  String get connected => 'இணைக்கப்பட்டது';

  @override
  String get notConnected => 'இணைக்கப்படவில்லை';

  @override
  String get cableUnplugged => 'கேபிள் இணைக்கப்படவில்லை';

  @override
  String get linkUpNoAddress => 'இணைப்பு உள்ளது, முகவரி இல்லை';

  @override
  String get scan => 'தேடு';

  @override
  String get scanning => 'நெட்வொர்க்குகள் தேடப்படுகின்றன…';

  @override
  String get noNetworksFound => 'நெட்வொர்க்குகள் எதுவும் கிடைக்கவில்லை';

  @override
  String get noNetworkHardware => 'நெட்வொர்க் வன்பொருள் எதுவும் இல்லை';

  @override
  String get networkServiceUnavailable => 'நெட்வொர்க் சேவை கிடைக்கவில்லை';

  @override
  String get scanFailed => 'தேடல் தோல்வி — நெட்வொர்க் சேவை கிடைக்கவில்லை';

  @override
  String get connectionFailed =>
      'இணைப்பு தோல்வி — நெட்வொர்க் சேவை கிடைக்கவில்லை';

  @override
  String get enterPassword => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String passwordFor(String ssid) {
    return '\"$ssid\" கடவுச்சொல்';
  }

  @override
  String get wifi => 'வை-ஃபை';

  @override
  String get ethernet => 'ஈதர்நெட்';

  @override
  String get timeFormat => 'நேர வடிவம்';

  @override
  String get hour12 => '12-மணி';

  @override
  String get hour24 => '24-மணி';

  @override
  String get changeTimeZone => 'மாற்று';

  @override
  String get selectTimeZone => 'நேர மண்டலம் தேர்வு செய்க';

  @override
  String get searchTimeZones => 'நேர மண்டலங்கள் தேடுக…';
}
