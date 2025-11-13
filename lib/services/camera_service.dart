import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();
  CameraService._();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;

  // Initialize camera service
  Future<bool> initialize() async {
    try {
      Logger.info('Initializing camera service');

      // Request camera and microphone permissions
      final cameraPermission = await Permission.camera.request();
      final microphonePermission = await Permission.microphone.request();

      if (!cameraPermission.isGranted || !microphonePermission.isGranted) {
        Logger.error('Camera or microphone permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        Logger.error('No cameras available');
        return false;
      }

      Logger.info('Found ${_cameras.length} cameras');
      return true;
    } catch (e) {
      Logger.error('Error initializing camera service: $e');
      return false;
    }
  }

  // Initialize camera controller
  Future<bool> initializeCamera({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = true,
  }) async {
    try {
      if (_cameras.isEmpty) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // Use provided camera or default to first available
      final selectedCamera = camera ?? _cameras.first;

      _controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;

      Logger.info('Camera controller initialized successfully');
      return true;
    } catch (e) {
      Logger.error('Error initializing camera controller: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Switch between front and back camera
  Future<bool> switchCamera() async {
    if (_cameras.length < 2 || !_isInitialized) return false;

    try {
      final currentCamera = _controller!.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras.first,
      );

      await _controller!.dispose();
      return await initializeCamera(camera: newCamera);
    } catch (e) {
      Logger.error('Error switching camera: $e');
      return false;
    }
  }

  // Take a photo
  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      Logger.error('Camera not initialized');
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      Logger.info('Photo taken: ${photo.path}');
      return File(photo.path);
    } catch (e) {
      Logger.error('Error taking picture: $e');
      return null;
    }
  }

  // Start video recording
  Future<bool> startVideoRecording() async {
    if (!_isInitialized || _controller == null || _isRecording) {
      Logger.error('Cannot start recording: camera not ready or already recording');
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      Logger.info('Video recording started');
      return true;
    } catch (e) {
      Logger.error('Error starting video recording: $e');
      return false;
    }
  }

  // Stop video recording
  Future<File?> stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      Logger.error('Not currently recording');
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _isRecording = false;
      Logger.info('Video recording stopped: ${video.path}');
      return File(video.path);
    } catch (e) {
      Logger.error('Error stopping video recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Pause video recording
  Future<bool> pauseVideoRecording() async {
    if (!_isRecording || _controller == null) return false;

    try {
      await _controller!.pauseVideoRecording();
      Logger.info('Video recording paused');
      return true;
    } catch (e) {
      Logger.error('Error pausing video recording: $e');
      return false;
    }
  }

  // Resume video recording
  Future<bool> resumeVideoRecording() async {
    if (!_isRecording || _controller == null) return false;

    try {
      await _controller!.resumeVideoRecording();
      Logger.info('Video recording resumed');
      return true;
    } catch (e) {
      Logger.error('Error resuming video recording: $e');
      return false;
    }
  }

  // Set flash mode
  Future<bool> setFlashMode(FlashMode mode) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setFlashMode(mode);
      Logger.info('Flash mode set to: $mode');
      return true;
    } catch (e) {
      Logger.error('Error setting flash mode: $e');
      return false;
    }
  }

  // Set exposure mode
  Future<bool> setExposureMode(ExposureMode mode) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setExposureMode(mode);
      Logger.info('Exposure mode set to: $mode');
      return true;
    } catch (e) {
      Logger.error('Error setting exposure mode: $e');
      return false;
    }
  }

  // Set focus mode
  Future<bool> setFocusMode(FocusMode mode) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setFocusMode(mode);
      Logger.info('Focus mode set to: $mode');
      return true;
    } catch (e) {
      Logger.error('Error setting focus mode: $e');
      return false;
    }
  }

  // Set zoom level
  Future<bool> setZoomLevel(double zoom) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setZoomLevel(zoom);
      Logger.info('Zoom level set to: $zoom');
      return true;
    } catch (e) {
      Logger.error('Error setting zoom level: $e');
      return false;
    }
  }

  // Get maximum zoom level
  Future<double> getMaxZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;

    try {
      return await _controller!.getMaxZoomLevel();
    } catch (e) {
      Logger.error('Error getting max zoom level: $e');
      return 1.0;
    }
  }

  // Get minimum zoom level
  Future<double> getMinZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;

    try {
      return await _controller!.getMinZoomLevel();
    } catch (e) {
      Logger.error('Error getting min zoom level: $e');
      return 1.0;
    }
  }

  // Focus on point
  Future<bool> focusOnPoint(Offset point) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setFocusPoint(point);
      Logger.info('Focus set to point: $point');
      return true;
    } catch (e) {
      Logger.error('Error setting focus point: $e');
      return false;
    }
  }

  // Set exposure point
  Future<bool> setExposurePoint(Offset point) async {
    if (!_isInitialized || _controller == null) return false;

    try {
      await _controller!.setExposurePoint(point);
      Logger.info('Exposure point set to: $point');
      return true;
    } catch (e) {
      Logger.error('Error setting exposure point: $e');
      return false;
    }
  }

  // Get camera info
  Map<String, dynamic> getCameraInfo() {
    if (!_isInitialized || _controller == null) {
      return {'initialized': false};
    }

    return {
      'initialized': _isInitialized,
      'recording': _isRecording,
      'camera_count': _cameras.length,
      'current_camera': _controller!.description.name,
      'lens_direction': _controller!.description.lensDirection.toString(),
      'resolution': _controller!.resolutionPreset.toString(),
    };
  }

  // Dispose camera resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopVideoRecording();
      }
      
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _isRecording = false;
      
      Logger.info('Camera service disposed');
    } catch (e) {
      Logger.error('Error disposing camera service: $e');
    }
  }
}

// Camera preview widget
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final Widget? overlay;
  final VoidCallback? onTap;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.overlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
