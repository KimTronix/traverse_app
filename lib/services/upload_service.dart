import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import 'auth_service.dart';

class UploadService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  // Upload file to Supabase Storage
  static Future<String?> uploadFile({
    required String bucket,
    required String filePath,
    required Uint8List fileBytes,
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename if not provided
      fileName ??= '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      
      // Create user-specific path
      final userPath = '${user.id}/$fileName';

      // Upload file
      await _client.storage.from(bucket).uploadBinary(
        userPath,
        fileBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: _getContentType(filePath),
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from(bucket).getPublicUrl(userPath);
      
      Logger.info('File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading file', e);
      return null;
    }
  }

  // Upload image from file
  static Future<String?> uploadImageFile({
    required String bucket,
    required File imageFile,
    String? fileName,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await uploadFile(
        bucket: bucket,
        filePath: imageFile.path,
        fileBytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      Logger.error('Error uploading image file', e);
      return null;
    }
  }

  // Pick and upload image from gallery
  static Future<String?> pickAndUploadImage({
    required String bucket,
    ImageSource source = ImageSource.gallery,
    int? imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      return await uploadFile(
        bucket: bucket,
        filePath: image.path,
        fileBytes: bytes,
      );
    } catch (e) {
      Logger.error('Error picking and uploading image', e);
      return null;
    }
  }

  // Pick and upload multiple images
  static Future<List<String>> pickAndUploadMultipleImages({
    required String bucket,
    int? imageQuality = 80,
    int? limit = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
        limit: limit,
      );

      if (images.isEmpty) return [];

      final List<String> uploadedUrls = [];
      
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final url = await uploadFile(
          bucket: bucket,
          filePath: image.path,
          fileBytes: bytes,
        );
        
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      return uploadedUrls;
    } catch (e) {
      Logger.error('Error picking and uploading multiple images', e);
      return [];
    }
  }

  // Upload avatar image
  static Future<String?> uploadAvatar({
    ImageSource source = ImageSource.gallery,
  }) async {
    return await pickAndUploadImage(
      bucket: 'avatars',
      source: source,
      imageQuality: 90,
    );
  }

  // Upload post images
  static Future<List<String>> uploadPostImages() async {
    return await pickAndUploadMultipleImages(
      bucket: 'posts',
      imageQuality: 85,
      limit: 10,
    );
  }

  // Upload story media
  static Future<String?> uploadStoryMedia({
    ImageSource source = ImageSource.gallery,
  }) async {
    return await pickAndUploadImage(
      bucket: 'stories',
      source: source,
      imageQuality: 80,
    );
  }

  // Delete file from storage
  static Future<bool> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Extract user path from URL if needed
      String userPath = filePath;
      if (filePath.contains('${user.id}/')) {
        userPath = filePath.split('${user.id}/').last;
        userPath = '${user.id}/$userPath';
      }

      await _client.storage.from(bucket).remove([userPath]);
      
      Logger.info('File deleted successfully: $userPath');
      return true;
    } catch (e) {
      Logger.error('Error deleting file', e);
      return false;
    }
  }

  // Get content type from file extension
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  // Validate file size
  static bool isValidFileSize(Uint8List bytes, {int maxSizeInMB = 10}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return bytes.length <= maxSizeInBytes;
  }

  // Validate image format
  static bool isValidImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(extension);
  }

  // Validate video format
  static bool isValidVideoFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi'].contains(extension);
  }

  // Get file size in MB
  static double getFileSizeInMB(Uint8List bytes) {
    return bytes.length / (1024 * 1024);
  }
}