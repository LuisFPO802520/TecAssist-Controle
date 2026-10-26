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

  Future<void> cadastrarFuncionario({
    required String nome,
    required String email,
    required String senha,
    required String codigoCadastro,
    String? telefone,
  }) async {
    await ApiClient.dio.post(
      '/auth/register',
      data: {
        'nome': nome.trim(),
        'email': email.trim(),
        'senha': senha,
        'codigoCadastro': codigoCadastro.trim(),

        if (telefone != null && telefone.trim().isNotEmpty)
          'telefone': telefone.trim(),
      },
    );
  }
}
