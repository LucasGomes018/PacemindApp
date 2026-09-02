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

    final paceController = TextEditingController(
      text: user!["pace_referencia_segundos"]?.toString(),
    );

    final objetivoController = TextEditingController(
      text: user!["objetivo_semanal_km"]?.toString(),
    );

    int paceAtual = user!["pace_referencia_segundos"] ?? 300;

    int minutosSelecionados = (paceAtual ~/ 60).clamp(3, 15);

    int segundosSelecionados = (paceAtual % 60).clamp(0, 59);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 HEADER
                  Row(
                    children: const [
                      Icon(
                        Icons.edit_rounded,
                        color: Colors.lightBlueAccent,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Editar Perfil",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

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
                          return Row(
                            children: [
                              // ⏱️ MINUTOS
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    initialValue: minutosSelecionados,

                                    dropdownColor: const Color(0xFF1E293B),

                                    menuMaxHeight: 250,

                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),

                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.cyanAccent,
                                    ),

                                    items: List.generate(
                                      13,
                                      (index) => DropdownMenuItem(
                                        value: index + 3,
                                        child: Text("${index + 3} min"),
                                      ),
                                    ),

                                    onChanged: (value) {
                                      setModalState(() {
                                        minutosSelecionados = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // ⏱️ SEGUNDOS
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    initialValue: segundosSelecionados,

                                    menuMaxHeight: 250,

                                    dropdownColor: const Color(0xFF1E293B),

                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),

                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.cyanAccent,
                                    ),

                                    items: List.generate(60, (index) {
                                      final valor = index;

                                      return DropdownMenuItem(
                                        value: valor,
                                        child: Text(
                                          valor.toString().padLeft(2, '0'),
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
                          onPressed: () => Navigator.pop(context),
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

                              setState(() {
                                user = atualizado;
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Perfil atualizado!"),
                                ),
                              );
                            } catch (e) {
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
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
                    Navigator.pop(context);
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
                    Navigator.pop(context);
                    escolherImagem(ImageSource.gallery);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> carregarPerfil() async {
    try {
      final data = await Api.getProfile();

      setState(() {
        user = data;
        loading = false;
      });
    } catch (e) {
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
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightBlueAccent),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Erro ao carregar perfil")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

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
                    height: 340,
                    width: double.infinity,

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
                      child: Column(
                        children: [
                          const SizedBox(height: 25),

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
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(18),
                                    ),

                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(18),
                                  ),

                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // 👤 FOTO
                          GestureDetector(
                            onTap: abrirOpcoesFoto,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 62,
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
                                      ? const Icon(
                                          Icons.person,
                                          size: 70,
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

                          const SizedBox(height: 18),

                          Text(
                            user!["nome_usuario"] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            user!["email"] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📦 CARDS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Column(
                      children: [
                        _modernTile(
                          Icons.speed_rounded,
                          "Pace de referência",
                          formatarPace(user!["pace_referencia_segundos"]),
                        ),

                        const SizedBox(height: 14),

                        _modernTile(
                          Icons.flag_rounded,
                          "Meta semanal",
                          user!["objetivo_semanal_km"] != null
                              ? "${user!["objetivo_semanal_km"]} km"
                              : "-",
                        ),

                        const SizedBox(height: 14),

                        _modernTile(
                          Icons.calendar_month_rounded,
                          "Conta criada",
                          user!["criado_em"] ?? "-",
                        ),

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
                        const SizedBox(height: 40),
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

  Widget _infoTile(String title, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          218,
          203,
          240,
          255,
        ), // 👈 fundo mais visível
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value?.toString() ?? "-",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: 0.5,
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

  Widget _modernTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),

        borderRadius: BorderRadius.circular(30),

        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
              ),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Icon(icon, color: Colors.white, size: 26),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),

      child: Column(
        children: [
          Icon(icon, color: Colors.white),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
