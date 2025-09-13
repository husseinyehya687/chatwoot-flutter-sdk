import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Check and request storage permissions needed for file attachments
  static Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we need different permissions
        if (await _getAndroidVersion() >= 33) {
          return await _requestAndroid13Permissions();
        } else {
          return await _requestLegacyAndroidPermissions();
        }
      } else if (Platform.isIOS) {
        // iOS handles permissions automatically through the system
        return true;
      }
      
      // For other platforms, assume permissions are handled
      return true;
    } catch (e) {
      print('Error requesting storage permissions: $e');
      return false;
    }
  }

  /// Check if storage permissions are currently granted
  static Future<bool> hasStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        if (await _getAndroidVersion() >= 33) {
          return await _hasAndroid13Permissions();
        } else {
          return await _hasLegacyAndroidPermissions();
        }
      }
      return true;
    } catch (e) {
      print('Error checking storage permissions: $e');
      return false;
    }
  }

  static Future<int> _getAndroidVersion() async {
    // This is a simplified version - in practice you might want to use
    // device_info_plus package for accurate Android version detection
    return 30; // Default to API 30 for now
  }

  static Future<bool> _requestAndroid13Permissions() async {
    // For Android 13+, request granular media permissions
    final Map<Permission, PermissionStatus> permissions = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    // Check if at least photos permission is granted (most common use case)
    return permissions[Permission.photos]?.isGranted ?? false;
  }

  static Future<bool> _requestLegacyAndroidPermissions() async {
    // For older Android versions
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> _hasAndroid13Permissions() async {
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    
    // Return true if we have at least photos permission
    return photos.isGranted || videos.isGranted;
  }

  static Future<bool> _hasLegacyAndroidPermissions() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Show a permission rationale dialog to the user
  static Future<bool> shouldShowPermissionRationale() async {
    if (Platform.isAndroid) {
      if (await _getAndroidVersion() >= 33) {
        return await Permission.photos.shouldShowRequestRationale;
      } else {
        return await Permission.storage.shouldShowRequestRationale;
      }
    }
    return false;
  }

  /// Check if permission was permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      if (await _getAndroidVersion() >= 33) {
        final status = await Permission.photos.status;
        return status.isPermanentlyDenied;
      } else {
        final status = await Permission.storage.status;
        return status.isPermanentlyDenied;
      }
    }
    return false;
  }
}