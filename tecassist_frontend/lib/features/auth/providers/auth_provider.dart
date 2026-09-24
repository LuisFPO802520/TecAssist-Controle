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

  String? _errorMessage;

  UsuarioModel? get usuario => _usuario;

  String? get token => _token;

  bool get isLoading => _isLoading;

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

      if (error.response?.data is Map<String, dynamic>) {
        _errorMessage =
            error.response?.data['error'] ?? 'Erro ao realizar login';
      } else {
        _errorMessage = 'Não foi possível conectar ao servidor';
      }

      notifyListeners();

      return false;
    } catch (error) {
      _isLoading = false;

      _errorMessage = 'Erro inesperado ao realizar login';

      notifyListeners();

      return false;
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
}
