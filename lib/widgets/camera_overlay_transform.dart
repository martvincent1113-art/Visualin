import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Maps normalized, sensor-space landmarks onto the orientation shown by the
/// Android camera preview.
///
/// Camera frames arrive in the sensor's native coordinate space. The preview
/// is instead oriented for the current device orientation, and front-camera
/// previews are mirrored. Keeping this conversion separate from painting makes
/// the mapping testable and ensures all overlay points use the same geometry.
class CameraOverlayTransform {
  const CameraOverlayTransform({
    required this.rotationDegrees,
    required this.mirrorHorizontally,
  }) : assert(
          rotationDegrees == 0 ||
              rotationDegrees == 90 ||
              rotationDegrees == 180 ||
              rotationDegrees == 270,
        );

  factory CameraOverlayTransform.fromCamera(CameraController controller) {
    final camera = controller.value.description;
    return CameraOverlayTransform.fromConfiguration(
      sensorOrientation: camera.sensorOrientation,
      deviceOrientation: controller.value.deviceOrientation,
      lensDirection: camera.lensDirection,
    );
  }

  factory CameraOverlayTransform.fromConfiguration({
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
    required CameraLensDirection lensDirection,
  }) {
    final deviceRotation = _deviceRotationDegrees(
      deviceOrientation,
    );
    final isFrontCamera = lensDirection == CameraLensDirection.front;

    // This matches Android's sensor-to-display orientation convention. The
    // front camera rotates in the opposite direction before its preview is
    // mirrored; the back camera does not mirror.
    final rotationDegrees = isFrontCamera
        ? (sensorOrientation + deviceRotation) % 360
        : (sensorOrientation - deviceRotation + 360) % 360;

    return CameraOverlayTransform(
      rotationDegrees: rotationDegrees,
      mirrorHorizontally: isFrontCamera,
    );
  }

  final int rotationDegrees;
  final bool mirrorHorizontally;

  /// Converts a normalized point from the sensor frame into the preview's
  /// normalized coordinate space. The caller scales this only after the point
  /// is inside the actual CameraPreview child bounds.
  Offset apply(double x, double y) {
    final rotated = switch (rotationDegrees) {
      0 => Offset(x, y),
      90 => Offset(1 - y, x),
      180 => Offset(1 - x, 1 - y),
      270 => Offset(y, 1 - x),
      _ => throw StateError('Unsupported camera rotation: $rotationDegrees'),
    };
    return mirrorHorizontally
        ? Offset(1 - rotated.dx, rotated.dy)
        : rotated;
  }

  static int _deviceRotationDegrees(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeRight => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeLeft => 270,
    };
  }
}
