import 'package:permission_handler/permission_handler.dart';

/// Keeps camera permission checks explicit and separate from camera startup.
/// No camera controller is created until [isGranted] returns true.
class CameraPermissionService {
  Future<PermissionStatus> get status => Permission.camera.status;

  Future<bool> get isGranted async => (await status).isGranted;

  Future<PermissionStatus> request() => Permission.camera.request();

  Future<bool> requestAccess() async => (await request()).isGranted;

  Future<bool> openSettings() => openAppSettings();
}
