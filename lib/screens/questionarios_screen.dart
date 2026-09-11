import 'package:flutter/material.dart';
import '../core/api.dart';

class QuestionariosPage extends StatefulWidget {
  const QuestionariosPage({super.key});

  @override
  State<QuestionariosPage> createState() => _QuestionariosPageState();
}

class _QuestionariosPageState extends State<QuestionariosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = false;
  bool enviando = false;
  List<dynamic> historicoQuestionarios = [];

  // Estado ACQ-5 (0 a 6, default 0 = ótimo/sem sintomas)
  final Map<String, int> respostasACQ5 = {
    'q1': 0,
    'q2': 0,
    'q3': 0,
    'q4': 0,
    'q5': 0,
  };

  // Estado MiniAQLQ (15 perguntas, 1 a 7, default 7 = excelente/nunca limitado)
  final Map<String, int> respostasMiniAQLQ = Map.fromIterable(
    List.generate(15, (index) => 'q${index + 1}'),
    value: (_) => 7,
  );

  // Perguntas oficiais ACQ-5
  final List<Map<String, dynamic>> itensACQ5 = [
    {
      'titulo': 'Acordar durante a noite',
      'pergunta':
          'Em média, durante a última semana, com que frequência você acordou durante a noite por causa da sua asma?',
      'opcoes': [
        '0 - Nunca',
        '1 - Quase nunca',
        '2 - Algumas vezes',
        '3 - Várias vezes',
        '4 - Muitas vezes',
        '5 - Muitíssimas vezes',
        '6 - Não consegui dormir por causa da asma',
      ],
      'icone': Icons.nights_stay_rounded,
    },
    {
      'titulo': 'Sintomas ao acordar pela manhã',
      'pergunta':
          'Em média, durante a última semana, como estavam os sintomas da sua asma ao acordar pela manhã?',
      'opcoes': [
        '0 - Nenhum sintoma',
        '1 - Sintomas muito leves',
        '2 - Sintomas leves',
        '3 - Sintomas moderados',
        '4 - Sintomas bastante graves',
        '5 - Sintomas graves',
        '6 - Sintomas muito graves',
      ],
      'icone': Icons.wb_sunny_rounded,
    },
    {
      'titulo': 'Limitação de atividades diárias',
      'pergunta':
          'Em geral, durante a última semana, o quanto sua asma limitou suas atividades?',
      'opcoes': [
        '0 - Não limitou em nada',
        '1 - Limitou muito pouco',
        '2 - Limitou um pouco',
        '3 - Limitou moderadamente',
        '4 - Limitou bastante',
        '5 - Limitou extremamente',
        '6 - Limitou totalmente',
      ],
      'icone': Icons.fitness_center_rounded,
    },
    {
      'titulo': 'Falta de ar (dispneia)',
      'pergunta':
          'Em geral, durante a última semana, quanta falta de ar você sentiu por causa da sua asma?',
      'opcoes': [
        '0 - Nenhuma',
        '1 - Muito pouca',
        '2 - Pouca',
        '3 - Moderada',
        '4 - Bastante',
        '5 - Muita',
        '6 - Muitíssima',
      ],
      'icone': Icons.air_rounded,
    },
    {
      'titulo': 'Chiado no peito (pieira)',
      'pergunta':
          'Em geral, durante a última semana, quanto tempo você apresentou chiado no peito?',
      'opcoes': [
        '0 - Em nenhum momento',
        '1 - Quase nunca',
        '2 - Em uma pequena parte do tempo',
        '3 - Em uma quantidade moderada do tempo',
        '4 - Em grande parte do tempo',
        '5 - Na maior parte do tempo',
        '6 - Durante todo o tempo',
      ],
      'icone': Icons.monitor_heart_rounded,
    },
  ];

  // Opções MiniAQLQ Parte 1 (escala 1 a 7)
  final List<String> opcoesMiniAQLQParte1 = [
    '1 - Sempre',
    '2 - Quase sempre',
    '3 - Bastante tempo',
    '4 - Algum tempo',
    '5 - Pouco tempo',
    '6 - Quase nunca',
    '7 - Nunca',
  ];

  // Opções MiniAQLQ Parte 2 (escala 1 a 7)
  final List<String> opcoesMiniAQLQParte2 = [
    '1 - Completamente limitado(a)',
    '2 - Extremamente limitado(a)',
    '3 - Muito limitado(a)',
    '4 - Moderadamente limitado(a)',
    '5 - Pouco limitado(a)',
    '6 - Muito pouco limitado(a)',
    '7 - Nada limitado(a)',
  ];

  // Perguntas Parte 1 (1 a 11)
  final List<String> perguntasMiniAQLQParte1 = [
    'Sentiu falta de ar por causa da asma?',
    'Sentiu-se incomodado(a) por, ou teve de evitar, um ambiente com pó?',
    'Teve um sentimento de frustração, tristeza ou revolta por causa da asma?',
    'Sentiu-se incomodado(a) por ter tosse?',
    'Teve medo ou receio de não ter à mão a medicação para a asma?',
    'Teve uma sensação de aperto no peito ou peso no peito?',
    'Sentiu-se incomodado(a) por, ou teve de evitar, um ambiente com fumo de tabaco?',
    'Teve dificuldade em dormir bem de noite por ter asma?',
    'Sentiu-se preocupado(a) por ter asma?',
    'Sentiu pieira/chiado no peito?',
    'Sentiu-se incomodado(a) por, ou teve de evitar sair por causa do tempo, clima ou poluição do ar?',
  ];

  // Perguntas Parte 2 (12 a 15)
  final List<String> perguntasMiniAQLQParte2 = [
    'Atividades extenuantes, como ter de se apressar, fazer ginástica, correr pela escada acima ou praticar desporto.',
    'Atividades moderadas, como andar a pé, fazer o trabalho doméstico, tratar do jardim/quintal, ir às compras ou subir escadas.',
    'Atividades sociais, como falar, brincar com crianças ou pegá-las ao colo, visitar amigos ou família.',
    'Atividades relacionadas com a sua profissão ou tarefas que desempenha na maior parte dos dias.',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarHistorico();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    if (!mounted) return;
    setState(() => carregando = true);
    try {
      final list = await Api.listarQuestionarios();
      if (!mounted) return;
      setState(() {
        historicoQuestionarios = list;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  Future<void> _salvarACQ5() async {
    setState(() => enviando = true);
    try {
      await Api.salvarQuestionario(tipo: 'acq5', respostas: respostasACQ5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Questionário ACQ-5 enviado com sucesso!"),
              ],
            ),
          ),
        );
      }
      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text("Erro ao enviar: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Future<void> _salvarMiniAQLQ() async {
    setState(() => enviando = true);
    try {
      await Api.salvarQuestionario(
        tipo: 'miniaqlq',
        respostas: respostasMiniAQLQ,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Questionário MiniAQLQ enviado com sucesso!"),
              ],
            ),
          ),
        );
      }
      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text("Erro ao enviar: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Future<void> _deletarQuestionario(String id) async {
    try {
      await Api.deletarQuestionario(id);
      await _carregarHistorico();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Questionário excluído."),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Erro ao deletar questionário."),
          ),
        );
      }
    }
  }

  double _calcularMediaACQ5() {
    final vals = respostasACQ5.values;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double _calcularMediaMiniAQLQ() {
    final vals = respostasMiniAQLQ.values;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Color _corParaACQ5(int valor) {
    if (valor <= 1) return const Color(0xFF10B981); // Verde
    if (valor <= 3) return const Color(0xFFF59E0B); // Amarelo/Laranja
    return const Color(0xFFEF4444); // Vermelho
  }

  Color _corParaMiniAQLQ(int valor) {
    if (valor <= 2) return const Color(0xFFEF4444); // Vermelho
    if (valor <= 4) return const Color(0xFFF59E0B); // Laranja
    if (valor <= 5) return const Color(0xFF3B82F6); // Azul
    return const Color(0xFF10B981); // Verde
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Questionários de Asma",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.shield_outlined),
              text: "Controle (ACQ-5)",
            ),
            Tab(
              icon: Icon(Icons.favorite_outline),
              text: "Qualidade de Vida (MiniAQLQ)",
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Banner de Orientação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [const Color(0xFF0066FF), const Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monitoramento Respiratório",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Responda semanalmente para personalizar a intensidade e segurança dos seus treinos de corrida.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Seletor de Abas dinâmico
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildConteudoACQ5(isDark, cardBg, txtColor);
              } else {
                return _buildConteudoMiniAQLQ(isDark, cardBg, txtColor);
              }
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Histórico de Questionários
          _buildHistoricoSection(isDark, cardBg, txtColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // 🩺 ABA ACQ-5
  // ==========================================
  Widget _buildConteudoACQ5(bool isDark, Color cardBg, Color txtColor) {
    final media = _calcularMediaACQ5();
    String status = "Asma Bem Controlada";
    Color statusColor = const Color(0xFF10B981);
    IconData statusIcon = Icons.check_circle_rounded;
    String recomendacao =
        "Ótimo controle! Você está liberado(a) para seguir o plano de treino completo de corrida.";

    if (media >= 0.75 && media <= 1.5) {
      status = "Asma Parcialmente Controlada";
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber_rounded;
      recomendacao =
          "Atenção aos treinos de alta intensidade (Zonas 4 e 5). Tenha o broncodilatador sempre à mão.";
    } else if (media > 1.5) {
      status = "Asma Não Controlada";
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_outline_rounded;
      recomendacao =
          "Evite treinos extenuantes e consulte seu pneumologista ou médico antes de treinar forte.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de Diagnóstico do ACQ-5
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Média Atual: ${media.toStringAsFixed(2)} pts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: txtColor,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (media / 6.0).clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                borderRadius: BorderRadius.circular(10),
                minHeight: 7,
              ),
              const SizedBox(height: 10),
              Text(
                recomendacao,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Perguntas sobre a última semana (ACQ-5)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: txtColor,
          ),
        ),
        const SizedBox(height: 12),

        // Lista de 5 Perguntas ACQ-5
        ...List.generate(itensACQ5.length, (index) {
          final item = itensACQ5[index];
          final key = 'q${index + 1}';
          final valorSelecionado = respostasACQ5[key] ?? 0;
          final opcoes = item['opcoes'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.12),
                      child: Icon(
                        item['icone'] as IconData,
                        color: const Color(0xFF0066FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Q${index + 1}. ${item['titulo']}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['pergunta'] as String,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 14),

                // Seletor horizontal de 0 a 6 responsivo
                LayoutBuilder(
                  builder: (context, box) {
                    final buttonWidth = (box.maxWidth - 24) / 7;
                    final useScroll = buttonWidth < 36;
                    final buttons = List.generate(7, (numOption) {
                      final selecionado = valorSelecionado == numOption;
                      final cor = _corParaACQ5(numOption);

                      Widget btn = GestureDetector(
                        onTap: () {
                          setState(() {
                            respostasACQ5[key] = numOption;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: useScroll ? 44 : null,
                          decoration: BoxDecoration(
                            color: selecionado
                                ? cor
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selecionado
                                  ? cor
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1)),
                              width: selecionado ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "$numOption",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: selecionado
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );

                      return useScroll ? btn : Expanded(child: btn);
                    });

                    if (useScroll) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: buttons),
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: buttons,
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Legenda da opção selecionada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _corParaACQ5(valorSelecionado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    opcoes[valorSelecionado],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _corParaACQ5(valorSelecionado),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        // Botão Salvar
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: enviando ? null : _salvarACQ5,
            icon: enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              enviando ? "Enviando..." : "Salvar Questionário ACQ-5",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 💖 ABA MiniAQLQ
  // ==========================================
  Widget _buildConteudoMiniAQLQ(bool isDark, Color cardBg, Color txtColor) {
    final media = _calcularMediaMiniAQLQ();
    String status = "Excelente Qualidade de Vida";
    Color statusColor = const Color(0xFF10B981);
    IconData statusIcon = Icons.sentiment_very_satisfied_rounded;

    if (media < 4.0) {
      status = "Baixa Qualidade de Vida";
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.sentiment_very_dissatisfied_rounded;
    } else if (media < 6.0) {
      status = "Boa Qualidade de Vida";
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.sentiment_satisfied_alt_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de Diagnóstico do MiniAQLQ
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Score MiniAQLQ: ${media.toStringAsFixed(2)} / 7.0 pts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: txtColor,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (media / 7.0).clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                borderRadius: BorderRadius.circular(10),
                minHeight: 7,
              ),
              const SizedBox(height: 8),
              Text(
                "Considerando as últimas 2 semanas. Quanto mais próximo de 7.0, melhor sua qualidade de vida.",
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Cabeçalho PARTE 1
        _buildHeaderSecao(
          "PARTE 1: SINTOMAS E AMBIENTE",
          "Em geral, quanto tempo durante as últimas 2 semanas você sentiu:",
          Icons.eco_rounded,
          const Color(0xFF0066FF),
          isDark,
        ),
        const SizedBox(height: 12),

        ...List.generate(perguntasMiniAQLQParte1.length, (index) {
          final qIndex = index + 1;
          final key = 'q$qIndex';
          final valor = respostasMiniAQLQ[key] ?? 7;

          return _buildItemMiniAQLQ(
            qIndex: qIndex,
            pergunta: perguntasMiniAQLQParte1[index],
            valorAtual: valor,
            opcoes: opcoesMiniAQLQParte1,
            isDark: isDark,
            cardBg: cardBg,
            txtColor: txtColor,
            onSelect: (novoValor) {
              setState(() {
                respostasMiniAQLQ[key] = novoValor;
              });
            },
          );
        }),

        const SizedBox(height: 20),

        // Cabeçalho PARTE 2
        _buildHeaderSecao(
          "PARTE 2: LIMITAÇÃO DE ATIVIDADES",
          "Até que ponto se sentiu limitado(a) ao desempenhar:",
          Icons.directions_run_rounded,
          const Color(0xFF8B5CF6),
          isDark,
        ),
        const SizedBox(height: 12),

        ...List.generate(perguntasMiniAQLQParte2.length, (index) {
          final qIndex = index + 12;
          final key = 'q$qIndex';
          final valor = respostasMiniAQLQ[key] ?? 7;

          return _buildItemMiniAQLQ(
            qIndex: qIndex,
            pergunta: perguntasMiniAQLQParte2[index],
            valorAtual: valor,
            opcoes: opcoesMiniAQLQParte2,
            isDark: isDark,
            cardBg: cardBg,
            txtColor: txtColor,
            onSelect: (novoValor) {
              setState(() {
                respostasMiniAQLQ[key] = novoValor;
              });
            },
          );
        }),

        const SizedBox(height: 16),

        // Botão Salvar MiniAQLQ
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: enviando ? null : _salvarMiniAQLQ,
            icon: enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              enviando ? "Enviando..." : "Salvar Questionário MiniAQLQ",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSecao(
    String titulo,
    String subtitulo,
    IconData icon,
    Color cor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemMiniAQLQ({
    required int qIndex,
    required String pergunta,
    required int valorAtual,
    required List<String> opcoes,
    required bool isDark,
    required Color cardBg,
    required Color txtColor,
    required ValueChanged<int> onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$qIndex",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pergunta,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: txtColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Seletor de 1 a 7 responsivo
          LayoutBuilder(
            builder: (context, box) {
              final buttonWidth = (box.maxWidth - 24) / 7;
              final useScroll = buttonWidth < 36;
              final buttons = List.generate(7, (idx) {
                final numOption = idx + 1;
                final selecionado = valorAtual == numOption;
                final cor = _corParaMiniAQLQ(numOption);

                Widget btn = GestureDetector(
                  onTap: () => onSelect(numOption),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: useScroll ? 44 : null,
                    decoration: BoxDecoration(
                      color: selecionado
                          ? cor
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selecionado
                            ? cor
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                        width: selecionado ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "$numOption",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: selecionado
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );

                return useScroll ? btn : Expanded(child: btn);
              });

              if (useScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: buttons),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: buttons,
              );
            },
          ),

          const SizedBox(height: 8),

          // Legenda do número selecionado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _corParaMiniAQLQ(valorAtual).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opcoes[valorAtual - 1],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _corParaMiniAQLQ(valorAtual),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📜 SEÇÃO HISTÓRICO DE QUESTIONÁRIOS
  // ==========================================
  Widget _buildHistoricoSection(bool isDark, Color cardBg, Color txtColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Histórico de Respostas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _carregarHistorico,
              tooltip: "Recarregar",
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (carregando)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (historicoQuestionarios.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 42, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  "Nenhum questionário registrado ainda.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historicoQuestionarios.length,
            itemBuilder: (context, index) {
              final item = historicoQuestionarios[index];
              final isACQ5 = item['tipo'] == 'acq5';
              final media = double.tryParse(item['pontuacao_media'].toString()) ?? 0.0;
              final dataStr = item['criado_em'] != null
                  ? item['criado_em'].toString().split('T')[0]
                  : "";

              Color badgeColor = Colors.green;
              if (isACQ5) {
                if (media >= 0.75 && media <= 1.5) {
                  badgeColor = Colors.orange;
                } else if (media > 1.5) {
                  badgeColor = Colors.red;
                }
              } else {
                if (media < 4.0) {
                  badgeColor = Colors.red;
                } else if (media < 6.0) {
                  badgeColor = Colors.orange;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                      child: Icon(
                        isACQ5 ? Icons.shield_rounded : Icons.favorite_rounded,
                        color: badgeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isACQ5 ? "Questionário ACQ-5" : "Questionário MiniAQLQ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: txtColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Score: ${media.toStringAsFixed(2)} pts • Data: $dataStr",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['classificacao'] ?? (isACQ5 ? "Controle da Asma" : "Qualidade de Vida"),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: "Excluir",
                      onPressed: () => _deletarQuestionario(item['id_questionario']),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
