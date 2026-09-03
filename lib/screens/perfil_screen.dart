import 'package:flutter/material.dart';
import '/core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;

  File? imagemSelecionada;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  void abrirEditarPerfil() {
    final nomeController = TextEditingController(text: user!["nome_usuario"]);

    final objetivoController = TextEditingController(
      text: user!["objetivo_semanal_km"]?.toString(),
    );

    int paceAtual = user!["pace_referencia_segundos"] ?? 300;

    int minutosSelecionados = (paceAtual ~/ 60).clamp(3, 15);

    int segundosSelecionados = (paceAtual % 60).clamp(0, 59);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final isSmallScreen = screenWidth < 360;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: 20,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.88,
              maxWidth: 460,
            ),
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 22,
              18,
              isSmallScreen ? 16 : 22,
              22,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.lightBlueAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Editar perfil",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Mantenha seus dados atualizados",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: "Fechar",
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 👤 NOME
                  _customField(
                    controller: nomeController,
                    label: "Nome",
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 16),

                  // 🏃 PACE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed, color: Colors.lightBlueAccent),

                          SizedBox(width: 8),

                          Text(
                            "Pace de referência",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      StatefulBuilder(
                        builder: (context, setModalState) {
                          const selectBackground = Color(0xFF1E293B);
                          const selectText = Colors.white;
                          const selectIcon = Colors.cyanAccent;

                          return Row(
                            children: [
                              // ⏱️ MINUTOS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Minutos",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<int>(
                                        isExpanded: true,
                                        initialValue: minutosSelecionados,

                                        dropdownColor: selectBackground,

                                        menuMaxHeight: 250,

                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),

                                        style: const TextStyle(
                                          color: selectText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),

                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: selectIcon,
                                        ),

                                        items: List.generate(
                                          13,
                                          (index) => DropdownMenuItem(
                                            value: index + 3,
                                            child: Text(
                                              "${index + 3} min",
                                              style: const TextStyle(
                                                color: selectText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),

                                        onChanged: (value) {
                                          setModalState(() {
                                            minutosSelecionados = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // ⏱️ SEGUNDOS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Segundos",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<int>(
                                        isExpanded: true,
                                        initialValue: segundosSelecionados,

                                        menuMaxHeight: 250,

                                        dropdownColor: selectBackground,

                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),

                                        style: const TextStyle(
                                          color: selectText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),

                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: selectIcon,
                                        ),

                                        items: List.generate(60, (index) {
                                          final valor = index;

                                          return DropdownMenuItem(
                                            value: valor,
                                            child: Text(
                                              valor.toString().padLeft(2, '0'),
                                              style: const TextStyle(
                                                color: selectText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }),

                                        onChanged: (value) {
                                          setModalState(() {
                                            segundosSelecionados = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 🔥 PREVIEW
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Pace Atual: "
                          "${minutosSelecionados.toString()}:"
                          "${segundosSelecionados.toString().padLeft(2, '0')} min/km",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🎯 META
                  _customField(
                    controller: objetivoController,
                    label: "Meta semanal (km)",
                    icon: Icons.flag,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 30),

                  // 🔘 BOTÕES
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final atualizado = await Api.atualizarPerfil(
                                nome: nomeController.text,
                                pace:
                                    (minutosSelecionados * 60) +
                                    segundosSelecionados,
                                objetivo: double.tryParse(
                                  objetivoController.text,
                                ),
                              );

                              if (!mounted) return;
                              setState(() {
                                user = atualizado;
                              });

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Perfil atualizado!"),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Erro ao atualizar"),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Salvar",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String formatarPace(dynamic segundos) {
    if (segundos == null) return "-";

    final totalSegundos = segundos.toInt();

    final minutos = totalSegundos ~/ 60;
    final seg = totalSegundos % 60;

    final minStr = minutos.toString().padLeft(2, '0');
    final segStr = seg.toString().padLeft(2, '0');

    return "$minStr:$segStr min/km";
  }

  Future<void> uploadImagem() async {
    if (imagemSelecionada == null) return;

    try {
      final response = await Api.uploadFoto(imagemSelecionada!);

      // backend deve retornar foto_url
      setState(() {
        user!["foto_url"] = response["foto_url"];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Foto atualizada!")));
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  Future<void> escolherImagem(ImageSource source) async {
    final XFile? imagem = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (imagem == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: imagem.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Ajustar foto', lockAspectRatio: true),
        IOSUiSettings(title: 'Ajustar foto'),
      ],
    );

    if (cropped != null) {
      setState(() {
        imagemSelecionada = File(cropped.path);
      });

      await uploadImagem();
    }
  }

  void abrirOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (bottomSheetContext) {
        final screenWidth = MediaQuery.of(bottomSheetContext).size.width;
        final isSmall = screenWidth < 360;

        return Container(
          margin: EdgeInsets.all(isSmall ? 8 : 12),
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),

          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 BARRINHA
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: Colors.lightBlueAccent,
                        size: 26,
                      ),

                      SizedBox(width: 10),

                      Text(
                        "Alterar foto",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 📷 CAMERA
                  _fotoOption(
                    icon: Icons.camera_alt_rounded,
                    title: "Tirar foto",
                    subtitle: "Usar a câmera do dispositivo",
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      escolherImagem(ImageSource.camera);
                    },
                  ),

                  const SizedBox(height: 14),

                  // 🖼️ GALERIA
                  _fotoOption(
                    icon: Icons.photo_library_rounded,
                    title: "Escolher da galeria",
                    subtitle: "Selecionar imagem salva",
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      escolherImagem(ImageSource.gallery);
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> carregarPerfil() async {
    try {
      final data = await Api.getProfile();
      if (!mounted) return;

      setState(() {
        user = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Erro ao carregar perfil")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Stack(
        children: [
          // 🔵 BACKGROUND
          // Positioned(
          //   top: -120,
          //   right: -80,
          //   child: Container(
          //     width: 260,
          //     height: 260,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: Colors.blue.withOpacity(0.10),
          //     ),
          //   ),
          // ),

          // Positioned(
          //   bottom: -100,
          //   left: -80,
          //   child: Container(
          //     width: 240,
          //     height: 240,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: Colors.cyan.withOpacity(0.08),
          //     ),
          //   ),
          // ),
          RefreshIndicator(
            onRefresh: carregarPerfil,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              child: Column(
                children: [
                  // 🔥 HEADER
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 318),
                    padding: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0057FF), Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: abrirEditarPerfil,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    "/configuracoes",
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.settings_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 👤 FOTO
                          GestureDetector(
                            onTap: abrirOpcoesFoto,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: MediaQuery.of(context).size.width < 360 ? 54 : 62,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      user!["foto_url"] != null &&
                                          user!["foto_url"]
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(user!["foto_url"])
                                      : null,
                                  child:
                                      user!["foto_url"] == null ||
                                          user!["foto_url"].toString().isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: MediaQuery.of(context).size.width < 360 ? 58 : 70,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),

                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              user!["nome_usuario"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              user!["email"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📦 CARDS
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 360 ? 14 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Resumo do perfil",
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Seus parâmetros atuais de treinamento",
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _modernTile(
                          context,
                          Icons.speed_rounded,
                          "Pace de referência",
                          formatarPace(user!["pace_referencia_segundos"]),
                        ),

                        const SizedBox(height: 14),

                        _modernTile(
                          context,
                          Icons.flag_rounded,
                          "Meta semanal",
                          user!["objetivo_semanal_km"] != null
                              ? "${user!["objetivo_semanal_km"]} km"
                              : "-",
                        ),

                        const SizedBox(height: 14),

                        _modernTile(
                          context,
                          Icons.calendar_month_rounded,
                          "Conta criada",
                          user!["criado_em"] ?? "-",
                        ),

                        // const SizedBox(height: 20),

                        // SizedBox(
                        //   width: double.infinity,
                        //   child: OutlinedButton.icon(
                        //     onPressed: abrirEditarPerfil,
                        //     icon: const Icon(Icons.edit_rounded),
                        //     label: const Text("Editar informações"),
                        //     style: OutlinedButton.styleFrom(
                        //       foregroundColor: colors.primary,
                        //       side: BorderSide(
                        //         color: colors.primary.withValues(alpha: .35),
                        //       ),
                        //       padding: const EdgeInsets.symmetric(vertical: 15),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(16),
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        // const SizedBox(height: 28),

                        // // ✏️ EDITAR
                        // SizedBox(
                        //   width: double.infinity,

                        //   child: ElevatedButton.icon(
                        //     onPressed: abrirEditarPerfil,

                        //     icon: const Icon(Icons.edit),

                        //     label: const Text("Editar perfil"),

                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: const Color(0xFF0066FF),

                        //       foregroundColor: Colors.white,

                        //       elevation: 0,

                        //       padding: const EdgeInsets.symmetric(vertical: 18),

                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(18),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 14),

                        // 🚪 LOGOUT
                        // SizedBox(
                        //   width: double.infinity,

                        //   child: ElevatedButton.icon(
                        //     onPressed: logout,

                        //     icon: const Icon(Icons.logout),

                        //     label: const Text("Sair"),

                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.red,
                        //       foregroundColor: Colors.white,
                        //       elevation: 0,

                        //       padding: const EdgeInsets.symmetric(vertical: 18),

                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(18),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),

        prefixIcon: Icon(icon, color: Colors.lightBlueAccent),

        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.lightBlueAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _fotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),

        child: Row(
          children: [
            // 🔥 ÍCONE
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.lightBlueAccent, size: 28),
            ),

            const SizedBox(width: 16),

            // 📝 TEXTOS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isSmall = MediaQuery.of(context).size.width < 360;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 14 : 20,
          vertical: isSmall ? 14 : 18,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(isSmall ? 22 : 30),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 12 : 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                ),
                borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
              ),
              child: Icon(icon, color: Colors.white, size: isSmall ? 22 : 26),
            ),
            SizedBox(width: isSmall ? 12 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: isSmall ? 12.5 : 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
