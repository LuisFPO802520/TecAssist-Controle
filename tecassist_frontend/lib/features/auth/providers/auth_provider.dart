import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UsuarioModel? _usuario;
  String? _token;
  bool _isLoading = false;
  bool _isSavingProfile = false;
  String? _errorMessage;

  UsuarioModel? get usuario => _usuario;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isSavingProfile => _isSavingProfile;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _usuario?.tipo == 'ADMIN';

  Future<bool> login({required String email, required String senha}) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final resultado = await _authService.login(
        email: email.trim(),
        senha: senha,
      );

      _usuario = resultado.usuario;
      _token = resultado.token;

      await StorageService.saveToken(resultado.token);
      await StorageService.saveUsuario(resultado.usuario.toJson());

      _isLoading = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _isLoading = false;
      _errorMessage = _mensagemErro(error, 'Erro ao realizar login.');

      notifyListeners();

      return false;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Erro inesperado ao realizar login.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> cadastrarFuncionario({
    required String nome,
    required String email,
    required String senha,
    required String codigoCadastro,
    String? telefone,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _authService.cadastrarFuncionario(
        nome: nome,
        email: email,
        senha: senha,
        codigoCadastro: codigoCadastro,
        telefone: telefone,
      );

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(
        error,
        'Não foi possível realizar o cadastro.',
      );
      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao realizar cadastro.';

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<void> carregarSessao() async {
    final tokenSalvo = await StorageService.getToken();
    final usuarioSalvo = await StorageService.getUsuario();

    if (tokenSalvo == null || usuarioSalvo == null) {
      return;
    }

    _token = tokenSalvo;
    _usuario = UsuarioModel.fromJson(usuarioSalvo);

    notifyListeners();
  }

  Future<bool> recarregarPerfil() async {
    _errorMessage = null;

    try {
      final usuarioAtualizado = await _authService.buscarPerfil();
      _usuario = usuarioAtualizado;
      await StorageService.saveUsuario(usuarioAtualizado.toJson());
      notifyListeners();
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(
        error,
        'Não foi possível atualizar os dados do perfil.',
      );
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao carregar as informações do perfil.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarPerfil({
    required String nome,
    required String email,
    String? telefone,
    String? senhaAtual,
    String? novaSenha,
    String? fotoBase64,
    String? fotoMimeType,
  }) async {
    _isSavingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usuarioAtualizado = await _authService.atualizarPerfil(
        nome: nome,
        email: email,
        telefone: telefone,
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
        fotoBase64: fotoBase64,
        fotoMimeType: fotoMimeType,
      );

      _usuario = usuarioAtualizado;
      await StorageService.saveUsuario(usuarioAtualizado.toJson());
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(
        error,
        'Não foi possível salvar as informações.',
      );
      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao atualizar o perfil.';
      return false;
    } finally {
      _isSavingProfile = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageService.clearAuth();

    _token = null;
    _usuario = null;
    _errorMessage = null;

    notifyListeners();
  }

  void limparErro() {
    _errorMessage = null;

    notifyListeners();
  }

  String _mensagemErro(DioException error, String padrao) {
    final data = error.response?.data;

    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Não foi possível conectar ao servidor.';
    }

    return padrao;
  }
}
