import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../services/camera_service.dart';
import '../services/stories_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class StoryCreatorScreen extends StatefulWidget {
  const StoryCreatorScreen({super.key});

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen>
    with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService.instance;
  final StoriesService _storiesService = StoriesService.instance;
  final TextEditingController _captionController = TextEditingController();

  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  File? _capturedMedia;
  VideoPlayerController? _videoController;
  String _currentMode = 'photo'; // 'photo' or 'video'
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  FlashMode _flashMode = FlashMode.auto;

  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimations();
  }

  void _setupAnimations() {
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      final success = await _cameraService.initializeCamera();
      if (success) {
        _maxZoom = await _cameraService.getMaxZoomLevel();
        _minZoom = await _cameraService.getMinZoomLevel();
        setState(() {
          _isInitialized = true;
        });
      } else {
        _showError('Failed to initialize camera');
      }
    } catch (e) {
      Logger.error('Error initializing camera: $e');
      _showError('Camera initialization failed');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    _recordingAnimationController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? _buildCameraInterface()
            : _buildLoadingScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: AppConstants.mdSpacing),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraInterface() {
    if (_capturedMedia != null) {
      return _buildPreviewScreen();
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: _cameraService.controller != null
              ? CameraPreview(_cameraService.controller!)
              : Container(color: Colors.black),
        ),

        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopControls(),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),

        // Zoom slider
        if (_maxZoom > _minZoom)
          Positioned(
            right: 20,
            top: 100,
            bottom: 200,
            child: _buildZoomSlider(),
          ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 60,
            left: 20,
            child: _buildRecordingIndicator(),
          ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),

          // Mode selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.mdSpacing,
              vertical: AppConstants.smSpacing,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton('PHOTO', 'photo'),
                const SizedBox(width: AppConstants.mdSpacing),
                _buildModeButton('VIDEO', 'video'),
              ],
            ),
          ),

          // Flash button
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _getFlashIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.lgSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          IconButton(
            onPressed: _openGallery,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: _currentMode == 'photo' ? _takePicture : null,
            onLongPressStart: _currentMode == 'video' ? (_) => _startRecording() : null,
            onLongPressEnd: _currentMode == 'video' ? (_) => _stopRecording() : null,
            child: AnimatedBuilder(
              animation: _recordingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _recordingAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isRecording
                        ? const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 32,
                          )
                        : Icon(
                            _currentMode == 'photo'
                                ? Icons.camera_alt
                                : Icons.videocam,
                            color: Colors.black,
                            size: 32,
                          ),
                  ),
                );
              },
            ),
          ),

          // Switch camera button
          IconButton(
            onPressed: _switchCamera,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomSlider() {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        value: _currentZoom,
        min: _minZoom,
        max: _maxZoom,
        onChanged: (value) {
          setState(() {
            _currentZoom = value;
          });
          _cameraService.setZoomLevel(value);
        },
        activeColor: AppTheme.primaryBlue,
        inactiveColor: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.mdSpacing,
        vertical: AppConstants.smSpacing,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'REC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen() {
    return Stack(
      children: [
        // Media preview
        Positioned.fill(
          child: _buildMediaPreview(),
        ),

        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildPreviewTopControls(),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildPreviewBottomControls(),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    if (_capturedMedia == null) return Container();

    if (_currentMode == 'photo') {
      return Image.file(
        _capturedMedia!,
        fit: BoxFit.cover,
      );
    } else {
      return _videoController != null && _videoController!.value.isInitialized
          ? VideoPlayer(_videoController!)
          : Container(color: Colors.black);
    }
  }

  Widget _buildPreviewTopControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _retakeMedia,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Text(
            'Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Balance the row
        ],
      ),
    );
  }

  Widget _buildPreviewBottomControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.lgSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caption input
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            maxLines: 3,
            minLines: 1,
          ),
          
          const SizedBox(height: AppConstants.mdSpacing),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Retake button
              TextButton.icon(
                onPressed: _retakeMedia,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retake',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              
              // Share button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _shareStory,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProcessing ? 'Sharing...' : 'Share Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.lgSpacing,
                    vertical: AppConstants.mdSpacing,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  Future<void> _toggleFlash() async {
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      default:
        newMode = FlashMode.auto;
    }

    final success = await _cameraService.setFlashMode(newMode);
    if (success) {
      setState(() {
        _flashMode = newMode;
      });
    }
  }

  Future<void> _switchCamera() async {
    await _cameraService.switchCamera();
  }

  Future<void> _takePicture() async {
    final photo = await _cameraService.takePicture();
    if (photo != null) {
      setState(() {
        _capturedMedia = photo;
      });
    }
  }

  Future<void> _startRecording() async {
    final success = await _cameraService.startVideoRecording();
    if (success) {
      setState(() {
        _isRecording = true;
      });
      _recordingAnimationController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording() async {
    final video = await _cameraService.stopVideoRecording();
    if (video != null) {
      setState(() {
        _isRecording = false;
        _capturedMedia = video;
      });
      _recordingAnimationController.stop();
      _recordingAnimationController.reset();
      
      // Initialize video player
      _videoController = VideoPlayerController.file(video);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      setState(() {});
    }
  }

  void _openGallery() {
    // TODO: Implement gallery picker
    _showError('Gallery picker not implemented yet');
  }

  void _retakeMedia() {
    setState(() {
      _capturedMedia = null;
    });
    _videoController?.dispose();
    _videoController = null;
    _captionController.clear();
  }

  Future<void> _shareStory() async {
    if (_capturedMedia == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.userData;
      
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      // Upload media
      final mediaUrl = await _storiesService.uploadStoryMedia(
        userId: currentUser['id'],
        imageFile: _capturedMedia!,
      );

      if (mediaUrl == null) {
        _showError('Failed to upload media');
        return;
      }

      // Create story
      final story = await _storiesService.createStory(
        userId: currentUser['id'],
        mediaUrl: mediaUrl,
        content: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        mediaType: _currentMode,
      );

      if (story != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story shared successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        _showError('Failed to create story');
      }
    } catch (e) {
      Logger.error('Error sharing story: $e');
      _showError('Failed to share story');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }
}
