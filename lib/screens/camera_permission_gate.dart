import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../services/camera_permission_service.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

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

class _CameraPermissionGateState extends State<CameraPermissionGate>
    with WidgetsBindingObserver {
  late final CameraPermissionService _permissionService =
      widget.permissionService ?? CameraPermissionService();
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _permissionService.status;
    if (mounted) setState(() => _status = status);
  }

  Future<void> _requestPermission() async {
    final status = await _permissionService.request();
    if (mounted) setState(() => _status = status);
  }

  void _leaveCamera() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const AppScreen(
        tabIndex: 1,
        body: Center(
          child: CircularProgressIndicator(color: VisualinColors.primaryOrange),
        ),
      );
    }
    if (status.isGranted) return widget.cameraScreenBuilder(context);

    final l10n = AppLocalizations.of(context);
    final isPermanentlyDenied =
        status.isPermanentlyDenied || status.isRestricted;
    return AppScreen(
      tabIndex: 1,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  SizedBox(
                    width: VisualinSpacing.minimumTapTarget,
                    height: VisualinSpacing.minimumTapTarget,
                    child: IconButton(
                      onPressed: _leaveCamera,
                      icon: const Icon(Icons.close),
                      tooltip: l10n.close,
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.fslToText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: VisualinSpacing.minimumTapTarget),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Semantics(
                  liveRegion: true,
                  child: SectionCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VisualinIconTile(
                          icon: Icons.camera_alt_outlined,
                          size: 64,
                          iconSize: 32,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          l10n.cameraPermissionTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.cameraPermissionBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.cameraPermissionSettingsBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isPermanentlyDenied
                                ? _permissionService.openSettings
                                : _requestPermission,
                            child: Text(
                              isPermanentlyDenied
                                  ? l10n.openSettings
                                  : l10n.allowCamera,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _leaveCamera,
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: VisualinColors.secondaryText,
                            ),
                            child: Text(l10n.notNow),
                          ),
                        ),
                      ],
                    ),
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
