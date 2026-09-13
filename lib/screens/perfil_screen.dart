import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/app_modal.dart';
import '/core/api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool saving = false;

  // Estatísticas complementares de treino
  int totalTreinos = 0;
  double totalKm = 0.0;
  double kmSemanaAtual = 0.0;
  int? ritmoMedioSegundos;

  File? imagemSelecionada;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final data = await Api.getProfile();
      if (!mounted) return;

      setState(() {
        user = data;
        loading = false;
      });

      // Carrega métricas complementares em background sem bloquear a UI
      _carregarEstatisticas();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _carregarEstatisticas() async {
    try {
      final dash = await Api.getDashboard();
      if (!mounted) return;

      final resumo = dash['resumo'];
      if (resumo != null) {
        setState(() {
          totalTreinos =
              int.tryParse(resumo['total_treinos']?.toString() ?? '0') ?? 0;
          totalKm =
              double.tryParse(resumo['total_km']?.toString() ?? '0') ?? 0.0;
          final rm = double.tryParse(
            resumo['ritmo_medio']?.toString() ?? '0',
          );
          if (rm != null && rm > 0) {
            ritmoMedioSegundos = rm.toInt();
          }
        });
      }

      // KM da semana atual
      if (dash['semanal'] is List && (dash['semanal'] as List).isNotEmpty) {
        final ultimo = (dash['semanal'] as List).last;
        setState(() {
          kmSemanaAtual =
              double.tryParse(ultimo['km']?.toString() ?? '0') ?? 0.0;
        });
      }
    } catch (_) {
      // Falha silenciosa: estatísticas são complementares
    }
  }

  String formatarPace(dynamic segundos) {
    if (segundos == null) return "--:--";
    final totalSegundos = (segundos is num)
        ? segundos.toInt()
        : int.tryParse(segundos.toString()) ?? 0;
    if (totalSegundos <= 0) return "--:--";

    final minutos = totalSegundos ~/ 60;
    final seg = totalSegundos % 60;

    final minStr = minutos.toString().padLeft(2, '0');
    final segStr = seg.toString().padLeft(2, '0');

    return "$minStr:$segStr min/km";
  }

  String _formatarPaceSimples(int totalSegundos) {
    if (totalSegundos <= 0) return "--:--";
    final minutos = totalSegundos ~/ 60;
    final seg = totalSegundos % 60;
    return "${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  Future<void> uploadImagem() async {
    if (imagemSelecionada == null) return;

    try {
      final response = await Api.uploadFoto(imagemSelecionada!);
      if (!mounted) return;

      if (user != null && response["foto_url"] != null) {
        setState(() {
          user!["foto_url"] = response["foto_url"];
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Foto de perfil atualizada com sucesso!"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar foto: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> escolherImagem(ImageSource source) async {
    try {
      final XFile? imagem = await picker.pickImage(
        source: source,
        imageQuality: 88,
      );

      if (imagem == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: imagem.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar foto',
            toolbarColor: const Color(0xFF0066FF),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF0066FF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Ajustar foto',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (cropped != null) {
        setState(() {
          imagemSelecionada = File(cropped.path);
        });
        await uploadImagem();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possível carregar a imagem: $e"),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void abrirOpcoesFoto() {
    AppModal.showBottomSheet(
      context: context,
      title: "Alterar foto do perfil",
      subtitle: "Escolha uma imagem de boa qualidade",
      icon: Icons.camera_alt_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fotoOption(
            icon: Icons.photo_camera_rounded,
            title: "Tirar foto agora",
            subtitle: "Usar a câmera do dispositivo",
            onTap: () {
              Navigator.pop(context);
              escolherImagem(ImageSource.camera);
            },
          ),
          const SizedBox(height: 12),
          _fotoOption(
            icon: Icons.photo_library_rounded,
            title: "Escolher da galeria",
            subtitle: "Selecionar foto salva no aparelho",
            onTap: () {
              Navigator.pop(context);
              escolherImagem(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void abrirEditarPerfil() {
    final nomeController = TextEditingController(text: user!["nome_usuario"] ?? "");
    final objetivoController = TextEditingController(
      text: user!["objetivo_semanal_km"] != null
          ? user!["objetivo_semanal_km"].toString()
          : "",
    );

    int paceAtual = (user!["pace_referencia_segundos"] is num)
        ? (user!["pace_referencia_segundos"] as num).toInt()
        : 300;
    if (paceAtual <= 0) paceAtual = 300;

    int minutosSelecionados = (paceAtual ~/ 60).clamp(3, 15);
    int segundosSelecionados = (paceAtual % 60).clamp(0, 59);

    AppModal.showBottomSheet(
      context: context,
      title: "Editar Perfil do Atleta",
      subtitle: "Mantenha seus dados e ritmo calibrados",
      icon: Icons.edit_note_rounded,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final selectBackground =
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
          final selectText = isDark ? Colors.white : const Color(0xFF0F172A);
          final selectIcon =
              isDark ? Colors.cyanAccent : const Color(0xFF0284C7);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 👤 NOME
              _customField(
                controller: nomeController,
                label: "Nome Completo",
                icon: Icons.person_rounded,
                hint: "Seu nome ou apelido de corredor",
              ),

              const SizedBox(height: 18),

              // 🏃 PACE DE REFERÊNCIA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            color: Color(0xFF0066FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pace de Referência",
                                style: TextStyle(
                                  color: selectText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "Seu ritmo padrão por quilômetro",
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Minutos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Minutos",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: minutosSelecionados,
                                    isExpanded: true,
                                    dropdownColor: selectBackground,
                                    menuMaxHeight: 260,
                                    borderRadius: BorderRadius.circular(16),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: selectIcon,
                                    ),
                                    style: TextStyle(
                                      color: selectText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: List.generate(
                                      13,
                                      (index) => DropdownMenuItem(
                                        value: index + 3,
                                        child: Text(
                                          "${index + 3} min",
                                          style: TextStyle(
                                            color: selectText,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setModalState(() {
                                          minutosSelecionados = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Segundos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Segundos",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: segundosSelecionados,
                                    isExpanded: true,
                                    dropdownColor: selectBackground,
                                    menuMaxHeight: 260,
                                    borderRadius: BorderRadius.circular(16),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: selectIcon,
                                    ),
                                    style: TextStyle(
                                      color: selectText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: List.generate(60, (index) {
                                      return DropdownMenuItem(
                                        value: index,
                                        child: Text(
                                          "${index.toString().padLeft(2, '0')} s",
                                          style: TextStyle(
                                            color: selectText,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setModalState(() {
                                          segundosSelecionados = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Live preview banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0066FF).withValues(alpha: 0.14),
                            const Color(0xFF00C6FF).withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF0066FF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Ritmo Calculado: ${minutosSelecionados.toString().padLeft(2, '0')}:${segundosSelecionados.toString().padLeft(2, '0')} min/km",
                            style: const TextStyle(
                              color: Color(0xFF0066FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 🎯 META SEMANAL
              _customField(
                controller: objetivoController,
                label: "Meta Semanal (km)",
                icon: Icons.flag_rounded,
                hint: "Ex: 25.0",
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 28),

              // BOTÕES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(modalContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final novoPace =
                                    (minutosSelecionados * 60) +
                                    segundosSelecionados;
                                final novoObjetivo = double.tryParse(
                                  objetivoController.text.replaceAll(',', '.'),
                                );

                                final atualizado = await Api.atualizarPerfil(
                                  nome: nomeController.text.trim(),
                                  pace: novoPace,
                                  objetivo: novoObjetivo,
                                );

                                if (!mounted) return;
                                setState(() {
                                  user = atualizado;
                                });

                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Perfil atualizado com sucesso!"),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Erro ao atualizar: $e"),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Salvar Alterações",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  Future<void> logout() async {
    final confirmar = await AppModal.showConfirmDialog(
      context: context,
      title: "Desconectar da conta?",
      message:
          "Sua sessão será encerrada neste dispositivo. Você precisará fazer login novamente para acessar seus treinos.",
      confirmText: "Sim, sair",
      cancelText: "Cancelar",
      icon: Icons.logout_rounded,
      confirmButtonColor: const Color(0xFFEF4444),
      isDestructive: true,
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("token");

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;

    if (loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0066FF)),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),
              Text(
                "Não foi possível carregar o perfil",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: carregarPerfil,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Tentar novamente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: const Color(0xFF0066FF),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        onRefresh: carregarPerfil,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 🔥 1. HERO ATHLETE HEADER
              _buildHeroHeader(context, isDark, screenWidth),

              // 📦 2. CONTEÚDO PRINCIPAL (COM CONSTRAINTS PARA TABLETS/DESKTOP)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 360 ? 14 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // 🏃 3. KPI METRICS STRIP (Treinos, Volume, Pace, Meta)
                        _buildKpiMetrics(context, isDark, screenWidth),

                        const SizedBox(height: 22),

                        // 🎯 4. CARD INTERATIVO DE META SEMANAL
                        _buildWeeklyGoalCard(context, isDark, screenWidth),

                        const SizedBox(height: 22),

                        // ⚡ 5. CARD CIENTÍFICO DE ZONAS DE RITMO
                        _buildPacingZonesCard(context, isDark, screenWidth),

                        const SizedBox(height: 28),

                        // ⚙️ 6. CENTRAL DE AÇÕES E CONFIGURAÇÕES DA CONTA
                        _buildAccountHub(context, isDark),

                        // ESPAÇO EXTRA INFERIOR PARA NÃO COBRIR A BARRA DE NAVEGAÇÃO
                        const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 🌟 1. HERO ATHLETE HEADER
  // ===========================================================================
  Widget _buildHeroHeader(BuildContext context, bool isDark, double screenWidth) {
    final nome = user!["nome_usuario"]?.toString().trim() ?? "Atleta PaceMind";
    final email = user!["email"]?.toString().trim() ?? "";
    final fotoUrl = user!["foto_url"]?.toString().trim();
    final tipoUsuario = user!["tipo_usuario"]?.toString().toLowerCase();
    final isAdmin = tipoUsuario == "admin";
    final criadoEm = user!["criado_em"]?.toString() ?? "";

    final avatarRadius = screenWidth < 360 ? 52.0 : 62.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
              : [const Color(0xFF0052D4), const Color(0xFF4364F7), const Color(0xFF6FB1FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0052D4))
                .withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Barra de ações superiores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.directions_run_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAdmin ? "Treinador / Admin" : "Atleta PaceMind",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botões de Ação Rápida
                  Row(
                    children: [
                      _headerIconButton(
                        icon: Icons.edit_rounded,
                        tooltip: "Editar Perfil",
                        onTap: abrirEditarPerfil,
                      ),
                      const SizedBox(width: 10),
                      _headerIconButton(
                        icon: Icons.settings_outlined,
                        tooltip: "Configurações",
                        onTap: () =>
                            Navigator.pushNamed(context, "/configuracoes"),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // AVATAR COM GLOW E BADGE DE EDIÇÃO
              GestureDetector(
                onTap: abrirOpcoesFoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Halo de luz ao redor do avatar
                    Container(
                      width: (avatarRadius * 2) + 12,
                      height: (avatarRadius * 2) + 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00F0FF),
                            Color(0xFF0066FF),
                            Color(0xFF7000FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Avatar real
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                          ? NetworkImage(fotoUrl)
                          : null,
                      child: (fotoUrl == null || fotoUrl.isEmpty)
                          ? Text(
                              _obterIniciais(nome),
                              style: TextStyle(
                                fontSize: avatarRadius * 0.7,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0066FF),
                              ),
                            )
                          : null,
                    ),

                    // Botão da câmera flutuante
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // NOME DO ATLETA COM BADGE DE VERIFICADO
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                ],
              ),

              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // DATA DE ENTRADA OU STATUS
              if (criadoEm.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Atleta no PaceMind desde $criadoEm",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  String _obterIniciais(String nome) {
    if (nome.isEmpty) return "P";
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes.first.substring(0, min(2, partes.first.length)).toUpperCase();
    }
    return "${partes.first[0]}${partes.last[0]}".toUpperCase();
  }

  // ===========================================================================
  // 🏃 2. KPI METRICS STRIP (Treinos, Volume, Pace Ref, Meta)
  // ===========================================================================
  Widget _buildKpiMetrics(BuildContext context, bool isDark, double screenWidth) {
    final paceRef = user!["pace_referencia_segundos"];
    final metaSemanal = user!["objetivo_semanal_km"];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: "Pace Referência",
                value: formatarPace(paceRef),
                subtitle: "Ritmo base calibrado",
                icon: Icons.speed_rounded,
                accentColor: const Color(0xFF0066FF),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: "Meta Semanal",
                value: metaSemanal != null ? "$metaSemanal km" : "Sem meta",
                subtitle: "Distância alvo",
                icon: Icons.flag_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: "Treinos Feitos",
                value: totalTreinos.toString(),
                subtitle: "Corridas registradas",
                icon: Icons.directions_run_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: "Volume Total",
                value: "${totalKm.toStringAsFixed(1)} km",
                subtitle: "Quilometragem geral",
                icon: Icons.straighten_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎯 3. CARD INTERATIVO DE META SEMANAL
  // ===========================================================================
  Widget _buildWeeklyGoalCard(
    BuildContext context,
    bool isDark,
    double screenWidth,
  ) {
    final meta = double.tryParse(
          user!["objetivo_semanal_km"]?.toString() ?? "0",
        ) ??
        0.0;

    final progresso = meta > 0 ? (kmSemanaAtual / meta).clamp(0.0, 1.0) : 0.0;
    final porcentagem = (progresso * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Meta Semanal de Quilometragem",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      meta > 0
                          ? "$kmSemanaAtual km de $meta km percorridos esta semana"
                          : "Defina uma meta para acompanhar seu progresso",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: abrirEditarPerfil,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: isDark ? Colors.cyanAccent : const Color(0xFF0066FF),
                ),
                tooltip: "Ajustar meta",
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meta > 0 ? "$porcentagem% concluído" : "Nenhuma meta ativa",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: meta > 0
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
              Text(
                meta > 0
                    ? "Restam ${(meta - kmSemanaAtual).clamp(0.0, meta).toStringAsFixed(1)} km"
                    : "Toque para configurar",
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ⚡ 4. CARD CIENTÍFICO DE ZONAS DE RITMO
  // ===========================================================================
  Widget _buildPacingZonesCard(
    BuildContext context,
    bool isDark,
    double screenWidth,
  ) {
    int paceBase = (user!["pace_referencia_segundos"] is num)
        ? (user!["pace_referencia_segundos"] as num).toInt()
        : 300;
    if (paceBase <= 0) paceBase = 300;

    // Definição das zonas de ritmo fisiológicas com base no Pace de Referência
    final zonas = [
      {
        "zona": "Z1",
        "nome": "Regenerativo",
        "descricao": "Recuperação ativa e aquecimento",
        "paceMin": paceBase + 45,
        "paceMax": paceBase + 90,
        "cor": const Color(0xFF06B6D4),
      },
      {
        "zona": "Z2",
        "nome": "Aeróbico / Rodagem",
        "descricao": "Construção de base e queima de gordura",
        "paceMin": paceBase + 20,
        "paceMax": paceBase + 45,
        "cor": const Color(0xFF10B981),
      },
      {
        "zona": "Z3",
        "nome": "Limiar de Lactato",
        "descricao": "Ritmo de meia-maratona e esforço sustentado",
        "paceMin": paceBase - 10,
        "paceMax": paceBase + 20,
        "cor": const Color(0xFFF59E0B),
      },
      {
        "zona": "Z4",
        "nome": "Ritmo VO2 Máx",
        "descricao": "Tiros longos e intervalados intensos",
        "paceMin": paceBase - 30,
        "paceMax": paceBase - 10,
        "cor": const Color(0xFFF97316),
      },
      {
        "zona": "Z5",
        "nome": "Velocidade Máxima",
        "descricao": "Sprints curtos e potência anaeróbica",
        "paceMin": max(60, paceBase - 55),
        "paceMax": paceBase - 30,
        "cor": const Color(0xFFEF4444),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Suas Zonas de Ritmo",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Baseadas no seu pace de ${formatarPace(paceBase)}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/zonas"),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ver Zonas",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.cyanAccent
                            : const Color(0xFF0066FF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isDark
                          ? Colors.cyanAccent
                          : const Color(0xFF0066FF),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // LISTA DE ZONAS
          Column(
            children: zonas.map((z) {
              final cor = z["cor"] as Color;
              final pMin = z["paceMin"] as int;
              final pMax = z["paceMax"] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: isDark ? 0.08 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cor.withValues(alpha: isDark ? 0.25 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          z["zona"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              z["nome"] as String,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              z["descricao"] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${_formatarPaceSimples(pMin)} - ${_formatarPaceSimples(pMax)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ⚙️ 5. CENTRAL DE AÇÕES E CONFIGURAÇÕES DA CONTA
  // ===========================================================================
  Widget _buildAccountHub(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Configurações e Conta",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Gerencie seus dados pessoais, ficha e preferências",
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _hubTile(
                icon: Icons.person_outline_rounded,
                title: "Editar Perfil",
                subtitle: "Altere seu nome, pace e objetivo",
                accentColor: const Color(0xFF0066FF),
                isDark: isDark,
                onTap: abrirEditarPerfil,
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.camera_alt_outlined,
                title: "Foto de Perfil",
                subtitle: "Atualizar avatar através da câmera ou galeria",
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
                onTap: abrirOpcoesFoto,
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.badge_outlined,
                title: "Ficha do Atleta",
                subtitle: "Consulte anamnese, biometria e histórico médico",
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, "/ficha"),
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.notifications_none_rounded,
                title: "Notificações e Avisos",
                subtitle: "Lembretes de treinos e comunicados",
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, "/notificacoes"),
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.settings_outlined,
                title: "Preferências do Aplicativo",
                subtitle: "Temas, conexões de GPS e segurança",
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, "/configuracoes"),
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.shield_outlined,
                title: "Privacidade e Termos",
                subtitle: "Consulte nossos termos de uso e política LGPD",
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, "/politica-privacidade"),
              ),
              _divider(isDark),
              _hubTile(
                icon: Icons.logout_rounded,
                title: "Encerrar Sessão",
                subtitle: "Desconectar sua conta do dispositivo",
                accentColor: const Color(0xFFEF4444),
                isDestructive: true,
                isDark: isDark,
                onTap: logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hubTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF1F5F9),
      indent: 64,
      endIndent: 16,
    );
  }

  // ===========================================================================
  // 🧩 CAMPOS E COMPONENTES AUXILIARES
  // ===========================================================================
  Widget _customField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subColor =
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final fill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      final borderColor =
          isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

      return TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: txtColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 14),
          labelStyle: TextStyle(color: subColor, fontSize: 14),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.lightBlueAccent : const Color(0xFF0066FF),
          ),
          filled: true,
          fillColor: fill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF0066FF),
              width: 1.8,
            ),
          ),
        ),
      );
    });
  }

  Widget _fotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subColor =
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      final border =
          isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF)
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0066FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: txtColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subColor,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: subColor,
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }
}
