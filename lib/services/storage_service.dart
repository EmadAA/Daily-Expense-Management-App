import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../supabase_config.dart';

class StorageService {
  // Convert image to compressed base64 — no upload needed
  Future<String?> imageToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize to max 400px wide
      final resized = img.copyResize(decoded, width: 400);

      // Compress to JPEG at 60% quality
      final compressed = img.encodeJpg(resized, quality: 60);

      // Return as base64 string
      return base64Encode(compressed);
    } catch (e) {
      return null;
    }
  }
}

Future<void> deleteReceipt(String url) async {
  try {
    // Extract file path from URL
    final uri = Uri.parse(url);
    final path =
        uri.pathSegments.skipWhile((s) => s != 'receipts').skip(1).join('/');
    await supabase.storage.from('receipts').remove([path]);
  } catch (_) {}
}
