import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:visualin/app.dart';
import 'package:visualin/l10n/app_localizations.dart';
import 'package:visualin/services/app_preferences.dart';
import 'package:visualin/services/camera_permission_service.dart';
import 'package:visualin/screens/camera_permission_gate.dart';
import 'package:visualin/screens/camera_translation_screen.dart';
import 'package:visualin/services/landmark_service.dart';

void main() {
  test('default output locale and FSL-to-Text copy are English', () async {
    final preferences = AppPreferences.inMemory();
    final l10n = AppLocalizations(preferences.locale);

    expect(preferences.locale, const Locale('en'));
    expect(l10n.fslToText, 'FSL to Text');
    expect(
      l10n.cameraPermissionBody,
      'Visualin needs camera access to recognize FSL signs.',
    );
  });

  test('output language selection never changes the FSL sign language', () {
    const english = AppLocalizations(Locale('en'));
    const filipino = AppLocalizations(Locale('fil'));

    expect(english.fslToOutputLanguage(english.english), 'FSL → English');
    expect(filipino.signLanguageValue, 'Filipino Sign Language (FSL)');
    expect(filipino.outputLanguageBody, contains('FSL'));
  });

  testWidgets('app launches with English copy by default', (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pump();
    expect(find.text('See language. Speak freely.'), findsOneWidget);
  });

  testWidgets('a fresh install advances from Splash to Onboarding',
      (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Translate FSL into text'), findsOneWidget);
  });

  testWidgets('a returning user advances from Splash to Home', (tester) async {
    final preferences = AppPreferences.inMemory();
    await preferences.setHasOnboarded(true);
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('What would you like to translate?'), findsOneWidget);
    expect(find.text('FSL to Text'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Sign using your camera'), findsOneWidget);
    expect(find.text('Type text to view signs'), findsOneWidget);
  });

  testWidgets('language toggle switches profile copy to Filipino',
      (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filipino'));
    await tester.pumpAndSettle();
    expect(find.text('Wika ng output na teksto'), findsOneWidget);
    expect(
      AppLocalizations(preferences.locale).fslToText,
      'FSL patungong Teksto',
    );
  });

  testWidgets(
      'FSL to Text checks permission before constructing the camera screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: CameraPermissionGate(
          permissionService: _DeniedCameraPermissionService(),
          cameraScreenBuilder: (_) => const Text('Camera screen'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allow camera'), findsOneWidget);
    expect(
      find.text(
        'Visualin needs camera access to recognize FSL signs.',
      ),
      findsOneWidget,
    );
    expect(find.text('Camera screen'), findsNothing);
  });

  test('onboarding and language preferences persist to local storage',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await AppPreferences.create();

    await preferences.setHasOnboarded(true);
    await preferences.setLocale(const Locale('fil'));
    await preferences.setHighContrast(true);
    await preferences.setReducedMotion(true);
    await preferences.setTextScale(1.2);

    final reloaded = await AppPreferences.create();
    expect(reloaded.hasOnboarded, isTrue);
    expect(reloaded.locale, const Locale('fil'));
    expect(reloaded.highContrast, isTrue);
    expect(reloaded.reducedMotion, isTrue);
    expect(reloaded.textScale, 1.2);
  });

  testWidgets('History uses the shared two-line empty state', (tester) async {
    final preferences = AppPreferences.inMemory();
    await preferences.setHasOnboarded(true);
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('No translations yet'), findsOneWidget);
    expect(
      find.text('Your saved translations will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Camera'), findsOneWidget);
  });

  testWidgets('Text to FSL never fabricates unverified sign content',
      (tester) async {
    final preferences = AppPreferences.inMemory();
    await preferences.setHasOnboarded(true);
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('Text to FSL'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Good morning');
    await tester.pump();
    await tester.tap(find.text('View signs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text(
        'Verified FSL content is not available for this message yet.',
      ),
      findsOneWidget,
    );
  });

  test('navigation label is Camera while the feature title stays FSL to Text',
      () {
    const l10n = AppLocalizations(Locale('en'));
    expect(l10n.cameraTab, 'Camera');
    expect(l10n.fslToText, 'FSL to Text');
  });

  testWidgets('Camera result does not show confidence before a translation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: CameraTranslationScreen(
          landmarkService: _IdleLandmarkDetector(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('FSL to Text'), findsOneWidget);
    expect(find.text('Confidence unavailable'), findsNothing);
    expect(find.text('A verified FSL translation will appear here.'),
        findsOneWidget);
    expect(find.text('Speak'), findsNothing);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('large text remains usable on a compact phone', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final preferences = AppPreferences.inMemory();
    await preferences.setHasOnboarded(true);
    await preferences.setTextScale(1.35);
    await tester.pumpWidget(VisualinApp(preferences: preferences));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Customize your experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DeniedCameraPermissionService extends CameraPermissionService {
  @override
  Future<PermissionStatus> get status async => PermissionStatus.denied;
}

class _IdleLandmarkDetector implements LandmarkDetector {
  @override
  Stream<LandmarkFrame> get frames => const Stream<LandmarkFrame>.empty();

  @override
  Future<void> start(
    CameraController controller, {
    bool Function()? isActive,
  }) async {}

  @override
  Future<void> stop() async {}
}
