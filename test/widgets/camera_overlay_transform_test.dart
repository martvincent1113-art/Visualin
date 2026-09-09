import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:visualin/widgets/camera_overlay_transform.dart';

void main() {
  group('CameraOverlayTransform', () {
    test('rotates all four sensor orientations into preview space', () {
      const pointX = 0.2;
      const pointY = 0.3;

      expect(
        const CameraOverlayTransform(
          rotationDegrees: 0,
          mirrorHorizontally: false,
        ).apply(pointX, pointY),
        const Offset(0.2, 0.3),
      );
      expect(
        const CameraOverlayTransform(
          rotationDegrees: 90,
          mirrorHorizontally: false,
        ).apply(pointX, pointY),
        const Offset(0.7, 0.2),
      );
      expect(
        const CameraOverlayTransform(
          rotationDegrees: 180,
          mirrorHorizontally: false,
        ).apply(pointX, pointY),
        const Offset(0.8, 0.7),
      );
      expect(
        const CameraOverlayTransform(
          rotationDegrees: 270,
          mirrorHorizontally: false,
        ).apply(pointX, pointY),
        const Offset(0.3, 0.8),
      );
    });

    test('mirrors only after the sensor rotation', () {
      const transform = CameraOverlayTransform(
        rotationDegrees: 90,
        mirrorHorizontally: true,
      );

      final point = transform.apply(0.2, 0.3);
      expect(point.dx, closeTo(0.3, 0.000001));
      expect(point.dy, closeTo(0.2, 0.000001));
    });

    test('uses the front-camera rotation convention and mirror', () {
      final front = CameraOverlayTransform.fromConfiguration(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.portraitUp,
        lensDirection: CameraLensDirection.front,
      );
      final back = CameraOverlayTransform.fromConfiguration(
        sensorOrientation: 90,
        deviceOrientation: DeviceOrientation.portraitUp,
        lensDirection: CameraLensDirection.back,
      );

      expect(front.rotationDegrees, 270);
      expect(front.mirrorHorizontally, isTrue);
      expect(back.rotationDegrees, 90);
      expect(back.mirrorHorizontally, isFalse);
    });
  });
}
