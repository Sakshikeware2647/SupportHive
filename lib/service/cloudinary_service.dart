// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';

// /// Result object returned by every Cloudinary upload.
// class CloudinaryUploadResult {
//   final String secureUrl;
//   final String publicId;
//   final int duration; // seconds (for video/audio)
//   final String resourceType;

//   const CloudinaryUploadResult({
//     required this.secureUrl,
//     required this.publicId,
//     required this.duration,
//     required this.resourceType,
//   });
// }

// class CloudinaryService {
//   // ─── Replace with your real Cloudinary credentials ──────────────────────────
//   static const String _cloudName = 'diyb2otzj';
//   static const String _apiKey = 	
// "953982173421429";
//   static const String _apiSecret = 'b6lHbk4Pgw_T1NaSzp1_o36gomM';
//   static const String _uploadPreset = 'supporthive_profiles'; // unsigned preset
//   // ─────────────────────────────────────────────────────────────────────────────

//   static final Dio _dio = Dio(BaseOptions(
//     connectTimeout: const Duration(seconds: 30),
//     receiveTimeout: const Duration(minutes: 5), // large files take time
//   ));

//   // ── Private helper ──────────────────────────────────────────────────────────

//   /// Generates a SHA-1 signature for authenticated (signed) uploads.
//   static String _generateSignature(
//       Map<String, String> params, String apiSecret) {
//     final sorted = params.entries.toList()
//       ..sort((a, b) => a.key.compareTo(b.key));
//     final paramString = sorted.map((e) => '${e.key}=${e.value}').join('&');
//     final toSign = '$paramString$apiSecret';
//     final bytes = utf8.encode(toSign);
//     return sha1.convert(bytes).toString();
//   }

//   // ── Public API ──────────────────────────────────────────────────────────────

//   /// Uploads a video or audio file to Cloudinary.
//   ///
//   /// [file]           – the local file to upload.
//   /// [resourceType]   – 'video' (handles both video and audio on Cloudinary).
//   /// [onProgress]     – optional progress callback (0.0 → 1.0).
//   static Future<CloudinaryUploadResult> uploadMedia(
//     File file, {
//     String resourceType = 'video',
//     void Function(double progress)? onProgress,
//   }) async {
//     final url =
//         'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload';

//     final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

//     final params = {
//       'timestamp': timestamp,
//       'upload_preset': _uploadPreset,
//     };

//     final signature = _generateSignature(params, _apiSecret);

//     final formData = FormData.fromMap({
//       'file': await MultipartFile.fromFile(file.path),
//       'api_key': _apiKey,
//       'timestamp': timestamp,
//       'upload_preset': _uploadPreset,
//       'signature': signature,
//     });

//     try {
//       final response = await _dio.post(
//         url,
//         data: formData,
//         onSendProgress: (sent, total) {
//           if (total > 0 && onProgress != null) {
//             onProgress(sent / total);
//           }
//         },
//       );

//       final data = response.data as Map<String, dynamic>;

//       return CloudinaryUploadResult(
//         secureUrl: data['secure_url'] as String,
//         publicId: data['public_id'] as String,
//         duration: (data['duration'] as num?)?.toInt() ?? 0,
//         resourceType: data['resource_type'] as String? ?? resourceType,
//       );
//     } on DioException catch (e) {
//       final message = e.response?.data?.toString() ?? e.message;
//       throw Exception('Cloudinary upload failed: $message');
//     }
//   }

//   /// Deletes a resource from Cloudinary (e.g., when a podcast is removed).
//   static Future<void> deleteMedia(String publicId,
//       {String resourceType = 'video'}) async {
//     final url =
//         'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy';

//     final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
//     final params = {'public_id': publicId, 'timestamp': timestamp};
//     final signature = _generateSignature(params, _apiSecret);

//     await _dio.post(url, data: {
//       'public_id': publicId,
//       'api_key': _apiKey,
//       'timestamp': timestamp,
//       'signature': signature,
//     });
//   }
// }