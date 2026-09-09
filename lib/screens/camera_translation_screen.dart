import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/landmark_service.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/camera_overlay_transform.dart';
import '../widgets/hand_landmark_connections.dart';

class CameraTranslationScreen extends StatefulWidget {
  const CameraTranslationScreen({super.key, required this.landmarkService});

  final LandmarkDetector landmarkService;

  @override
  State<CameraTranslationScreen> createState() =>
      _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends State<CameraTranslationScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  final ValueNotifier<List<List<LandmarkPoint>>> _hands =
      ValueNotifier<List<List<LandmarkPoint>>>(const []);
  StreamSubscription<LandmarkFrame>? _landmarkSubscription;
  bool _initializing = true;
  bool _isTearingDown = false;
  bool _isSwitchingCamera = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted || _isTearingDown) return;
      if (cameras.isEmpty) throw StateError('camera');
      _cameras = cameras;
      // The one-in-flight detector guard provides backpressure, so retain a
      // high-quality preview instead of lowering camera resolution for lag.
      controller = CameraController(
        _preferredCamera(cameras),
        ResolutionPreset.high,
        enableAudio: false,
      );
      // Retain the controller before awaiting initialization so dispose can
      // tear it down if the user leaves this screen mid-initialization.
      _controller = controller;
      _landmarkSubscription =
          widget.landmarkService.frames.listen(_onLandmarkFrame);
      await controller.initialize();
      if (!mounted || _isTearingDown) return;
      await widget.landmarkService.start(
        controller,
        isActive: () => mounted && !_isTearingDown,
      );
      if (mounted && !_isTearingDown) setState(() => _initializing = false);
    } catch (_) {
      await _landmarkSubscription?.cancel();
      _landmarkSubscription = null;
      await widget.landmarkService.stop();
      if (!_isTearingDown && identical(_controller, controller)) {
        _controller = null;
        await controller?.dispose();
      }
      if (mounted && !_isTearingDown) setState(() => _initializing = false);
    }
  }

  void _onLandmarkFrame(LandmarkFrame frame) {
    // A queued stream event can arrive after cancel() has been requested.
    if (!mounted || _isTearingDown) return;
    _hands.value = frame.hands;
  }

  CameraDescription _preferredCamera(List<CameraDescription> cameras) {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  Future<void> _switchCamera() async {
    final previous = _controller;
    if (previous == null ||
        _cameras.length < 2 ||
        _isSwitchingCamera ||
        _isTearingDown) {
      return;
    }

    final currentIndex = _cameras.indexWhere(
      (camera) => camera == previous.description,
    );
    if (currentIndex < 0) return;
    final nextCamera = _cameras[(currentIndex + 1) % _cameras.length];
    _isSwitchingCamera = true;

    try {
      await widget.landmarkService.stop();
      if (_isTearingDown) return;
      _controller = null;
      await previous.dispose();
      if (!mounted || _isTearingDown) return;

      final replacement = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = replacement;
      await replacement.initialize();
      if (!mounted || _isTearingDown) return;
      await widget.landmarkService.start(
        replacement,
        isActive: () => mounted && !_isTearingDown,
      );
      if (mounted && !_isTearingDown) setState(() {});
    } catch (_) {
      if (mounted && !_isTearingDown) setState(() {});
    } finally {
      _isSwitchingCamera = false;
    }
  }

  @override
  void dispose() {
    _isTearingDown = true;
    final subscription = _landmarkSubscription;
    _landmarkSubscription = null;
    final controller = _controller;
    _controller = null;
    unawaited(_tearDownCamera(subscription, controller));
    _hands.dispose();
    super.dispose();
  }

  Future<void> _tearDownCamera(
    StreamSubscription<LandmarkFrame>? subscription,
    CameraController? controller,
  ) async {
    await subscription?.cancel();
    if (controller?.value.isStreamingImages == true) {
      await controller!.stopImageStream();
    }
    await widget.landmarkService.stop();
    await controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.close,
                    ),
                    Expanded(
                      child: Text(
                        l10n.fslToText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _cameras.length > 1 && !_isSwitchingCamera
                          ? _switchCamera
                          : null,
                      icon: const Icon(Icons.flip_camera_ios_outlined),
                      tooltip: l10n.flipCamera,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _CameraPreviewPanel(
                  controller: _controller,
                  hands: _hands,
                  initializing: _initializing,
                  cameraUnavailable: l10n.cameraUnavailable,
                  frameLabel: l10n.cameraFrameLabel,
                ),
              ),
              const SizedBox(height: 16),
              _TranslationResultPanel(hands: _hands, l10n: l10n),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VisualinBottomNav(index: 1),
    );
  }
}

class _CameraPreviewPanel extends StatelessWidget {
  const _CameraPreviewPanel({
    required this.controller,
    required this.hands,
    required this.initializing,
    required this.cameraUnavailable,
    required this.frameLabel,
  });

  final CameraController? controller;
  final ValueNotifier<List<List<LandmarkPoint>>> hands;
  final bool initializing;
  final String cameraUnavailable;
  final String frameLabel;

  @override
  Widget build(BuildContext context) {
    final isReady = controller?.value.isInitialized == true;
    return Semantics(
      label: frameLabel,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: VisualinRadii.card,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: isReady
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    // Preview and painter share bounds so landmark positions
                    // remain correct within the rounded camera crop.
                    child: CameraPreview(
                      controller!,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: LandmarkPainter(
                              hands: hands,
                              controller: controller!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 172,
                        height: 224,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: VisualinColors.primaryOrange,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: initializing
                    ? const CircularProgressIndicator(
                        color: VisualinColors.primaryOrange,
                      )
                    : Text(
                        cameraUnavailable,
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
      ),
    );
  }
}

class _TranslationResultPanel extends StatelessWidget {
  const _TranslationResultPanel({required this.hands, required this.l10n});

  final ValueNotifier<List<List<LandmarkPoint>>> hands;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<List<LandmarkPoint>>>(
      valueListenable: hands,
      builder: (context, detectedHands, _) {
        final hasHand = detectedHands.isNotEmpty;
        final status = hasHand ? l10n.handDetected : l10n.noHandDetected;
        final guidance = hasHand
            ? l10n.cameraGuidanceHandDetected
            : l10n.cameraGuidanceNoHand;
        final outputLanguage = l10n.isEnglish ? l10n.english : l10n.filipino;
        return Semantics(
          liveRegion: true,
          label: '$status. $guidance',
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translatedText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: VisualinColors.orangeTint,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasHand
                                ? Icons.check_circle_outline
                                : Icons.pan_tool_outlined,
                            size: 16,
                            color: VisualinColors.primaryOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: VisualinColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(guidance, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: VisualinColors.orangeTint,
                    borderRadius: VisualinRadii.control,
                  ),
                  child: Text(
                    l10n.translationWaiting,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.fslToOutputLanguage(outputLanguage),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.confidenceUnavailable,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.volume_up_outlined),
                      label: Text(l10n.speak),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.copy),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.bookmark_border),
                      label: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LandmarkPainter extends CustomPainter {
  LandmarkPainter({required this.hands, required this.controller})
      : super(repaint: Listenable.merge(<Listenable>[hands, controller]));

  final ValueListenable<List<List<LandmarkPoint>>> hands;
  final CameraController controller;

  static final Paint _linePaint = Paint()
    ..color = const Color(0xB3FF6B0A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _jointPaint = Paint()
    ..color = VisualinColors.primaryOrange
    ..style = PaintingStyle.fill;
  static final Paint _fingertipGlowPaint = Paint()
    ..color = const Color(0x33FF6B0A)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  static const double _jointRadius = 3.5;
  static const double _fingertipRadius = 5.5;
  static const double _fingertipGlowRadius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = CameraOverlayTransform.fromCamera(controller);
    for (final hand in hands.value) {
      final points = hand
          .map((landmark) => transform.apply(landmark.x, landmark.y))
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList(growable: false);

      for (final connection in handLandmarkConnections) {
        if (connection.startIndex >= points.length ||
            connection.endIndex >= points.length) {
          continue;
        }
        canvas.drawLine(
          points[connection.startIndex],
          points[connection.endIndex],
          _linePaint,
        );
      }

      for (var index = 0; index < hand.length; index++) {
        final isFingertip = handLandmarkFingertips.contains(index);
        if (isFingertip) {
          canvas.drawCircle(
            points[index],
            _fingertipGlowRadius,
            _fingertipGlowPaint,
          );
        }
        canvas.drawCircle(
          points[index],
          isFingertip ? _fingertipRadius : _jointRadius,
          _jointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(LandmarkPainter oldDelegate) =>
      hands != oldDelegate.hands || controller != oldDelegate.controller;
}
