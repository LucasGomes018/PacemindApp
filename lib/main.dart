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
import 'screens/zonas_screen.dart';
import 'screens/evolucao_screen.dart';
import 'screens/overtraining_screen.dart';
import 'screens/execucoes_screen.dart';
import 'screens/ficha_screen.dart';
import 'screens/exames_screen.dart';
import 'screens/relatorios_screen.dart';
import 'services/background_tracking_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme_provider.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificacaoService.inicializar();
  } catch (_) {}

  try {
    await BackgroundTrackingService.initialize();
  } catch (_) {}

  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (_) {}

  String? token;
  var corridaAtiva = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    corridaAtiva = prefs.getBool('corrida_ativa') ?? false;
  } catch (_) {}

  runApp(
    MyApp(
      isAuthenticated: token != null && token.isNotEmpty,
      initialPage: corridaAtiva ? 1 : 0,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  final int initialPage;

  const MyApp({super.key, this.isAuthenticated = false, this.initialPage = 0});

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
            themeAnimationDuration: const Duration(milliseconds: 400),
            themeAnimationCurve: Curves.easeInOut,

            initialRoute: isAuthenticated ? "/home" : "/",

            routes: {
              "/": (context) => const LoginPage(),
              "/cadastro": (context) => const CadastroPage(),
              "/home": (context) => DashboardPage(initialPage: initialPage),
              "/notificacoes": (context) => const NotificationsPage(),
              "/eventos": (context) => const EventosPage(),
              "/treinos": (context) => const TreinosPage(),
              "/metas": (context) => const MetasPage(),
              "/recomendacoes": (context) => const RecomendacoesPage(),
              "/configuracoes": (context) => const ConfiguracoesPage(),
              "/testes": (context) => const TestesPage(),
              "/questionarios": (context) => const QuestionariosPage(),
              "/zonas": (context) => const ZonasPage(),
              "/evolucao": (context) => const EvolucaoPage(),
              "/overtraining": (context) => const OvertrainingPage(),
              "/execucoes": (context) => const ExecucoesPage(),
              "/ficha": (context) => const FichaPage(),
              "/exames": (context) => const ExamesPage(),
              "/relatorios": (context) => const RelatoriosPage(),
            },
          );
        },
      ),
    );
  }
}
