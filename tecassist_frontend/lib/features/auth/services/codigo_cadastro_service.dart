import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class CodigoCadastroService {
  static Future<Map<String, dynamic>> gerarCodigo({
    required int limiteUsos,
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/codigo-cadastro',
      data: {'limiteUsos': limiteUsos},
    );

    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>?> consultarCodigo() async {
    try {
      final response = await ApiClient.dio.get('/auth/codigo-cadastro');

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }
}
