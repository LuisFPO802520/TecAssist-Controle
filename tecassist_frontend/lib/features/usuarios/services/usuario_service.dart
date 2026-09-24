import '../../../core/network/api_client.dart';
import '../../auth/models/usuario_model.dart';

class UsuarioService {
  Future<List<UsuarioModel>> listarUsuarios() async {
    final response = await ApiClient.dio.get('/usuarios');

    final List<dynamic> dados = response.data;

    return dados.map((json) => UsuarioModel.fromJson(json)).toList();
  }

  Future<UsuarioModel> buscarUsuario(int id) async {
    final response = await ApiClient.dio.get('/usuarios/$id');

    return UsuarioModel.fromJson(response.data);
  }

  Future<UsuarioModel> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    String? telefone,
  }) async {
    final response = await ApiClient.dio.post(
      '/usuarios',
      data: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'tipo': tipo,
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      },
    );

    return UsuarioModel.fromJson(response.data);
  }

  Future<UsuarioModel> atualizarUsuario({
    required int id,
    required String nome,
    required String email,
    required String tipo,
    String? telefone,
    String? senha,
  }) async {
    final Map<String, dynamic> dados = {
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'telefone': telefone?.isNotEmpty == true ? telefone : null,
    };

    if (senha != null && senha.isNotEmpty) {
      dados['senha'] = senha;
    }

    final response = await ApiClient.dio.put('/usuarios/$id', data: dados);

    return UsuarioModel.fromJson(response.data);
  }

  Future<void> excluirUsuario(int id) async {
    await ApiClient.dio.delete('/usuarios/$id');
  }
}
