import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class LandmarkPoint {
  const LandmarkPoint(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class LandmarkFrame {
  const LandmarkFrame(this.hands);

  final List<List<LandmarkPoint>> hands;
}

abstract class LandmarkDetector {
  Stream<LandmarkFrame> get frames;
  Future<void> start(
    CameraController controller, {
    bool Function()? isActive,
  });
  Future<void> stop();
}

/// Adapter boundary for the Android hand_landmarker pipeline.
///
/// `HandLandmarkerPlugin.detect` is synchronous and blocking. The plugin
/// therefore lives in a dedicated Dart isolate; the UI isolate only copies a
/// selected camera frame to the worker and receives normalized landmarks.
class LandmarkService implements LandmarkDetector {
  final StreamController<LandmarkFrame> _controller =
      StreamController<LandmarkFrame>.broadcast();

  CameraController? _camera;
  Isolate? _worker;
  ReceivePort? _workerResponses;
  SendPort? _workerCommands;
  Completer<void>? _workerInitialized;
  Completer<void>? _workerStopped;
  /// Exactly one detection may use the native tensor at a time. Frames that
  /// arrive while this is true are intentionally discarded.
  bool _isProcessing = false;
  int _session = 0;
  Future<void> _operations = Future<void>.value();

  @override
  Stream<LandmarkFrame> get frames => _controller.stream;

  @override
  Future<void> start(
    CameraController controller, {
    bool Function()? isActive,
  }) {
    final session = ++_session;
    return _enqueue(() async {
      if (session != _session) return;
      await _stopActiveSession();
      if (session != _session) return;

      _camera = controller;
      await _startWorker();
      if (session != _session) return;
      await controller.startImageStream(
        (image) => _processCameraImage(image, session, isActive),
      );
    });
  }

  @override
  Future<void> stop() {
    _session++;
    _isProcessing = false;
    return _enqueue(_stopActiveSession);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final queued = _operations.then((_) => operation());
    // Keep later lifecycle operations usable if startup or shutdown failed.
    _operations = queued.catchError((Object _) {});
    return queued;
  }

  Future<void> _stopActiveSession() async {
    final camera = _camera;
    _camera = null;
    _isProcessing = false;
    if (camera?.value.isStreamingImages == true) {
      await camera!.stopImageStream();
    }
    await _stopWorker();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<void> _startWorker() async {
    final responses = ReceivePort();
    final initialized = Completer<void>();
    _workerResponses = responses;
    _workerInitialized = initialized;
    responses.listen(_onWorkerResponse);

    _worker = await Isolate.spawn(
      _handLandmarkerWorker,
      responses.sendPort,
      errorsAreFatal: true,
      onError: responses.sendPort,
    );
    await initialized.future.timeout(const Duration(seconds: 5));
  }

  Future<void> _stopWorker() async {
    final worker = _worker;
    final commands = _workerCommands;
    final responses = _workerResponses;
    _worker = null;
    _workerCommands = null;
    _workerResponses = null;
    _workerInitialized = null;

    if (worker != null && commands != null) {
      final stopped = Completer<void>();
      _workerStopped = stopped;
      commands.send(const <String, Object?>{'type': 'stop'});
      try {
        await stopped.future.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        // The isolate is only a single in-flight detector. Killing it is a
        // safe last resort during teardown and avoids retaining the camera.
      }
    }
    _workerStopped = null;
    worker?.kill(priority: Isolate.immediate);
    responses?.close();
  }

  void _processCameraImage(
    CameraImage image,
    int session,
    bool Function()? isActive,
  ) {
    // This callback can be delivered after stopImageStream has been requested.
    // Do not access the camera, worker, or UI-facing stream once its session
    // has ended. The processing guard prevents concurrent tensor writes.
    if ((isActive != null && !isActive()) ||
        session != _session ||
        _isProcessing ||
        _camera == null ||
        _workerCommands == null) {
      return;
    }

    final camera = _camera!;
    if (!camera.value.isInitialized || !camera.value.isStreamingImages) {
      return;
    }
    final commands = _workerCommands;
    if (commands == null || image.planes.length != 3) return;

    _isProcessing = true;
    try {
      commands.send(<String, Object?>{
        'type': 'frame',
        'session': session,
        'sensorOrientation': camera.description.sensorOrientation,
        'width': image.width,
        'height': image.height,
        // TransferableTypedData prevents a second Dart heap copy in the
        // worker. The raw YUV planes are sent directly; no RGB conversion is
        // performed on the UI isolate.
        'planes': <TransferableTypedData>[
          for (final plane in image.planes)
            TransferableTypedData.fromList(<TypedData>[plane.bytes]),
        ],
        'bytesPerRow': <int>[
          for (final plane in image.planes) plane.bytesPerRow,
        ],
        'bytesPerPixel': <int>[
          for (final plane in image.planes) plane.bytesPerPixel ?? 1,
        ],
      });
    } catch (_) {
      // A send failure means the worker has already stopped. Do not retain a
      // busy flag that would prevent a future session from accepting frames.
      _finishProcessing(session);
    }
  }

  void _onWorkerResponse(dynamic message) {
    if (message is List<Object?>) {
      // Uncaught isolate errors arrive on the configured error port.
      _isProcessing = false;
      return;
    }
    if (message is! Map<Object?, Object?>) return;

    switch (message['type']) {
      case 'ready':
        _workerCommands = message['commands'] as SendPort?;
        _workerCommands!.send(const <String, Object?>{'type': 'initialize'});
        return;
      case 'initialized':
        _workerInitialized?.complete();
        return;
      case 'stopped':
        _workerStopped?.complete();
        return;
      case 'result':
        _handleDetectionResult(message);
        return;
      case 'error':
        _handleDetectionError(message);
        return;
    }
  }

  void _handleDetectionResult(Map<Object?, Object?> message) {
    final session = message['session'];
    if (session != _session) return;

    try {
      final encodedHands = message['hands'] as List<Object?>? ?? const [];
      final frame = LandmarkFrame(<List<LandmarkPoint>>[
        for (final encodedHand in encodedHands)
          _decodeHand(encodedHand! as List<Object?>),
      ]);
      if (session == _session && !_controller.isClosed) {
        _controller.add(frame);
      }
    } finally {
      _finishProcessing(session as int);
    }
  }

  void _handleDetectionError(Map<Object?, Object?> message) {
    final session = message['session'];
    try {
      final initialized = _workerInitialized;
      if (initialized != null && !initialized.isCompleted) {
        initialized.completeError(
          StateError(
            message['error']?.toString() ?? 'Hand landmarker worker failed',
          ),
        );
      }
    } finally {
      if (session is int) {
        _finishProcessing(session);
      } else {
        _isProcessing = false;
      }
    }
  }

  void _finishProcessing(int session) {
    if (session == _session) _isProcessing = false;
  }
}

List<LandmarkPoint> _decodeHand(List<Object?> encodedHand) => <LandmarkPoint>[
      for (final encodedPoint in encodedHand)
        _decodePoint(encodedPoint! as List<Object?>),
    ];

LandmarkPoint _decodePoint(List<Object?> encodedPoint) => LandmarkPoint(
      (encodedPoint[0]! as num).toDouble(),
      (encodedPoint[1]! as num).toDouble(),
      (encodedPoint[2]! as num).toDouble(),
    );

/// Isolate entry point. It owns the JNI/plugin objects, so its synchronous
/// calls cannot block Flutter's UI isolate.
void _handLandmarkerWorker(SendPort responses) {
  final commands = ReceivePort();
  responses
      .send(<String, Object?>{'type': 'ready', 'commands': commands.sendPort});

  HandLandmarkerPlugin? plugin;
  commands.listen((dynamic message) {
    if (message is! Map<Object?, Object?>) return;
    switch (message['type']) {
      case 'initialize':
        try {
          plugin = HandLandmarkerPlugin.create(
            numHands: 2,
            minHandDetectionConfidence: 0.7,
            // The package constructs a Bitmap-backed MPImage for every
            // CameraImage. On the GPU delegate this device reports MediaPipe
            // tensor write races even with one Dart request in flight. CPU
            // avoids that unsafe bitmap-to-GPU path; the one-in-flight guard
            // still provides adaptive backpressure on slower devices.
            delegate: HandLandmarkerDelegate.cpu,
          );
          responses.send(const <String, Object?>{'type': 'initialized'});
        } catch (error) {
          responses.send(<String, Object?>{
            'type': 'error',
            'session': message['session'],
            'error': '$error',
          });
        }
        return;
      case 'frame':
        if (plugin == null) return;
        try {
          final image = _cameraImageFromMessage(message);
          final hands = plugin!.detect(
            image,
            message['sensorOrientation']! as int,
          );
          responses.send(<String, Object?>{
            'type': 'result',
            'session': message['session'],
            'hands': <List<List<double>>>[
              for (final hand in hands)
                <List<double>>[
                  for (final point in hand.landmarks)
                    <double>[point.x, point.y, point.z],
                ],
            ],
          });
        } catch (error) {
          responses.send(<String, Object?>{
            'type': 'error',
            'session': message['session'],
            'error': '$error',
          });
        }
        return;
      case 'stop':
        plugin?.dispose();
        commands.close();
        responses.send(const <String, Object?>{'type': 'stopped'});
        return;
    }
  });
}

CameraImage _cameraImageFromMessage(Map<Object?, Object?> message) {
  final planeData = message['planes']! as List<Object?>;
  final bytesPerRow = message['bytesPerRow']! as List<Object?>;
  final bytesPerPixel = message['bytesPerPixel']! as List<Object?>;
  // `camera` does not export CameraImageData, which is needed for the newer
  // constructor. This compatibility constructor lets the worker recreate the
  // exact Android YUV_420_888 planes without adding another dependency.
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData(<String, Object?>{
    // android.graphics.ImageFormat.YUV_420_888
    'format': 35,
    'width': message['width'],
    'height': message['height'],
    'planes': <Map<String, Object?>>[
      for (var index = 0; index < planeData.length; index++)
        <String, Object?>{
          'bytes': (planeData[index]! as TransferableTypedData)
              .materialize()
              .asUint8List(),
          'bytesPerRow': bytesPerRow[index],
          'bytesPerPixel': bytesPerPixel[index],
        },
    ],
  });
}
