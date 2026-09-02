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
  List<dynamic> historicoQuestionarios = [];

  // Estado ACQ-5
  final Map<String, int> respostasACQ5 = {
    'q1': 0,
    'q2': 0,
    'q3': 0,
    'q4': 0,
    'q5': 0,
  };

  // Estado MiniAQLQ (15 perguntas, default 7 = excelente)
  final Map<String, int> respostasMiniAQLQ = Map.fromIterable(
    List.generate(15, (index) => 'q${index + 1}'),
    value: (_) => 7,
  );

  final List<String> perguntasACQ5 = [
    "1. Com que frequência acordou devido à asma durante a noite na última semana?",
    "2. Quão graves foram os seus sintomas de asma ao acordar de manhã?",
    "3. Quão limitado(a) esteve nas suas atividades por causa da asma?",
    "4. Quanto falta de ar (dispneia) sentiu durante a última semana?",
    "5. Durante quanto tempo teve pieira (chiado no peito) na última semana?",
  ];

  final List<String> opcoesACQ5 = [
    "0 - Nunca / Sem sintomas",
    "1 - Raras vezes / Muito leve",
    "2 - Poucas vezes / Leve",
    "3 - Moderado",
    "4 - Bastante / Moderadamente grave",
    "5 - Muitas vezes / Grave",
    "6 - Todo o tempo / Muito grave",
  ];

  final List<String> perguntasMiniAQLQ = [
    "1. Limitação para praticar exercícios ou corridas intensas",
    "2. Limitação para subir escadas ou ladeiras",
    "3. Sentiu-se incomodado(a) com poeira ou poluição",
    "4. Sentiu falta de ar ao realizar tarefas do dia a dia",
    "5. Sentiu aperto no peito",
    "6. Teve acordares noturnos devido à tossea/chiado",
    "7. Teve medo de não ter os medicamentos por perto",
    "8. Sentiu-se frustrado(a) por causa da asma",
    "9. Teve limitações sociais ou com amigos",
    "10. Incomodou-se com fumaça ou cheiros fortes",
    "11. Teve dificuldade para ter uma noite inteira de sono",
    "12. Teve crises de tosse insistente",
    "13. Sentiu-se preocupado(a) com sua saúde respiratória",
    "14. Teve necessidade de usar medicação de alívio rápido",
    "15. Sentiu-se sem energia ou fadigado(a)",
  ];

  final List<String> opcoesMiniAQLQ = [
    "1 - Totalmente limitado / Todo o tempo",
    "2 - Muito limitado",
    "3 - Moderadamente limitado",
    "4 - Alguma limitação",
    "5 - Pouca limitação",
    "6 - Quase nada limitado",
    "7 - Nada limitado / Nunca",
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
    setState(() => carregando = true);
    try {
      final list = await Api.listarQuestionarios();
      setState(() {
        historicoQuestionarios = list;
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  Future<void> _salvarACQ5() async {
    try {
      await Api.salvarQuestionario(tipo: 'acq5', respostas: respostasACQ5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Questionário ACQ-5 enviado com sucesso!")),
        );
      }
      _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar: $e")),
        );
      }
    }
  }

  Future<void> _salvarMiniAQLQ() async {
    try {
      await Api.salvarQuestionario(tipo: 'miniaqlq', respostas: respostasMiniAQLQ);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Questionário MiniAQLQ enviado com sucesso!")),
        );
      }
      _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar: $e")),
        );
      }
    }
  }

  Future<void> _deletarQuestionario(String id) async {
    try {
      await Api.deletarQuestionario(id);
      _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao deletar questionário.")),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Questionários de Asma"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.health_and_safety), text: "Controle (ACQ-5)"),
            Tab(icon: Icon(Icons.favorite), text: "Qualidade de Vida (MiniAQLQ)"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabACQ5(isDark, cardBg, txtColor),
                  _buildTabMiniAQLQ(isDark, cardBg, txtColor),
                ],
              ),
            ),
            const Divider(height: 32),
            _buildHistoricoSection(isDark, cardBg, txtColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTabACQ5(bool isDark, Color cardBg, Color txtColor) {
    final media = _calcularMediaACQ5();
    String status = "Asma Controlada";
    Color statusColor = Colors.green;

    if (media >= 0.75 && media <= 1.5) {
      status = "Parcialmente Controlada";
      statusColor = Colors.orange;
    } else if (media > 1.5) {
      status = "Asma Não Controlada";
      statusColor = Colors.red;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pontuação Média: ${media.toStringAsFixed(2)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                      Text("Classificação: $status",
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(perguntasACQ5.length, (index) {
            final key = 'q${index + 1}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(perguntasACQ5[index], style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: respostasACQ5[key],
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    items: List.generate(opcoesACQ5.length, (i) {
                      return DropdownMenuItem(value: i, child: Text(opcoesACQ5[i], style: const TextStyle(fontSize: 13)));
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => respostasACQ5[key] = val);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _salvarACQ5,
              icon: const Icon(Icons.send),
              label: const Text("Enviar ACQ-5", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabMiniAQLQ(bool isDark, Color cardBg, Color txtColor) {
    final media = _calcularMediaMiniAQLQ();
    String status = "Excelente Qualidade de Vida";
    Color statusColor = Colors.green;

    if (media < 4.0) {
      status = "Baixa Qualidade de Vida";
      statusColor = Colors.red;
    } else if (media < 6.0) {
      status = "Boa Qualidade de Vida";
      statusColor = Colors.orange;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.sentiment_satisfied_alt, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pontuação Média: ${media.toStringAsFixed(2)} / 7.0",
                          style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                      Text("Classificação: $status",
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(perguntasMiniAQLQ.length, (index) {
            final key = 'q${index + 1}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${index + 1}. ${perguntasMiniAQLQ[index]}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: respostasMiniAQLQ[key],
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    items: List.generate(opcoesMiniAQLQ.length, (i) {
                      return DropdownMenuItem(value: i + 1, child: Text(opcoesMiniAQLQ[i], style: const TextStyle(fontSize: 13)));
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => respostasMiniAQLQ[key] = val);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _salvarMiniAQLQ,
              icon: const Icon(Icons.send),
              label: const Text("Enviar MiniAQLQ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoSection(bool isDark, Color cardBg, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Histórico de Questionários",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: txtColor),
          ),
          const SizedBox(height: 12),
          if (carregando)
            const Center(child: CircularProgressIndicator())
          else if (historicoQuestionarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text("Nenhum questionário de asma registrado.", style: TextStyle(color: Colors.grey)),
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
                final dataStr = item['criado_em'] != null ? item['criado_em'].toString().split('T')[0] : "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isACQ5 ? Colors.teal.withValues(alpha: 0.15) : Colors.purple.withValues(alpha: 0.15),
                      child: Icon(
                        isACQ5 ? Icons.health_and_safety : Icons.favorite,
                        color: isACQ5 ? Colors.teal : Colors.purple,
                      ),
                    ),
                    title: Text(
                      isACQ5 ? "Questionário ACQ-5" : "Questionário MiniAQLQ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: txtColor),
                    ),
                    subtitle: Text(
                      "Média: ${item['pontuacao_media']} • ${item['classificacao'] ?? ''}\nData: $dataStr",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletarQuestionario(item['id_questionario']),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
