import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_response.dart';
import '../models/form_models.dart';
import 'api_client.dart';
import 'offline_support.dart';

final fileUploadRepositoryProvider = Provider<FileUploadRepository>((ref) {
  return FileUploadRepository(ref.read(dioProvider));
});

class FileUploadRepository {
  FileUploadRepository(this._dio);

  final Dio _dio;

  Future<UploadedFileMetadata> uploadFile({
    required List<int> bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/files/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => UploadedFileMetadata.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo subir el archivo.');
    }

    return envelope.data;
  }
}
