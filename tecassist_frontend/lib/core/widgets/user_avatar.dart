import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../network/api_client.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? fotoPerfil;
  final Uint8List? previewBytes;
  final double iconSize;
  final double borderWidth;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const UserAvatar({
    super.key,
    required this.size,
    this.fotoPerfil,
    this.previewBytes,
    this.iconSize = 60,
    this.borderWidth = 0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.borderColor = const Color(0xFF999999),
    this.iconColor = const Color(0xFF9B9B9B),
  });

  String? _fotoUrl() {
    final caminho = fotoPerfil?.trim();

    if (caminho == null || caminho.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(caminho);
    if (uri != null && uri.hasScheme) {
      return caminho;
    }

    final baseUrl = ApiClient.dio.options.baseUrl;
    final base = Uri.tryParse(baseUrl);

    if (base == null || !base.hasScheme) {
      return null;
    }

    final caminhoNormalizado = caminho.startsWith('/') ? caminho : '/$caminho';

    return base.resolve(caminhoNormalizado).toString();
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = _fotoUrl();

    Widget conteudo;

    if (previewBytes != null) {
      conteudo = Image.memory(
        previewBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (fotoUrl != null) {
      conteudo = Image.network(
        fotoUrl,
        headers: const {'ngrok-skip-browser-warning': '1'},
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      conteudo = _placeholder();
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(child: conteudo),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(Icons.person_outline, size: iconSize, color: iconColor),
    );
  }
}
