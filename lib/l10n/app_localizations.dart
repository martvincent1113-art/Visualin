import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('fil')];
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isEnglish => locale.languageCode == 'en';
  String _t(String key) => _messages[locale.languageCode]![key]!;

  String get tagline => _t('tagline');
  String get appName => _t('appName');
  String get welcome => _t('welcome');
  String get skip => _t('skip');
  String get next => _t('next');
  String get getStarted => _t('getStarted');
  String get onboardingSignText => _t('onboardingSignText');
  String get onboardingSignTextBody => _t('onboardingSignTextBody');
  String get onboardingTextSign => _t('onboardingTextSign');
  String get onboardingTextSignBody => _t('onboardingTextSignBody');
  String get onboardingSpeech => _t('onboardingSpeech');
  String get onboardingSpeechBody => _t('onboardingSpeechBody');
  String get onboardingCameraTitle => _t('onboardingCameraTitle');
  String get onboardingCameraBody => _t('onboardingCameraBody');
  String get cameraPermissionTitle => _t('cameraPermissionTitle');
  String get cameraPermissionBody => _t('cameraPermissionBody');
  String get homePrompt => _t('homePrompt');
  String get fslToText => _t('fslToText');
  String get fslToTextBody => _t('fslToTextBody');
  String get textToFsl => _t('textToFsl');
  String get textToFslBody => _t('textToFslBody');
  String get noTranslations => _t('noTranslations');
  String get noTranslationsBody => _t('noTranslationsBody');
  String get recentTranslations => _t('recentTranslations');
  String get home => _t('home');
  String get history => _t('history');
  String get flipCamera => _t('flipCamera');
  String get cameraUnavailable => _t('cameraUnavailable');
  String get settings => _t('settings');
  String get outputLanguage => _t('outputLanguage');
  String get outputLanguageBody => _t('outputLanguageBody');
  String get translation => _t('translation');
  String get signLanguage => _t('signLanguage');
  String get signLanguageValue => _t('signLanguageValue');
  String get signLanguageBody => _t('signLanguageBody');
  String get filipino => _t('filipino');
  String get english => _t('english');
  String get accessibility => _t('accessibility');
  String get language => _t('language');
  String get app => _t('app');
  String get settingsSubtitle => _t('settingsSubtitle');
  String get fontSize => _t('fontSize');
  String get textSizeDescription => _t('textSizeDescription');
  String get highContrast => _t('highContrast');
  String get highContrastDescription => _t('highContrastDescription');
  String get reducedMotion => _t('reducedMotion');
  String get reducedMotionDescription => _t('reducedMotionDescription');
  String get cameraPreferences => _t('cameraPreferences');
  String get cameraPreferencesDescription => _t('cameraPreferencesDescription');
  String get helpSupport => _t('helpSupport');
  String get helpSupportDescription => _t('helpSupportDescription');
  String get about => _t('about');
  String get aboutDescription => _t('aboutDescription');
  String get smallText => _t('smallText');
  String get defaultText => _t('defaultText');
  String get largeText => _t('largeText');
  String get settingsFeatureUnavailable => _t('settingsFeatureUnavailable');
  String onboardingProgress(int current, int total) =>
      _t('onboardingProgress')
          .replaceAll('{current}', '$current')
          .replaceAll('{total}', '$total');
  String get historyStub => _t('historyStub');
  String get textToFslStub => _t('textToFslStub');
  String get permissionDenied => _t('permissionDenied');
  String get allowCamera => _t('allowCamera');
  String get later => _t('later');
  String get openSettings => _t('openSettings');
  String get handDetected => _t('handDetected');
  String get noHandDetected => _t('noHandDetected');
  String get cameraGuidanceNoHand => _t('cameraGuidanceNoHand');
  String get cameraGuidanceHandDetected => _t('cameraGuidanceHandDetected');
  String get cameraFrameLabel => _t('cameraFrameLabel');
  String get translatedText => _t('translatedText');
  String get translationWaiting => _t('translationWaiting');
  String get confidenceUnavailable => _t('confidenceUnavailable');
  String get speak => _t('speak');
  String get copy => _t('copy');
  String get save => _t('save');
  String fslToOutputLanguage(String outputLanguage) =>
      _t('fslToOutputLanguage').replaceAll('{language}', outputLanguage);
  String get on => _t('on');
  String get off => _t('off');
  String get close => _t('close');

  static const _messages = <String, Map<String, String>>{
    'fil': {
      'appName': 'Visualin',
      'tagline': 'Makita ang wika. Malayang magsalita.',
      'welcome': 'Maligayang pagdating sa Visualin',
      'skip': 'Laktawan', 'next': 'Susunod', 'getStarted': 'Magsimula',
       'onboardingSignText': 'Isalin ang FSL sa teksto',
       'onboardingSignTextBody': 'Gamitin ang iyong kamera upang gawing mababasang teksto ang Filipino Sign Language.',
       'onboardingTextSign': 'Ihanda ang teksto para sa FSL',
       'onboardingTextSignBody': 'Mag-type ng mensahe at tingnan ang salin nito sa Filipino Sign Language.',
       'onboardingSpeech': 'Pakinggan ang salin gamit ang boses',
       'onboardingSpeechBody': 'Pakinggan ang isinaling teksto nang malakas.',
       'onboardingCameraTitle': 'Kailangan ang access sa kamera',
       'onboardingCameraBody': 'Ginagamit ang access sa kamera upang makilala ang mga senyas sa FSL. Pinoproseso ang video nang live para sa pagsasalin at hindi ito sine-save. Maaari mong baguhin ang pahintulot sa kamera sa Settings anumang oras.',
       'cameraPermissionTitle': 'Kailangan ang access sa kamera',
       'cameraPermissionBody': 'Ginagamit ang access sa kamera upang makilala ang mga senyas sa FSL. Pinoproseso ang video nang live para sa pagsasalin at hindi ito sine-save. Maaari mong baguhin ang pahintulot sa kamera sa Settings anumang oras.',
      'homePrompt': 'Ano ang gusto mong isalin?',
      'fslToText': 'FSL patungong Teksto', 'fslToTextBody': 'Magsenyas gamit ang iyong kamera',
       'textToFsl': 'Teksto patungong FSL', 'textToFslBody': 'Mag-type ng teksto upang makita ang mga senyas', 'noTranslations': 'Wala pang mga salin',
       'noTranslationsBody': 'Makikita rito ang iyong mga kamakailang salin.',
      'recentTranslations': 'Mga kamakailang salin', 'home': 'Tahanan',
      'history': 'Kasaysayan',
      'flipCamera': 'Baligtarin ang kamera', 'cameraUnavailable': 'Hindi available ang kamera',
      'settings': 'Mga setting', 'outputLanguage': 'Wika ng output na teksto',
      'outputLanguageBody': 'Binabago nito ang wika ng output na teksto at boses lamang. FSL pa rin ang sign language.',
      'translation': 'Pagsasalin', 'signLanguage': 'Sign language',
      'signLanguageValue': 'Filipino Sign Language (FSL)',
      'signLanguageBody': 'FSL lamang ang kasalukuyang sinusuportahan.',
       'filipino': 'Filipino', 'english': 'Ingles', 'accessibility': 'Accessibility',
       'language': 'Wika', 'app': 'App', 'settingsSubtitle': 'I-customize ang iyong karanasan',
       'fontSize': 'Laki ng teksto', 'textSizeDescription': 'Ayusin ang laki ng teksto',
       'highContrast': 'Mataas na contrast', 'highContrastDescription': 'Palakihin ang visibility',
       'reducedMotion': 'Bawas na galaw', 'reducedMotionDescription': 'Bawasan ang mga animation',
       'cameraPreferences': 'Mga kagustuhan sa kamera', 'cameraPreferencesDescription': 'Pamahalaan ang iyong kamera',
       'helpSupport': 'Tulong at suporta', 'helpSupportDescription': 'Kumuha ng tulong sa Visualin',
       'about': 'Tungkol sa Visualin', 'aboutDescription': 'Bersyon at impormasyon ng app',
       'smallText': 'Maliit', 'defaultText': 'Default', 'largeText': 'Malaki',
       'settingsFeatureUnavailable': 'Malapit nang maging available ang option na ito.',
       'onboardingProgress': '{current} sa {total}',
      'historyStub': 'Wala pang kasaysayan ng salin.',
      'textToFslStub': 'Malapit na ang feature na teksto patungong FSL.',
      'permissionDenied': 'Hindi pinayagan ang kamera.', 'allowCamera': 'Payagan ang kamera', 'later': 'Mamaya',
      'openSettings': 'Buksan ang settings', 'handDetected': 'May nakitang kamay',
       'noHandDetected': 'Walang nakitang kamay',
       'cameraGuidanceNoHand': 'Ilagay ang iyong mga kamay sa loob ng frame.',
       'cameraGuidanceHandDetected': 'May nakitang kamay. Hawakan nang matatag ang senyas.',
       'cameraFrameLabel': 'Gabay sa posisyon ng kamay',
       'translatedText': 'Isinaling teksto',
       'translationWaiting': 'Makikita rito ang isang na-verify na salin ng FSL.',
       'confidenceUnavailable': 'Hindi pa available ang confidence',
       'speak': 'Basahin', 'copy': 'Kopyahin', 'save': 'I-save',
       'fslToOutputLanguage': 'FSL patungong {language}',
       'on': 'Naka-on', 'off': 'Naka-off', 'close': 'Isara',
    },
    'en': {
      'appName': 'Visualin',
      'tagline': 'See language. Speak freely.', 'welcome': 'Welcome to Visualin',
      'skip': 'Skip', 'next': 'Next', 'getStarted': 'Get started',
       'onboardingSignText': 'Translate FSL into text',
       'onboardingSignTextBody': 'Use your camera to turn Filipino Sign Language into readable text.',
       'onboardingTextSign': 'Prepare text for FSL',
       'onboardingTextSignBody': 'Type a message and view its Filipino Sign Language translation.',
       'onboardingSpeech': 'Listen to translations with speech',
       'onboardingSpeechBody': 'Hear translated text spoken aloud.',
       'onboardingCameraTitle': 'Camera access is required',
       'onboardingCameraBody': 'Camera access is used to recognize FSL signs. Video is processed live for translation and is not saved. You can change camera permission later in Settings.',
       'cameraPermissionTitle': 'Camera access is required',
       'cameraPermissionBody': 'Camera access is used to recognize FSL signs. Video is processed live for translation and is not saved. You can change camera permission later in Settings.',
      'homePrompt': 'What would you like to translate?',
      'fslToText': 'FSL to Text', 'fslToTextBody': 'Sign using your camera',
       'textToFsl': 'Text to FSL', 'textToFslBody': 'Type text to view signs', 'noTranslations': 'No translations yet',
       'noTranslationsBody': 'Your recent translations will appear here.',
      'recentTranslations': 'Recent translations', 'home': 'Home',
      'history': 'History', 'flipCamera': 'Flip camera',
      'cameraUnavailable': 'Camera unavailable', 'settings': 'Settings',
      'outputLanguage': 'Output text language',
      'outputLanguageBody': 'This changes output text and speech only. The sign language remains FSL.',
      'translation': 'Translation', 'signLanguage': 'Sign language',
      'signLanguageValue': 'Filipino Sign Language (FSL)',
      'signLanguageBody': 'Currently, only FSL is supported.',
       'filipino': 'Filipino', 'english': 'English', 'accessibility': 'Accessibility',
       'language': 'Language', 'app': 'App', 'settingsSubtitle': 'Customize your experience',
       'fontSize': 'Text size', 'textSizeDescription': 'Adjust text size',
       'highContrast': 'High contrast', 'highContrastDescription': 'Increase visibility',
       'reducedMotion': 'Reduced motion', 'reducedMotionDescription': 'Minimize animations',
       'cameraPreferences': 'Camera preferences', 'cameraPreferencesDescription': 'Manage your camera',
       'helpSupport': 'Help and support', 'helpSupportDescription': 'Get help with Visualin',
       'about': 'About Visualin', 'aboutDescription': 'App version and information',
       'smallText': 'Small', 'defaultText': 'Default', 'largeText': 'Large',
       'settingsFeatureUnavailable': 'This option will be available soon.',
       'onboardingProgress': '{current} of {total}',
      'historyStub': 'No translation history yet.', 'textToFslStub': 'Text to FSL is coming soon.',
      'permissionDenied': 'Camera permission was not granted.', 'allowCamera': 'Allow camera', 'later': 'Later',
      'openSettings': 'Open settings', 'handDetected': 'Hand detected',
       'noHandDetected': 'No hand detected',
       'cameraGuidanceNoHand': 'Move your hands inside the frame.',
       'cameraGuidanceHandDetected': 'Hand detected. Hold the sign steady.',
       'cameraFrameLabel': 'Hand position guide',
       'translatedText': 'Translated text',
       'translationWaiting': 'A verified FSL translation will appear here.',
       'confidenceUnavailable': 'Confidence unavailable',
       'speak': 'Speak', 'copy': 'Copy', 'save': 'Save',
       'fslToOutputLanguage': 'FSL to {language}',
       'on': 'On', 'off': 'Off', 'close': 'Close',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => ['fil', 'en'].contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(_AppLocalizationsDelegate old) => false;
}
