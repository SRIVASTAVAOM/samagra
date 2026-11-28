import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/academic_material_model.dart';

class MaterialsRepository {
  final DioClient _client;
  final Dio _storageDio;

  MaterialsRepository(this._client, {Dio? storageDio, Dio? s3Dio})
      : _storageDio = storageDio ?? s3Dio ?? Dio();

  Future<List<AcademicMaterialModel>> getClassMaterials(
    String classId,
    String subjectId, {
    String? sectionId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.classMaterials(classId, subjectId, sectionId: sectionId),
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => AcademicMaterialModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PresignedUploadResponse> initiatePresignedUpload({
    required String classId,
    String? sectionId,
    required String subjectId,
    required String title,
    String? description,
    String? materialType,
    required String fileName,
    required int fileSizeBytes,
    required String contentType,
  }) async {
    final payload = <String, dynamic>{
      'classId': classId,
      'subjectId': subjectId,
      'title': title,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'contentType': contentType,
    };
    if (sectionId != null) payload['sectionId'] = sectionId;
    if (description != null) payload['description'] = description;
    if (materialType != null && materialType.isNotEmpty) {
      payload['materialType'] = materialType;
    }

    final response = await _client.post(
      ApiEndpoints.presignedUploadUrl,
      data: payload,
    );
    return PresignedUploadResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> uploadFileDirectly(
    String uploadUrl,
    List<int> fileBytes,
    String contentType, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final uploadUri = Uri.tryParse(uploadUrl);
    final apiUri = Uri.tryParse(_client.dio.options.baseUrl);
    final isBackendFallback =
        uploadUrl.contains('/api/v1/materials/upload') ||
        (uploadUri != null &&
            apiUri != null &&
            uploadUri.host.isNotEmpty &&
            uploadUri.host == apiUri.host);

    if (isBackendFallback) {
      await _client.dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length,
          },
        ),
        onSendProgress: onProgress,
      );
      return;
    }

    await _storageDio.put(
      uploadUrl,
      data: fileBytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length,
        },
      ),
      onSendProgress: onProgress,
    );
  }

  /// Backward compatible alias for uploadFileDirectly
  Future<void> uploadFileDirectlyToS3(
    String uploadUrl,
    List<int> fileBytes,
    String contentType, {
    void Function(int sent, int total)? onProgress,
  }) => uploadFileDirectly(uploadUrl, fileBytes, contentType, onProgress: onProgress);

  Future<AcademicMaterialModel> verifyUpload(String materialId) async {
    final response = await _client.post(ApiEndpoints.verifyUpload(materialId));
    return AcademicMaterialModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PresignedDownloadResponse> getDownloadUrl(String materialId) async {
    final response = await _client.get(ApiEndpoints.materialDownloadUrl(materialId));
    return PresignedDownloadResponse.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
