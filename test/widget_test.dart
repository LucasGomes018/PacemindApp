// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pacemind/main.dart';
import 'package:pacemind/components/dashboard/stat_card.dart';
import 'package:pacemind/components/dashboard/weekly_goal_card.dart';
import 'package:pacemind/core/theme_provider.dart';
import 'package:pacemind/screens/configuracoes_screen.dart';
import 'package:pacemind/services/ia_treinador_service.dart';

void main() {
  test('não confunde "falar" com o assunto respiração', () async {
    final ia = IaTreinadorService(
      contextoInicial: ContextoAtleta(
        nome: 'Atleta',
        kmSemana: 0,
        metaSemanalKm: 30,
        treinosSemana: 0,
        paceReferenciaSegundos: 0,
        statusFadiga: 'Equilibrada',
        acwr: 1,
        metas: [],
        treinosRecentes: [],
        eventosInscritos: [],
      ),
    );

    final resposta = await ia.processarComandoOuPergunta(
      'Quero falar sobre tênis para corrida',
    );

    expect(resposta.mensagens.first, contains('equipamento ideal'));

    final respostaForaDaBase = await ia.processarComandoOuPergunta(
      'Como funciona a tributação sobre investimentos?',
    );

    expect(
      respostaForaDaBase.mensagens.first,
      contains('não tenho uma resposta específica'),
    );

    final respostaProva = await ia.processarComandoOuPergunta(
      'Como montar a estratégia de prova para uma meia maratona?',
    );
    expect(
      respostaProva.mensagens.first,
      contains('Comece de forma controlada'),
    );

    final respostaAquecimento = await ia.processarComandoOuPergunta(
      'Como deve ser meu aquecimento?',
    );
    expect(
      respostaAquecimento.mensagens.first,
      contains('comece alguns minutos'),
    );

    final respostaBicicleta = await ia.processarComandoOuPergunta(
      'Pedalar de bicicleta ajuda a complementar os treinos?',
    );
    expect(respostaBicicleta.mensagens.first, contains('Bicicleta'));

    final respostaDor = await ia.processarComandoOuPergunta(
      'Estou com dor no joelho depois de correr',
    );
    expect(respostaDor.mensagens.first, contains('Não consigo diagnosticar'));
  });

  testWidgets('exibe a tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Não tem uma conta? Cadastre-se'), findsOneWidget);
    expect(find.byIcon(Icons.email_rounded), findsOneWidget);
  });

  testWidgets('login não transborda em viewport compacto', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('card de métrica anima atualizações sem alterar o layout', (
    WidgetTester tester,
  ) async {
    Widget montarCard(String valor) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 130,
              child: StatCard(
                icon: Icons.route_rounded,
                title: 'Distância',
                value: valor,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(montarCard('8,2 km'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(montarCard('12,4 km'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('12,4 km'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('meta semanal destaca a conclusão com um troféu', (
    WidgetTester tester,
  ) async {
    Widget montarMeta(double kmAtual) {
      return MaterialApp(
        home: Scaffold(
          body: WeeklyGoalCard(
            kmAtual: kmAtual,
            meta: {'titulo': 'Meta', 'tipo': 'km', 'objetivo': 5},
          ),
        ),
      );
    }

    await tester.pumpWidget(montarMeta(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(montarMeta(5));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('configurações cabem no celular e abrem os fluxos', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(home: ConfiguracoesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Meta semanal'), findsOneWidget);
    expect(find.text('Receber notificações'), findsOneWidget);
    expect(find.text('Abrir treinador'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Meta semanal'));
    await tester.tap(find.text('Meta semanal'));
    await tester.pumpAndSettle();
    expect(find.text('Distância semanal'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Limpar histórico'),
      find.byType(ListView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar histórico'));
    await tester.pumpAndSettle();
    expect(
      find.text('As mensagens da conversa serão excluídas permanentemente.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
