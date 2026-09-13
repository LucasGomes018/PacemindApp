import 'package:flutter/material.dart';

class TermosUsoPage extends StatefulWidget {
  const TermosUsoPage({super.key});

  @override
  State<TermosUsoPage> createState() => _TermosUsoPageState();
}

class _TermosUsoPageState extends State<TermosUsoPage> {
  final ScrollController _scrollController = ScrollController();
  int _secaoAtiva = 0;

  final List<String> _categorias = [
    "Todos",
    "Serviço & GPS",
    "PaceMind AI",
    "Segurança nos Treinos",
    "Regras de Uso",
    "Isenções & Contato",
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 360;

    final primaryBlue = const Color(0xFF0066FF);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Termos de Uso",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 17 : 19,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: subColor, size: 20),
            tooltip: "Compartilhar",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Link dos termos copiado para a área de transferência"),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 20,
              vertical: 12,
            ),
            children: [
              // 🌟 1. BANNER HERO DE INTRODUÇÃO
              _buildHeroCard(isDark, isSmall),

              const SizedBox(height: 18),

              // 🏷️ 2. CHIPS DE FILTRO RÁPIDO
              _buildFilterChips(isDark, isSmall),

              const SizedBox(height: 20),

              // 📜 3. SEÇÕES DE CONTEÚDO
              if (_secaoAtiva == 0 || _secaoAtiva == 1) ...[
                _buildSection(
                  numero: "01",
                  titulo: "Sobre o PaceMind",
                  icone: Icons.directions_run_rounded,
                  corIcone: const Color(0xFF0066FF),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "O PaceMind é uma plataforma dedicada a auxiliar corredores no registro, acompanhamento e análise científica de seus treinamentos físicos.",
                      subColor,
                    ),
                    _paragrafo(
                      "Suas funcionalidades compreendem: registro de corridas, pace médio, zonas de frequência cardíaca, volume acumulado, metas de treino, GPS e recursos de inteligência artificial.",
                      subColor,
                    ),
                  ],
                ),
                _buildSection(
                  numero: "02",
                  titulo: "Aceitação e Capacidade Legal",
                  icone: Icons.check_circle_outline_rounded,
                  corIcone: const Color(0xFF10B981),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Ao criar uma conta ou utilizar qualquer recurso do PaceMind, você declara ter lido, compreendido e concordado com estes Termos de Uso.",
                      subColor,
                    ),
                    _bullet("Declara possuir capacidade legal para celebrar este acordo;", subColor),
                    _bullet("Compromete-se a fornecer informações verdadeiras e atualizadas;", subColor),
                    _bullet("Utilizará o serviço de forma ética, responsável e legal.", subColor),
                  ],
                ),
                _buildSection(
                  numero: "03",
                  titulo: "GPS e Dados de Localização",
                  icone: Icons.location_on_rounded,
                  corIcone: const Color(0xFF0284C7),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Funcionalidades de mapeamento e cálculo dinâmico de ritmo dependem de sensores de GPS do aparelho.",
                      subColor,
                    ),
                    _bullet("O GPS em segundo plano só é ativado mediante permissão do usuário;", subColor),
                    _bullet("A desativação do GPS pode limitar a precisão de distância e velocidade dos treinos.", subColor),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 2) ...[
                _buildSection(
                  numero: "04",
                  titulo: "PaceMind AI & Isenção Médica",
                  icone: Icons.smart_toy_rounded,
                  corIcone: const Color(0xFF06B6D4),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "O PaceMind disponibiliza recursos de inteligência artificial para sugerir ajustes na rotina de treinos a partir do histórico do usuário.",
                      subColor,
                    ),
                    const SizedBox(height: 8),
                    _destaqueAlerta(
                      icone: Icons.health_and_safety_rounded,
                      titulo: "Isenção de Responsabilidade Médica",
                      mensagem:
                          "A PaceMind AI NÃO substitui médicos, cardiologistas, nutricionistas ou treinadores certificados. As respostas têm caráter exclusivamente informativo. Nunca utilize respostas da IA como diagnóstico de saúde ou prescrição de esforços máximos.",
                      cor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _paragrafo(
                      "As respostas de modelos automatizados podem conter imprecisões ocasionais. O usuário deve sempre aplicar seu bom senso e consultar profissionais qualificados.",
                      subColor,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 3) ...[
                _buildSection(
                  numero: "05",
                  titulo: "Segurança e Saúde Durante a Corrida",
                  icone: Icons.favorite_rounded,
                  corIcone: const Color(0xFFEF4444),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "A prática de corrida e atividades físicas exige condições cardiovasculares adequadas. O PaceMind não avalia nem garante a aptidão física do usuário.",
                      subColor,
                    ),
                    _destaqueAlerta(
                      icone: Icons.warning_amber_rounded,
                      titulo: "Interrupção Imediata",
                      mensagem:
                          "Caso sinta dores no peito, tontura, palpitações anormais, falta de ar severa ou mal-estar durante uma corrida, interrompa o treino imediatamente e procure assistência médica.",
                      cor: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _paragrafo(
                      "O usuário assume total responsabilidade pela escolha de percursos, segurança em vias públicas e respeito aos seus limites fisiológicos.",
                      subColor,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 4) ...[
                _buildSection(
                  numero: "06",
                  titulo: "Regras de Conduta e Uso Aceitável",
                  icone: Icons.gavel_rounded,
                  corIcone: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Ao utilizar o PaceMind, é expressamente proibido:",
                      subColor,
                    ),
                    _bullet("Tentar invadir, descompilar ou realizar engenharia reversa do software;", subColor),
                    _bullet("Inserir dados fraudulentos ou utilizar automações que sobrecarreguem servidores;", subColor),
                    _bullet("Compartilhar credenciais de acesso ou acessar contas de outros atletas;", subColor),
                    _bullet("Praticar qualquer conduta em desconformidade com a legislação brasileira.", subColor),
                  ],
                ),
                _buildSection(
                  numero: "07",
                  titulo: "Propriedade Intelectual",
                  icone: Icons.copyright_rounded,
                  corIcone: const Color(0xFF6366F1),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Todos os direitos sobre a marca PaceMind, logotipos, interface gráfica, algoritmos de ritmo, código-fonte e arquitetura pertencem exclusivamente aos seus desenvolvedores.",
                      subColor,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 5) ...[
                _buildSection(
                  numero: "08",
                  titulo: "Disponibilidade e Modificações",
                  icone: Icons.update_rounded,
                  corIcone: const Color(0xFF0284C7),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Buscamos manter o aplicativo sempre ativo e estável, mas manutenções preventivas, melhorias ou instabilidades de infraestrutura em nuvem podem ocorrer.",
                      subColor,
                    ),
                    _paragrafo(
                      "Estes Termos podem ser atualizados periodicamente para refletir novas funcionalidades ou adequações legais.",
                      subColor,
                    ),
                  ],
                ),
                _buildSection(
                  numero: "09",
                  titulo: "Legislação Aplicável e Contato",
                  icone: Icons.contact_support_rounded,
                  corIcone: const Color(0xFF10B981),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Estes termos são regidos pelas leis da República Federativa do Brasil, em especial o Marco Civil da Internet e o Código de Defesa do Consumidor.",
                      subColor,
                    ),
                    _itemInfo("Canal de Atendimento", "suporte@pacemind.com", textColor, subColor),
                    _itemInfo("Privacidade", "privacidade@pacemind.com", textColor, subColor),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // 🏁 4. RODAPÉ DE ACEITE
              _buildFooter(isDark, primaryBlue, cardBg, cardBorder, textColor, subColor),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 🌟 COMPONENTES VISUAIS
  // ===========================================================================
  Widget _buildHeroCard(bool isDark, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF4338CA), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Termos de Uso",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Condições e diretrizes da plataforma PaceMind",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Regras de utilização, compromissos mútuos, diretrizes da IA e orientações de segurança para a prática de corrida.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badgeHero(Icons.verified_outlined, "Contrato do Atleta"),
              _badgeHero(Icons.calendar_today_rounded, "Versão: 1.0 (Setembro/2026)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeHero(IconData icon, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, bool isSmall) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _secaoAtiva == index;
          return FilterChip(
            selected: isSelected,
            label: Text(_categorias[index]),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            selectedColor: const Color(0xFF0066FF),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF0066FF)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onSelected: (_) {
              setState(() {
                _secaoAtiva = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String numero,
    required String titulo,
    required IconData icone,
    required Color corIcone,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color subColor,
    required List<Widget> conteudo,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: corIcone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  numero,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: subColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...conteudo,
        ],
      ),
    );
  }

  Widget _paragrafo(String texto, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13.5,
          color: cor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _bullet(String texto, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF0066FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, color: cor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemInfo(String rotulo, String valor, Color textColor, Color subColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$rotulo: ",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(fontSize: 12.5, color: subColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _destaqueAlerta({
    required IconData icone,
    required String titulo,
    required String mensagem,
    required Color cor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    bool isDark,
    Color primaryBlue,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF0066FF),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            "Pronto para correr com o PaceMind?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ao continuar utilizando o aplicativo, você concorda com os termos e com a política de privacidade.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Concordo com os Termos",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
