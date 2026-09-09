import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../services/camera_permission_service.dart';
import '../theme/visualin_tokens.dart';

/// An intentional permission screen shown before the camera feature starts.
class CameraPermissionGate extends StatefulWidget {
  const CameraPermissionGate({
    super.key,
    required this.cameraScreenBuilder,
    this.permissionService,
  });

  final WidgetBuilder cameraScreenBuilder;
  final CameraPermissionService? permissionService;

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  late final CameraPermissionService _permissionService =
      widget.permissionService ?? CameraPermissionService();
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _permissionService.status;
    if (mounted) setState(() => _status = status);
  }

  Future<void> _requestPermission() async {
    final status = await _permissionService.request();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: VisualinColors.primaryOrange),
        ),
      );
    }
    if (status.isGranted) return widget.cameraScreenBuilder(context);

    final l10n = AppLocalizations.of(context);
    final isPermanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: VisualinColors.primaryOrange,
                ),
                const SizedBox(height: 24),
                Text(l10n.cameraPermissionTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(l10n.cameraPermissionBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isPermanentlyDenied ? _permissionService.openSettings : _requestPermission,
                    child: Text(isPermanentlyDenied
                        ? l10n.openSettings
                        : l10n.allowCamera),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.later),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
