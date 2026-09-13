import 'package:flutter/material.dart';

class PoliticaPrivacidadePage extends StatefulWidget {
  const PoliticaPrivacidadePage({super.key});

  @override
  State<PoliticaPrivacidadePage> createState() =>
      _PoliticaPrivacidadePageState();
}

class _PoliticaPrivacidadePageState extends State<PoliticaPrivacidadePage> {
  final ScrollController _scrollController = ScrollController();
  int _secaoAtiva = 0;

  final List<String> _categorias = [
    "Todas",
    "Dados Coletados",
    "GPS & Treinos",
    "Inteligência Artificial",
    "Segurança",
    "Seus Direitos",
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
          "Política de Privacidade",
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
                  content: const Text("Link da política copiado para a área de transferência"),
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
                      "O PaceMind é uma plataforma desenvolvida para o acompanhamento e gestão inteligente de treinos de corrida. "
                      "Permite registrar desempenhos, analisar evolução métrica e obter recomendações personalizadas.",
                      subColor,
                    ),
                    _paragrafo(
                      "O aplicativo integra recursos de Inteligência Artificial (IA) para interpretar padrões dos treinos e sugerir diretrizes esportivas.",
                      subColor,
                    ),
                  ],
                ),
                _buildSection(
                  numero: "02",
                  titulo: "Responsável pelo Tratamento",
                  icone: Icons.business_rounded,
                  corIcone: const Color(0xFF0284C7),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _itemInfo("Aplicativo", "PaceMind Running Analytics", textColor, subColor),
                    _itemInfo("Responsável", "Equipe de Desenvolvimento PaceMind", textColor, subColor),
                    _itemInfo("Contato de Privacidade", "privacidade@pacemind.com", textColor, subColor),
                  ],
                ),
                _buildSection(
                  numero: "03",
                  titulo: "Dados Pessoais Coletados",
                  icone: Icons.folder_shared_rounded,
                  corIcone: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _subtitulo("3.1 Dados Cadastrais", textColor),
                    _bullet("Nome completo e e-mail de autenticação;", subColor),
                    _bullet("Senha armazenada com hash criptográfico seguro;", subColor),
                    _bullet("Foto de perfil (opcional) para identificação pessoal.", subColor),
                    const SizedBox(height: 12),
                    _subtitulo("3.2 Dados de Treinamento e Esporte", textColor),
                    _bullet("Distância, tempo decorrido, pace (ritmo) e velocidade;", subColor),
                    _bullet("Frequência cardíaca e zonas de intensidade calibradas;", subColor),
                    _bullet("Volume semanal e mensal acumulado e histórico de corridas;", subColor),
                    _bullet("Metas estabelecidas e consistência de descanso.", subColor),
                    const SizedBox(height: 12),
                    _subtitulo("3.3 Dados Técnicos do Dispositivo", textColor),
                    _bullet("Modelo do aparelho, sistema operacional e versão do PaceMind;", subColor),
                    _bullet("Logs operacionais de erro e tokens de sessão autenticada.", subColor),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 2) ...[
                _buildSection(
                  numero: "04",
                  titulo: "Dados de Localização & GPS",
                  icone: Icons.location_on_rounded,
                  corIcone: const Color(0xFF10B981),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Com o consentimento explícito do usuário, o PaceMind utiliza o GPS do dispositivo durante a corrida para:",
                      subColor,
                    ),
                    _bullet("Mapear a rota e o percurso realizado em tempo real;", subColor),
                    _bullet("Calcular com alta precisão distância, velocidade e ritmo instantâneo;", subColor),
                    _bullet("Acompanhar a sessão em segundo plano quando a tela estiver bloqueada.", subColor),
                    const SizedBox(height: 12),
                    _destaqueAlerta(
                      icone: Icons.info_outline_rounded,
                      titulo: "Controle de Permissão",
                      mensagem:
                          "O acesso à localização pode ser ativado ou revogado a qualquer momento nas configurações do seu celular ou na aba de Configurações do PaceMind.",
                      cor: const Color(0xFF0284C7),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 3) ...[
                _buildSection(
                  numero: "05",
                  titulo: "PaceMind AI (Inteligência Artificial)",
                  icone: Icons.smart_toy_rounded,
                  corIcone: const Color(0xFF06B6D4),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "O PaceMind oferece recursos de IA para auxiliar na interpretação dos treinos, analisando histórico, cargas, zonas de ritmo e consistência.",
                      subColor,
                    ),
                    const SizedBox(height: 8),
                    _destaqueAlerta(
                      icone: Icons.warning_amber_rounded,
                      titulo: "Aviso Médico e Esportivo Obrigatório",
                      mensagem:
                          "As análises e respostas da PaceMind AI têm caráter exclusivamente informativo e de suporte esportivo. NÃO constituem recomendação médica, nutricional ou prescrição clínica. Consulte sempre profissionais de saúde e educação física.",
                      cor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _subtitulo("Privacidade das Mensagens da IA", textColor),
                    _paragrafo(
                      "O histórico de conversas é mantido apenas para continuidade de contexto. Você pode solicitar a limpeza ou exclusão desse histórico diretamente nas Configurações.",
                      subColor,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 4) ...[
                _buildSection(
                  numero: "06",
                  titulo: "Segurança e Proteção das Informações",
                  icone: Icons.security_rounded,
                  corIcone: const Color(0xFF3B82F6),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Adotamos práticas alinhadas às diretrizes da LGPD (Lei Geral de Proteção de Dados) para salvaguardar seus dados:",
                      subColor,
                    ),
                    _bullet("Comunicação 100% criptografada via HTTPS/TLS;", subColor),
                    _bullet("Senhas protegidas com hashing de alta segurança;", subColor),
                    _bullet("Controle de sessão por tokens com expiração programada;", subColor),
                    _bullet("Banco de dados com controle restrito de privilégios e firewall.", subColor),
                    const SizedBox(height: 10),
                    _paragrafo(
                      "Não comercializamos dados pessoais de usuários com anunciantes ou parceiros comerciais em nenhuma hipótese.",
                      subColor,
                    ),
                  ],
                ),
                _buildSection(
                  numero: "07",
                  titulo: "Serviços de Terceiros e Hospedagem",
                  icone: Icons.cloud_done_rounded,
                  corIcone: const Color(0xFF6366F1),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Para garantir disponibilidade contínua, o PaceMind utiliza parceiros de infraestrutura de nuvem confiáveis para hospedagem de banco de dados, servidores de API e envio de notificações.",
                      subColor,
                    ),
                  ],
                ),
              ],

              if (_secaoAtiva == 0 || _secaoAtiva == 5) ...[
                _buildSection(
                  numero: "08",
                  titulo: "Seus Direitos como Titular (LGPD)",
                  icone: Icons.verified_user_rounded,
                  corIcone: const Color(0xFF10B981),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "De acordo com a Lei nº 13.709/2018 (LGPD), você pode exercer a qualquer momento os seguintes direitos:",
                      subColor,
                    ),
                    _bullet("Confirmar o tratamento e acessar todos os seus dados;", subColor),
                    _bullet("Solicitar correção de dados incompletos ou inexatos;", subColor),
                    _bullet("Solicitar exclusão definitiva da conta e de seus dados pessoais;", subColor),
                    _bullet("Revogar consentimentos concedidos anteriormente.", subColor),
                    const SizedBox(height: 12),
                    _itemInfo(
                      "Como exercer seus direitos",
                      "Envie um e-mail para privacidade@pacemind.com com o assunto 'Solicitação LGPD'.",
                      textColor,
                      subColor,
                    ),
                  ],
                ),
                _buildSection(
                  numero: "09",
                  titulo: "Exclusão de Conta e Dados",
                  icone: Icons.delete_outline_rounded,
                  corIcone: const Color(0xFFEF4444),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColor,
                  subColor: subColor,
                  conteudo: [
                    _paragrafo(
                      "Ao solicitar a exclusão da sua conta, todo o seu histórico de treinos, biometria e registros cadastrais serão eliminados de forma irreversível ou anonimizados, respeitados prazos legais de guarda.",
                      subColor,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // 🏁 4. RODAPÉ DE ACEITE E CONTATO
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
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF0052D4), const Color(0xFF4364F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052D4).withValues(alpha: 0.25),
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
                  Icons.shield_outlined,
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
                      "Transparência & Dados",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Privacidade desenhada para corredores",
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
            "Esta política explica com clareza quais dados coletamos, como protegemos seus treinos e rotas de GPS e quais são seus direitos sob a LGPD.",
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
              _badgeHero(Icons.gavel_rounded, "LGPD (Lei 13.709/18)"),
              _badgeHero(Icons.calendar_today_rounded, "Atualizado: 04/09/2026"),
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

  Widget _subtitulo(String texto, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: cor,
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
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF),
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
          Icon(
            Icons.task_alt_rounded,
            color: const Color(0xFF10B981),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            "Você tem o controle dos seus dados",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Em caso de dúvidas ou para exercer seus direitos da LGPD, fale diretamente com nossa equipe.",
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
                "Entendi e Concordo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
