import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/usuarios/providers/usuario_provider.dart';
import 'features/clientes/providers/cliente_provider.dart';
import 'features/agendamentos/providers/agendamento_provider.dart';
import 'features/agendamentos/services/agendamento_service.dart';
import 'features/servicos/providers/servico_provider.dart';
import 'features/servicos/services/servico_service.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await dotenv.load(fileName: '.env');

  ApiClient.initialize();

  final authProvider = AuthProvider();

  await authProvider.carregarSessao();

  final router = AppRouter.create(authProvider);

  runApp(TecAssistApp(authProvider: authProvider, router: router));
}

class TecAssistApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const TecAssistApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),

        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(
          create: (_) => AgendamentoProvider(AgendamentoService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ServicoProvider(ServicoService()),
        ),
      ],

      child: MaterialApp.router(
        title: 'TecAssist',

        debugShowCheckedModeBanner: false,

        theme: AppTheme.light,

        routerConfig: router,
      ),
    );
  }
}
