// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get power => 'पावर';

  @override
  String get powerQuestion => 'आप क्या करना चाहेंगे?';

  @override
  String get restart => 'रीस्टार्ट';

  @override
  String get powerOff => 'बंद करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get close => 'बंद करें';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get goodMorning => 'सुप्रभात!';

  @override
  String get goodAfternoon => 'नमस्ते!';

  @override
  String get goodEvening => 'शुभ संध्या!';

  @override
  String get pickAGame => 'एक खेल चुनें और चलना शुरू करें';

  @override
  String get library => 'लाइब्रेरी';

  @override
  String get tapCardToPlay => 'खेलने के लिए कार्ड पर टैप करें';

  @override
  String notInstalled(String gameTitle) {
    return '$gameTitle अभी इंस्टॉल नहीं है';
  }

  @override
  String get contactPhysio => 'मेरे फ़िज़ियो से संपर्क करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get taglineSkyHopper => 'शहर के ऊपर उड़ान भरें — एक छलांग एक बार';

  @override
  String get taglineCatNap => 'अपनी चालों से बिल्ली को जगाए रखें';

  @override
  String get taglineYogaFlow => 'दौड़ें, कूदें और मैदानों में रेस लगाएँ';

  @override
  String get whoIsPlaying => 'आज कौन खेल रहा है?';

  @override
  String get chooseYourName =>
      'अपना नाम चुनें, फिर देखभालकर्ता से मिला कोड डालें';

  @override
  String get selectPatient => 'मरीज़ चुनें';

  @override
  String get otpError => 'कोड मेल नहीं खाया। फिर से कोशिश करें।';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get voiceGuideHint => 'वॉइस गाइड आपसे इसी भाषा में बात करेगा';

  @override
  String goodMorningName(String name) {
    return 'सुप्रभात, $name!';
  }

  @override
  String goodAfternoonName(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String goodEveningName(String name) {
    return 'शुभ संध्या, $name!';
  }

  @override
  String get somethingBeautiful => 'आज कुछ सुंदर आपका इंतज़ार कर रहा है';

  @override
  String get yourWeek => 'आपका सप्ताह';

  @override
  String get todaysRoutine => 'आज की दिनचर्या';

  @override
  String get suggestions => 'सुझाव';

  @override
  String get startToday => 'आज शुरू करें';

  @override
  String get mon => 'सोम';

  @override
  String get tue => 'मंगल';

  @override
  String get wed => 'बुध';

  @override
  String get thu => 'गुरु';

  @override
  String get fri => 'शुक्र';

  @override
  String get sat => 'शनि';

  @override
  String get sun => 'रवि';

  @override
  String get presSkyHopper => '10 मिनट — बाँह उठाना';

  @override
  String get presCatNap => '5 मिनट — संतुलन और पहुँच';

  @override
  String get presYogaFlow => '10 मिनट — जगह पर कदम';

  @override
  String get sugg1 => 'शानदार! लगातार दो दिन।';

  @override
  String get sugg2 => 'आज धीमे और पूरे बाँह उठाने आज़माएँ।';

  @override
  String get sugg3 => 'शुरू करने से पहले पानी पिएँ।';

  @override
  String get physioAssigned => 'डॉ. प्रिया शर्मा — आपकी फ़िज़ियोथेरेपिस्ट';

  @override
  String get consultNow => 'अभी सलाह लें';

  @override
  String get consultNowSub => 'सवाल पूछें या बताएं कि आप कैसा महसूस कर रहे हैं';

  @override
  String get bookAppointment => 'अपॉइंटमेंट बुक करें';

  @override
  String get bookAppointmentSub => 'अपने अनुकूल समय चुनें';

  @override
  String get consultRequested => 'सलाह का अनुरोध भेजा गया';

  @override
  String get appointmentRequested => 'अपॉइंटमेंट का अनुरोध भेजा गया';

  @override
  String physioNotified(String action) {
    return '$action — आपके फ़िज़ियो को सूचित किया जाएगा';
  }

  @override
  String get language => 'भाषा';

  @override
  String get network => 'नेटवर्क';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get connected => 'कनेक्टेड';

  @override
  String get notConnected => 'कनेक्ट नहीं है';

  @override
  String get cableUnplugged => 'केबल नहीं लगी है';

  @override
  String get linkUpNoAddress => 'लिंक चालू, पता नहीं मिला';

  @override
  String get scan => 'स्कैन';

  @override
  String get scanning => 'नेटवर्क खोजे जा रहे हैं…';

  @override
  String get noNetworksFound => 'कोई नेटवर्क नहीं मिला';

  @override
  String get noNetworkHardware => 'कोई नेटवर्क हार्डवेयर नहीं मिला';

  @override
  String get networkServiceUnavailable => 'नेटवर्क सेवा उपलब्ध नहीं है';

  @override
  String get scanFailed => 'स्कैन विफल — नेटवर्क सेवा उपलब्ध नहीं';

  @override
  String get connectionFailed => 'कनेक्शन विफल — नेटवर्क सेवा उपलब्ध नहीं';

  @override
  String get enterPassword => 'पासवर्ड डालें';

  @override
  String passwordFor(String ssid) {
    return '\"$ssid\" का पासवर्ड';
  }

  @override
  String get wifi => 'वाई-फ़ाई';

  @override
  String get ethernet => 'ईथरनेट';
}
