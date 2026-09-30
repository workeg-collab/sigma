import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خدمة الاتصال بـ Supabase لمشروع سيجما (Sigma)
class SupabaseConfig {
  static const String baseUrl = 'https://supabase.pom-hosting.online';
  static const String restUrl = '$baseUrl/rest/v1';
  static const String storageUrl = '$baseUrl/storage/v1';
  static const String bucketName = 'sigma';
  
  // المفتاح العام للتطبيق
  static const String anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc5MDczMzk2MCwiZXhwIjo0OTQ2NDA3NTYwLCJyb2xlIjoiYW5vbiJ9.YpWkajAaHKnpniKxFTRBM8Km9vHkryfwinK9lyAKiq8';

  // مخطط قاعدة البيانات المخصص لسيجما
  static const String schema = 'sigma';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// فحص الاتصال بسيرفر Supabase
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.restUrl}/'),
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error connecting to Supabase: $e');
      return false;
    }
  }

  /// الحصول على رابط مباشر عام لملف في مستودع سيجما (Storage)
  String getPublicFileUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${SupabaseConfig.storageUrl}/object/public/${SupabaseConfig.bucketName}/$cleanPath';
  }

  /// رفع ملف إلى مستودع سيجما (فواتير، مستندات، شعارات)
  Future<String?> uploadFile({
    required String filePath,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
      final uri = Uri.parse(
        '${SupabaseConfig.storageUrl}/object/${SupabaseConfig.bucketName}/$cleanPath',
      );

      final response = await http.post(
        uri,
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'Content-Type': contentType,
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return getPublicFileUrl(cleanPath);
      } else {
        debugPrint('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading file to Supabase: $e');
      return null;
    }
  }
}
