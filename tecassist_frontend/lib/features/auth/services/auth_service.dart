import '../../../core/network/api_client.dart';
import '../models/login_response_model.dart';
import '../models/usuario_model.dart';

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

  Future<UsuarioModel> buscarPerfil() async {
    final response = await ApiClient.dio.get('/usuarios/perfil');
    return UsuarioModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<UsuarioModel> atualizarPerfil({
    required String nome,
    required String email,
    String? telefone,
    String? senhaAtual,
    String? novaSenha,
    String? fotoBase64,
    String? fotoMimeType,
  }) async {
    final dados = <String, dynamic>{
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone?.trim() ?? '',
    };

    if (novaSenha != null && novaSenha.isNotEmpty) {
      dados['senhaAtual'] = senhaAtual ?? '';
      dados['novaSenha'] = novaSenha;
    }

    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      dados['fotoBase64'] = fotoBase64;
      dados['fotoMimeType'] = fotoMimeType ?? 'image/jpeg';
    }

    final response = await ApiClient.dio.put('/usuarios/perfil', data: dados);

    return UsuarioModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
