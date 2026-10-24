import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_preferences.dart';
import '../services/camera_permission_service.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.preferences});
  final AppPreferences preferences;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _cameraPermissionService = CameraPermissionService();
  int _page = 0;

  Future<void> _finish({bool requestCamera = false}) async {
    final l10n = AppLocalizations.of(context);
    if (requestCamera) {
      final granted = await _cameraPermissionService.requestAccess();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.permissionDenied)));
      }
    }
    await widget.preferences.setHasOnboarded(true);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = reducedMotion
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 250);
    final transitionCurve = reducedMotion ? Curves.linear : Curves.easeOutCubic;
    final slides = [
      (
        Icons.sign_language_outlined,
        l10n.onboardingSignText,
        l10n.onboardingSignTextBody
      ),
      (
        Icons.subtitles_outlined,
        l10n.onboardingTextSign,
        l10n.onboardingTextSignBody
      ),
      (
        Icons.volume_up_outlined,
        l10n.onboardingSpeech,
        l10n.onboardingSpeechBody
      ),
      (
        Icons.camera_alt_outlined,
        l10n.onboardingCameraTitle,
        l10n.onboardingCameraBody
      ),
    ];
    return AppScreen(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => _finish(),
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
                    child: Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VisualinIconTile(
                                icon: slide.$1,
                                size: 88,
                                iconSize: 44,
                              ),
                              const SizedBox(height: 26),
                              Semantics(
                                header: true,
                                child: Text(
                                  slide.$2,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slide.$3,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: VisualinColors.secondaryText,
                                    ),
                              ),
                              if (index == slides.length - 1) ...[
                                const SizedBox(height: 10),
                                Text(
                                  l10n.cameraPrivacyBody,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.cameraPermissionSettingsBody,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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
                          ? Theme.of(context).colorScheme.primary
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
                      ? () => _finish(requestCamera: true)
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
