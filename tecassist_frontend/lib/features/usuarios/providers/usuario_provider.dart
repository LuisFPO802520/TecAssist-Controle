import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../auth/models/usuario_model.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioService _service = UsuarioService();

  List<UsuarioModel> _usuarios = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  List<UsuarioModel> get usuarios => _usuarios;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  Future<void> carregarUsuarios() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _usuarios = await _service.listarUsuarios();
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);
    } catch (_) {
      _errorMessage = 'Erro ao carregar usuários.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<UsuarioModel?> buscarUsuario(int id) async {
    _errorMessage = null;

    try {
      return await _service.buscarUsuario(id);
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      notifyListeners();

      return null;
    } catch (_) {
      _errorMessage = 'Erro ao carregar usuário.';

      notifyListeners();

      return null;
    }
  }

  Future<bool> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    String? telefone,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.criarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        tipo: tipo,
        telefone: telefone,
      );

      await carregarUsuarios();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao cadastrar usuário.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> atualizarUsuario({
    required int id,
    required String nome,
    required String email,
    required String tipo,
    String? telefone,
    String? senha,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.atualizarUsuario(
        id: id,
        nome: nome,
        email: email,
        tipo: tipo,
        telefone: telefone,
        senha: senha,
      );

      await carregarUsuarios();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao atualizar usuário.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> excluirUsuario(int id) async {
    _errorMessage = null;

    try {
      await _service.excluirUsuario(id);

      await carregarUsuarios();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      notifyListeners();

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao excluir usuário.';

      notifyListeners();

      return false;
    }
  }

  void limparErro() {
    _errorMessage = null;

    notifyListeners();
  }

  String _obterMensagemErro(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Não foi possível conectar ao servidor.';
    }

    return 'Erro ao realizar a operação.';
  }
}
