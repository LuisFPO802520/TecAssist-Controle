import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/cliente_model.dart';
import '../services/cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _service = ClienteService();

  List<ClienteModel> _clientes = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  List<ClienteModel> get clientes => _clientes;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  Future<void> carregarClientes() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _clientes = await _service.listarClientes();
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);
    } catch (_) {
      _errorMessage = 'Erro ao carregar clientes.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<ClienteModel?> buscarCliente(int id) async {
    _errorMessage = null;

    try {
      return await _service.buscarCliente(id);
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      notifyListeners();

      return null;
    } catch (_) {
      _errorMessage = 'Erro ao carregar cliente.';

      notifyListeners();

      return null;
    }
  }

  Future<bool> criarCliente({
    required String nome,
    required String telefone,
    String? email,
    String? endereco,
    String? cpf,
    String? observacoes,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.criarCliente(
        nome: nome,
        telefone: telefone,
        email: email,
        endereco: endereco,
        cpf: cpf,
        observacoes: observacoes,
      );

      await carregarClientes();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao cadastrar cliente.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> atualizarCliente({
    required int id,
    required String nome,
    required String telefone,
    String? email,
    String? endereco,
    String? cpf,
    String? observacoes,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.atualizarCliente(
        id: id,
        nome: nome,
        telefone: telefone,
        email: email,
        endereco: endereco,
        cpf: cpf,
        observacoes: observacoes,
      );

      await carregarClientes();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao atualizar cliente.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> excluirCliente(int id) async {
    _errorMessage = null;

    try {
      await _service.excluirCliente(id);

      await carregarClientes();

      return true;
    } on DioException catch (error) {
      _errorMessage = _obterMensagemErro(error);

      notifyListeners();

      return false;
    } catch (_) {
      _errorMessage = 'Erro ao excluir cliente.';

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
