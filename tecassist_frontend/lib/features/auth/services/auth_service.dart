import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class AuthService {
  Future<Response> login({required String email, required String senha}) async {
    return await ApiClient.dio.post(
      "/auth/login",
      data: {"email": email, "senha": senha},
    );
  }
}
