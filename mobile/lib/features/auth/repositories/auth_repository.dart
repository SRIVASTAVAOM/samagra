import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient dioClient;
  final SecureStorageService storageService;

  AuthRepository({
    required this.dioClient,
    required this.storageService,
  });

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.login,
        data: {
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      final data = response.data['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Persist credentials in hardware secure storage
      await storageService.saveToken(token);
      await storageService.saveUserInfo(
        userId: user.id,
        role: user.primaryRole,
      );
      await storageService.saveUserData(user.toJson());

      return user;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMsg = e.response?.data['error'] ?? 'Authentication failed';
        throw Exception(errorMsg);
      }
      throw Exception('Network error. Unable to reach server.');
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    final token = await storageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    UserModel? cachedUser;
    final cachedUserData = await storageService.getUserData();
    if (cachedUserData != null) {
      try {
        cachedUser = UserModel.fromJson(cachedUserData);
      } catch (_) {}
    }

    if (cachedUser == null) {
      final role = await storageService.getActiveRole();
      final userId = await storageService.read('active_user_id');
      if (role != null && userId != null) {
        cachedUser = UserModel(
          id: userId,
          schoolId: '',
          identifier: userId,
          roles: [role],
        );
      }
    }

    try {
      final response = await dioClient.dio.get(ApiEndpoints.me);
      if (response.statusCode == 200 && response.data['data'] != null) {
        final freshUser = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
        await storageService.saveUserData(freshUser.toJson());
        await storageService.saveUserInfo(
          userId: freshUser.id,
          role: freshUser.primaryRole,
        );
        return freshUser;
      }
      return cachedUser;
    } on DioException catch (e) {
      // ONLY wipe storage if backend explicitly told us token is 401 Unauthorized
      if (e.response?.statusCode == 401) {
        await storageService.clearAll();
        return null;
      }
      // Network timeout, Render cold start, or temporary 5xx: keep session alive!
      return cachedUser;
    } catch (_) {
      // Offline or other exceptions: keep session alive!
      return cachedUser;
    }
  }

  Future<void> logout() async {
    await storageService.clearAll();
  }

  Future<Map<String, dynamic>> getForgotRequirements(String identifier) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.forgotPasswordRequirements,
        queryParameters: {'identifier': identifier.trim()},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Account lookup failed');
      }
      throw Exception('Network error. Unable to reach server.');
    }
  }

  Future<String> verifyForgotChallenge({
    required String identifier,
    String? phone,
    String? dob,
    String? email,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.forgotPasswordVerify,
        data: {
          'identifier': identifier.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          if (dob != null && dob.isNotEmpty) 'dob': dob.trim(),
          if (email != null && email.isNotEmpty) 'email': email.trim(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return data['resetToken'] as String;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Verification failed');
      }
      throw Exception('Network error. Unable to verify identity.');
    }
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await dioClient.dio.post(
        ApiEndpoints.forgotPasswordReset,
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Reset password failed');
      }
      throw Exception('Network error. Unable to reset password.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dioClient.dio.post(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Change password failed');
      }
      throw Exception('Network error. Unable to change password.');
    }
  }
}

