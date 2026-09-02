import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cadastro_screen.dart';
import 'services/notificacao_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/evento_screen.dart';
import 'screens/treinos_screen.dart';
import 'screens/metas_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'screens/recomendacoes_screen.dart';
import 'screens/testes_screen.dart';
import 'screens/questionarios_screen.dart';
import 'services/background_tracking_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificacaoService.inicializar();
  await BackgroundTrackingService.initialize();
  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "PaceMind",

            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.currentTheme,

            initialRoute: "/",

            routes: {
              "/": (context) => const LoginPage(),
              "/cadastro": (context) => const CadastroPage(),
              "/home": (context) => const DashboardPage(),
              "/notificacoes": (context) => const NotificationsPage(),
              "/eventos": (context) => const EventosPage(),
              "/treinos": (context) => const TreinosPage(),
              "/metas": (context) => const MetasPage(),
              "/recomendacoes": (context) => const RecomendacoesPage(),
              "/configuracoes": (context) => const ConfiguracoesPage(),
              "/testes": (context) => const TestesPage(),
              "/questionarios": (context) => const QuestionariosPage(),
            },
          );
        },
      ),
    );
  }
}
