import 'usuario_model.dart';

class LoginResponseModel {
  final UsuarioModel usuario;
  final String token;

  LoginResponseModel({required this.usuario, required this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      usuario: UsuarioModel.fromJson(json['usuario']),
      token: json['token'],
    );
  }
}
