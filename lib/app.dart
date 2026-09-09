import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/camera_translation_screen.dart';
import 'screens/camera_permission_gate.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_preferences.dart';
import 'services/landmark_service.dart';
import 'theme/visualin_tokens.dart';

class VisualinApp extends StatefulWidget {
  const VisualinApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<VisualinApp> createState() => _VisualinAppState();
}

class _VisualinAppState extends State<VisualinApp> {
  late Locale _locale;
  late bool _highContrast;
  late bool _reducedMotion;
  late double _textScale;

  @override
  void initState() {
    super.initState();
    _locale = widget.preferences.locale;
    _highContrast = widget.preferences.highContrast;
    _reducedMotion = widget.preferences.reducedMotion;
    _textScale = widget.preferences.textScale;
  }

  Future<void> _setLocale(Locale locale) async {
    await widget.preferences.setLocale(locale);
    if (mounted) setState(() => _locale = locale);
  }

  Future<void> _setHighContrast(bool value) async {
    await widget.preferences.setHighContrast(value);
    if (mounted) setState(() => _highContrast = value);
  }

  Future<void> _setReducedMotion(bool value) async {
    await widget.preferences.setReducedMotion(value);
    if (mounted) setState(() => _reducedMotion = value);
  }

  Future<void> _setTextScale(double value) async {
    await widget.preferences.setTextScale(value);
    if (mounted) setState(() => _textScale = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visualin',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: VisualinTheme.light(highContrast: _highContrast, reducedMotion: _reducedMotion),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: _reducedMotion || mediaQuery.disableAnimations,
            textScaler: _PreferenceTextScaler(mediaQuery.textScaler, _textScale),
          ),
          child: child!,
        );
      },
      home: SplashScreen(preferences: widget.preferences),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute<void>(
              builder: (_) => OnboardingScreen(preferences: widget.preferences),
            );
          case '/home':
            return MaterialPageRoute<void>(
              builder: (_) => HomeScreen(preferences: widget.preferences),
            );
          case '/camera':
            return MaterialPageRoute<void>(
              builder: (_) => CameraPermissionGate(
                cameraScreenBuilder: (_) => CameraTranslationScreen(
                  landmarkService: LandmarkService(),
                ),
              ),
            );
          case '/profile':
            return MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(
                preferences: widget.preferences,
                onLocaleChanged: _setLocale,
                onHighContrastChanged: _setHighContrast,
                onReducedMotionChanged: _setReducedMotion,
                textScale: _textScale,
                onTextScaleChanged: _setTextScale,
              ),
            );
          case '/text-to-fsl':
            return MaterialPageRoute<void>(
              builder: (_) => const ComingSoonScreen(
                feature: ComingSoonFeature.textToFsl,
              ),
            );
          case '/history':
            return MaterialPageRoute<void>(
              builder: (_) => const ComingSoonScreen(
                feature: ComingSoonFeature.history,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class VisualinTheme {
  static ThemeData light({
    required bool highContrast,
    required bool reducedMotion,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      // Flutter resolves this to SF Pro on iOS. Other platforms retain their
      // own system typeface instead of using a look-alike font.
      fontFamily:
          defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : null,
    );
    final ink = highContrast ? Colors.black : VisualinColors.primaryText;
    final textTheme = baseTheme.textTheme.copyWith(
      displaySmall: baseTheme.textTheme.displaySmall!.copyWith(
        fontSize: 34,
        height: 1.16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall!.copyWith(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: baseTheme.textTheme.titleLarge!.copyWith(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: baseTheme.textTheme.titleMedium!.copyWith(
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge!.copyWith(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium!.copyWith(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: highContrast ? Colors.black : VisualinColors.secondaryText,
      ),
      labelLarge: baseTheme.textTheme.labelLarge!.copyWith(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily:
          defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : null,
      scaffoldBackgroundColor:
          highContrast ? Colors.white : VisualinColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VisualinColors.primaryOrange,
        primary: VisualinColors.primaryOrange,
        surface: VisualinColors.surface,
        onSurface: ink,
        outline: highContrast ? Colors.black : VisualinColors.divider,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleMedium,
      ),
      dividerColor: highContrast ? Colors.black : VisualinColors.divider,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: VisualinColors.surface,
        border: OutlineInputBorder(
          borderRadius: VisualinRadii.control,
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VisualinColors.primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: VisualinRadii.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VisualinColors.primaryOrange,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(
            color: highContrast ? Colors.black : VisualinColors.primaryOrange,
          ),
          shape: const RoundedRectangleBorder(borderRadius: VisualinRadii.control),
        ),
      ),
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: _NoTransitionsBuilder(),
              TargetPlatform.iOS: _NoTransitionsBuilder(),
              TargetPlatform.linux: _NoTransitionsBuilder(),
              TargetPlatform.macOS: _NoTransitionsBuilder(),
              TargetPlatform.windows: _NoTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _PreferenceTextScaler extends TextScaler {
  const _PreferenceTextScaler(this.systemScaler, this.preferenceScale);

  final TextScaler systemScaler;
  final double preferenceScale;

  @override
  double scale(double fontSize) => systemScaler.scale(fontSize) * preferenceScale;

  // TextScaler exposes this legacy estimate for framework compatibility. The
  // actual scale calculation above intentionally retains the platform's
  // non-linear accessibility behavior.
  @override
  @Deprecated('Use scale instead.')
  double get textScaleFactor => systemScaler.scale(1) * preferenceScale;

  @override
  bool operator ==(Object other) =>
      other is _PreferenceTextScaler &&
      other.systemScaler == systemScaler &&
      other.preferenceScale == preferenceScale;

  @override
  int get hashCode => Object.hash(systemScaler, preferenceScale);
}
