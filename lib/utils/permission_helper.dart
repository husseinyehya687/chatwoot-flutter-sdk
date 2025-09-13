import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  /// Check and request storage permissions needed for file attachments
  static Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        print('Android API level: $androidVersion');
        
        // For Android 13+ (API 33+), we need different permissions
        if (androidVersion >= 33) {
          print('Using Android 13+ permission strategy');
          return await _requestAndroid13Permissions();
        } else {
          print('Using legacy Android permission strategy');
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
      // Instead of returning false, let's try to proceed anyway
      // Some file pickers might work without explicit permissions
      print('Proceeding without explicit permissions - file picker may handle it');
      return true;
    }
  }

  /// Alternative method that bypasses permission checks entirely
  /// Use this when permission handling is problematic
  static Future<bool> requestStoragePermissionsWithFallback() async {
    try {
      final result = await requestStoragePermissions();
      if (result) {
        return true;
      }
      
      // If permission request failed, try to proceed anyway
      print('Permission request failed, but attempting to proceed with file picker');
      return true;
    } catch (e) {
      print('Permission handling failed completely, falling back to no permission checks: $e');
      return true;
    }
  }

  /// Check if storage permissions are currently granted
  static Future<bool> hasStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        if (androidVersion >= 33) {
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
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      print('Error getting Android version: $e');
      return 30; // Default to API 30 as fallback
    }
  }

  static Future<bool> _requestAndroid13Permissions() async {
    try {
      // For Android 13+, try multiple strategies
      print('Requesting Android 13+ permissions...');
      
      // First try photos permission (most commonly used)
      final photosStatus = await Permission.photos.request();
      print('Photos permission status: $photosStatus');
      
      if (photosStatus.isGranted) {
        return true;
      }
      
      // If photos failed, try videos
      final videosStatus = await Permission.videos.request();  
      print('Videos permission status: $videosStatus');
      
      if (videosStatus.isGranted) {
        return true;
      }
      
      // As a last resort, try the old storage permission 
      // (some devices might still respect it)
      print('Trying legacy storage permission as fallback...');
      final storageStatus = await Permission.storage.request();
      print('Storage permission status: $storageStatus');
      
      return storageStatus.isGranted;
      
    } catch (e) {
      print('Error requesting Android 13+ permissions: $e');
      return false;
    }
  }

  static Future<bool> _requestLegacyAndroidPermissions() async {
    try {
      print('Requesting legacy Android permissions...');
      final status = await Permission.storage.request();
      print('Storage permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error requesting legacy permissions: $e');
      return false;
    }
  }

  static Future<bool> _hasAndroid13Permissions() async {
    try {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final storage = await Permission.storage.status;
      
      print('Permission status - Photos: $photos, Videos: $videos, Storage: $storage');
      
      // Return true if we have any relevant permission
      return photos.isGranted || videos.isGranted || storage.isGranted;
    } catch (e) {
      print('Error checking Android 13+ permissions: $e');
      return false;
    }
  }

  static Future<bool> _hasLegacyAndroidPermissions() async {
    try {
      final status = await Permission.storage.status;
      print('Legacy storage permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error checking legacy permissions: $e');
      return false;
    }
  }

  /// Show a permission rationale dialog to the user
  static Future<bool> shouldShowPermissionRationale() async {
    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        if (androidVersion >= 33) {
          // Check if any of the relevant permissions should show rationale
          final photosRationale = await Permission.photos.shouldShowRequestRationale;
          final videosRationale = await Permission.videos.shouldShowRequestRationale;
          final storageRationale = await Permission.storage.shouldShowRequestRationale;
          return photosRationale || videosRationale || storageRationale;
        } else {
          return await Permission.storage.shouldShowRequestRationale;
        }
      }
    } catch (e) {
      print('Error checking permission rationale: $e');
    }
    return false;
  }

  /// Check if permission was permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    try {
      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();
        if (androidVersion >= 33) {
          final photosStatus = await Permission.photos.status;
          final videosStatus = await Permission.videos.status;
          final storageStatus = await Permission.storage.status;
          
          // Return true if any relevant permission is permanently denied
          return photosStatus.isPermanentlyDenied || 
                 videosStatus.isPermanentlyDenied || 
                 storageStatus.isPermanentlyDenied;
        } else {
          final status = await Permission.storage.status;
          return status.isPermanentlyDenied;
        }
      }
    } catch (e) {
      print('Error checking permanent denial: $e');
    }
    return false;
  }
}