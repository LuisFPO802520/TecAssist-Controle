import '../../../core/network/api_client.dart';
import '../models/login_response_model.dart';

class AuthService {
  Future<LoginResponseModel> login({
    required String email,
    required String senha,
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'senha': senha},
    );

    return LoginResponseModel.fromJson(response.data);
  }
}
