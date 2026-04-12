import '../models/user_model.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<List<UserModel>> getUsers({
    final String? role,
    final int page = 1,
    final int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (role != null && role.isNotEmpty) {
      params['role'] = role;
    }

    final response = await _apiService.get('/admin/users', queryParams: params);
    final users = (response['data'] ?? []) as List<dynamic>;
    return users
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<UserModel> verifyFarmer(
    final String userId, {
    final bool override = false,
    final String? overrideReason,
  }) async {
    final response = await _apiService.post(
      '/admin/users/$userId/verify',
      body: {
        'override': override,
        if (overrideReason != null && overrideReason.trim().isNotEmpty)
          'overrideReason': overrideReason.trim(),
      },
    );

    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> suspendUser(final String userId, {required final String reason}) async {
    await _apiService.post(
      '/admin/users/$userId/suspend',
      body: {'reason': reason},
    );
  }

  Future<void> deleteUser(final String userId) async {
    await _apiService.delete('/admin/users/$userId');
  }
}
