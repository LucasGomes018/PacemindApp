import 'package:flutter/material.dart';
import '../core/api.dart';

class TestesPage extends StatefulWidget {
  const TestesPage({super.key});

  @override
  State<TestesPage> createState() => _TestesPageState();
}

class _TestesPageState extends State<TestesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool carregando = false;
  List<dynamic> historicoTestes = [];

  // Controllers 3km
  final TextEditingController _min3kmController = TextEditingController();
  final TextEditingController _sec3kmController = TextEditingController();
  final TextEditingController _obs3kmController = TextEditingController();

  // Controllers Sprint 20m
  final TextEditingController _tempoSprintController = TextEditingController();
  final TextEditingController _obsSprintController = TextEditingController();

  double? vvo2maxCalculado;
  double? vmaxCalculada;
  double? asrCalculada;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarHistorico();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _min3kmController.dispose();
    _sec3kmController.dispose();
    _obs3kmController.dispose();
    _tempoSprintController.dispose();
    _obsSprintController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    if (!mounted) return;
    setState(() => carregando = true);
    try {
      final testes = await Api.listarTestes();
      if (!mounted) return;
      setState(() {
        historicoTestes = testes;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  void _calcular3km() {
    final min = int.tryParse(_min3kmController.text) ?? 0;
    final sec = int.tryParse(_sec3kmController.text) ?? 0;
    final totalSec = min * 60 + sec;

    if (totalSec > 0) {
      setState(() {
        vvo2maxCalculado = 3.0 / (totalSec / 3600.0);
      });
    } else {
      setState(() => vvo2maxCalculado = null);
    }
  }

  void _calcularSprint() {
    final sec =
        double.tryParse(_tempoSprintController.text.replaceAll(',', '.')) ??
        0.0;
    if (sec > 0) {
      final vmax = 0.020 / (sec / 3600.0); // 20m em km/h

      // Buscar último 3km para ASR
      double? ultimoVVO2;
      for (var t in historicoTestes) {
        if (t['tipo_teste'] == '3km' && t['vvo2max_kmh'] != null) {
          ultimoVVO2 = double.tryParse(t['vvo2max_kmh'].toString());
          break;
        }
      }

      setState(() {
        vmaxCalculada = vmax;
        if (ultimoVVO2 != null && ultimoVVO2 > 0) {
          asrCalculada = vmax - ultimoVVO2;
        } else {
          asrCalculada = null;
        }
      });
    } else {
      setState(() {
        vmaxCalculada = null;
        asrCalculada = null;
      });
    }
  }

  Future<void> _salvar3km() async {
    final min = int.tryParse(_min3kmController.text) ?? 0;
    final sec = int.tryParse(_sec3kmController.text) ?? 0;
    final totalSec = min * 60 + sec;

    if (totalSec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o tempo do teste de 3km.")),
      );
      return;
    }

    try {
      await Api.salvarTeste(
        tipoTeste: '3km',
        tempoSegundos: totalSec.toDouble(),
        observacoes: _obs3kmController.text,
      );

      _min3kmController.clear();
      _sec3kmController.clear();
      _obs3kmController.clear();
      setState(() => vvo2maxCalculado = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teste de 3km salvo com sucesso!")),
        );
      }

      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar teste: $e")));
      }
    }
  }

  Future<void> _salvarSprint() async {
    final sec =
        double.tryParse(_tempoSprintController.text.replaceAll(',', '.')) ??
        0.0;

    if (sec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o tempo do Sprint 20m.")),
      );
      return;
    }

    try {
      await Api.salvarTeste(
        tipoTeste: 'sprint_20m',
        tempoSegundos: sec,
        observacoes: _obsSprintController.text,
      );

      _tempoSprintController.clear();
      _obsSprintController.clear();
      setState(() {
        vmaxCalculada = null;
        asrCalculada = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Teste de Sprint 20m salvo com sucesso!"),
          ),
        );
      }

      await _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar teste: $e")));
      }
    }
  }

  Future<void> _deletarTeste(String id) async {
    try {
      await Api.deletarTeste(id);
      _carregarHistorico();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Erro ao deletar teste.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final txtColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Testes de Corrida"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.directions_run), text: "3 km (vVO2max)"),
            Tab(icon: Icon(Icons.bolt), text: "Sprint 20m (ASR)"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildTab3km(isDark, cardBg, txtColor);
                } else {
                  return _buildTabSprint(isDark, cardBg, txtColor);
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 32),
            ),
            _buildHistoricoSection(isDark, cardBg, txtColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTab3km(bool isDark, Color cardBg, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF0066FF)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Protocolo 3km: Aquecimento de 10-15 min. Corra 3.000m na pista ou terreno plano no maior ritmo sustentável constante.",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min3kmController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calcular3km(),
                  decoration: const InputDecoration(
                    labelText: "Minutos",
                    suffixText: "min",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sec3kmController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calcular3km(),
                  decoration: const InputDecoration(
                    labelText: "Segundos",
                    suffixText: "seg",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _obs3kmController,
            decoration: const InputDecoration(
              labelText: "Observações (opcional)",
              hintText: "Ex: Condições climáticas, pista sintética...",
            ),
          ),
          if (vvo2maxCalculado != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "vVO2max Estimada",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${vvo2maxCalculado!.toStringAsFixed(2)} km/h",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _salvar3km,
              icon: const Icon(Icons.save),
              label: const Text(
                "Salvar Teste de 3km",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSprint(bool isDark, Color cardBg, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Protocolo 20m Sprint: 5m de aceleração prévia + 20m em sprint máximo cronometrados.",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tempoSprintController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _calcularSprint(),
            decoration: const InputDecoration(
              labelText: "Tempo dos 20m (segundos.milissegundos)",
              hintText: "Ex: 2.45",
              suffixText: "seg",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _obsSprintController,
            decoration: const InputDecoration(
              labelText: "Observações (opcional)",
            ),
          ),
          if (vmaxCalculada != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        "Vmax (20m)",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${vmaxCalculada!.toStringAsFixed(1)} km/h",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  if (asrCalculada != null)
                    Column(
                      children: [
                        Text(
                          "ASR (Reserva Anaeróbica)",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "+${asrCalculada!.toStringAsFixed(1)} km/h",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _salvarSprint,
              icon: const Icon(Icons.bolt),
              label: const Text(
                "Salvar Sprint 20m",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
            "Histórico de Testes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
          const SizedBox(height: 12),
          if (carregando)
            const Center(child: CircularProgressIndicator())
          else if (historicoTestes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "Nenhum teste físico registrado ainda.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historicoTestes.length,
              itemBuilder: (context, index) {
                final item = historicoTestes[index];
                final is3km = item['tipo_teste'] == '3km';
                final dataStr = item['criado_em'] != null
                    ? item['criado_em'].toString().split('T')[0]
                    : "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: is3km
                          ? const Color(0xFF0066FF).withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15),
                      child: Icon(
                        is3km ? Icons.directions_run : Icons.bolt,
                        color: is3km
                            ? const Color(0xFF0066FF)
                            : Colors.amber.shade800,
                      ),
                    ),
                    title: Text(
                      is3km ? "Teste de 3km" : "Sprint 20m Speed Max",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: txtColor,
                      ),
                    ),
                    subtitle: Text(
                      is3km
                          ? "Tempo: ${item['tempo_segundos']}s • vVO2: ${item['vvo2max_kmh'] ?? '-'} km/h\nData: $dataStr"
                          : "Tempo: ${item['tempo_segundos']}s • Vmax: ${item['velocidade_max_kmh'] ?? '-'} km/h • ASR: ${item['asr_kmh'] ?? '-'} km/h\nData: $dataStr",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletarTeste(item['id_teste']),
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
