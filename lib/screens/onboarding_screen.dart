import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_preferences.dart';
import '../services/camera_permission_service.dart';
import '../theme/visualin_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.preferences});
  final AppPreferences preferences;
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _cameraPermissionService = CameraPermissionService();
  int _page = 0;

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    if (_page == 3) {
      final granted = await _cameraPermissionService.requestAccess();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.permissionDenied)));
      }
    }
    await widget.preferences.setHasOnboarded(true);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final transitionDuration =
        reducedMotion ? const Duration(milliseconds: 1) : const Duration(milliseconds: 250);
    final transitionCurve = reducedMotion ? Curves.linear : Curves.easeOutCubic;
    final slides = [
      (Icons.sign_language_outlined, l10n.onboardingSignText, l10n.onboardingSignTextBody),
      (Icons.subtitles_outlined, l10n.onboardingTextSign, l10n.onboardingTextSignBody),
      (Icons.volume_up_outlined, l10n.onboardingSpeech, l10n.onboardingSpeechBody),
      (Icons.camera_alt_outlined, l10n.onboardingCameraTitle, l10n.onboardingCameraBody),
    ];
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(l10n.skip),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: VisualinColors.orangeTint,
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                          ),
                          child: Icon(
                            slide.$1,
                            size: 48,
                            color: VisualinColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          slide.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: VisualinColors.secondaryText,
                              ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            Semantics(
              label: l10n.onboardingProgress(_page + 1, slides.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: transitionDuration,
                    curve: transitionCurve,
                    margin: const EdgeInsets.all(4),
                    height: 8,
                    width: index == _page ? 24 : 8,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? VisualinColors.primaryOrange
                          : VisualinColors.inactive,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == slides.length - 1
                      ? _finish
                      : () => _pageController.nextPage(
                            duration: transitionDuration,
                            curve: transitionCurve,
                          ),
                  child: Text(
                    _page == slides.length - 1 ? l10n.getStarted : l10n.next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
