import 'package:flutter/material.dart';

class KmChart extends StatefulWidget {
  final List<dynamic> dados;

  const KmChart({super.key, required this.dados});

  @override
  State<KmChart> createState() => _KmChartState();
}

class _KmChartState extends State<KmChart> {
  int? indexHover;

  @override
  Widget build(BuildContext context) {
    if (widget.dados.isEmpty) {
      return const Center(child: Text("Sem dados"));
    }

    // 🔥 pega maior valor pra normalizar gráfico
    final maxKm = widget.dados
        .map((e) {
          final v = e["km"];
          return v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
        })
        .fold(0.0, (a, b) => a > b ? a : b);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: LayoutBuilder(
        key: ValueKey(widget.dados.length),
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;

          return Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(widget.dados.length, (index) {
                    final item = widget.dados[index];

                    final kmRaw = item["km"];
                    final km = kmRaw is num
                        ? kmRaw.toDouble()
                        : double.tryParse(kmRaw.toString()) ?? 0.0;

                    final isHover = indexHover == index;

                    // 🎯 altura proporcional ao maior valor
                    final alturaMax = maxHeight * 0.7;
                    final altura = maxKm == 0 ? 10.0 : (km / maxKm) * alturaMax;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            indexHover = index;
                          });
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              indexHover = index;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              indexHover = null;
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 🧠 espaço fixo evita overflow
                              SizedBox(
                                height: 28,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isHover ? 1 : 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "${km.toStringAsFixed(1)} km",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 📊 BARRA
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: isHover
                                    ? (altura + 8).clamp(10, alturaMax)
                                    : altura.clamp(10, alturaMax),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: isHover
                                      ? Colors.lightBlueAccent
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
