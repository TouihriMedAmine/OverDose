import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScanCameraTab extends StatefulWidget {
  const ScanCameraTab({super.key});

  @override
  State<ScanCameraTab> createState() => _ScanCameraTabState();
}

class _ScanCameraTabState extends State<ScanCameraTab> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  List<CameraDescription> _cameras = const [];
  String? _error;
  bool _isRearCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
      if (!mounted) return;
      setState(() {
        _error = 'Camera preview is supported on mobile devices only.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      _cameras = cameras;
      final camera = _pickCamera();
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      final future = controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializeFuture = future;
        _error = null;
      });
      await future;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Camera failed to initialize: $e');
    }
  }

  CameraDescription _pickCamera() {
    if (_cameras.isEmpty) {
      throw StateError('No cameras available');
    }
    final preferredPosition = _isRearCamera ? CameraLensDirection.back : CameraLensDirection.front;
    final preferred = _cameras.where((c) => c.lensDirection == preferredPosition).toList();
    return preferred.isNotEmpty ? preferred.first : _cameras.first;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _isRearCamera = !_isRearCamera;
    await _controller?.dispose();
    _controller = null;
    await _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Switch camera',
                onPressed: _cameras.length > 1 ? _switchCamera : null,
                icon: const Icon(Icons.cameraswitch_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use the camera to scan a product, label, or barcode area.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPreview(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What to scan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Center the product label in the frame. The current version shows live camera preview and can be extended to capture or recognize labels next.', style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _messageBox(context, error, icon: Icons.videocam_off_rounded);
    }

    final controller = _controller;
    if (controller == null) {
      return _messageBox(context, 'Starting camera...');
    }

    final future = _initializeFuture;
    if (future == null) {
      return _messageBox(context, 'Starting camera...');
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !controller.value.isInitialized) {
          return _messageBox(context, 'Starting camera...');
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live camera ready',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _messageBox(BuildContext context, String message, {IconData icon = Icons.photo_camera_outlined}) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}