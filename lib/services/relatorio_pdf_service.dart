import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'recomendacao_parecer_service.dart';

class RelatorioPdfService {
  /// Gera o documento PDF em bytes com todas as informações de treino, saúde e parecer.
  static Future<Uint8List> gerarPdfRelatorio({
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? dashboard,
    required Map<String, dynamic>? overtraining,
    required dynamic ultimoACQ5,
    required dynamic ultimoMiniAQLQ,
    required dynamic ultimo3km,
  }) async {
    final parecer = RecomendacaoParecerService.gerar(
      user: user,
      dashboard: dashboard,
      overtraining: overtraining,
      ultimoACQ5: ultimoACQ5,
      ultimoMiniAQLQ: ultimoMiniAQLQ,
      ultimo3km: ultimo3km,
    );

    final pdf = pw.Document();

    final dataAtual = DateFormat("dd/MM/yyyy 'às' HH:mm").format(DateTime.now());

    final nomeAtleta = user?["nome_usuario"]?.toString().trim() ?? "Atleta PaceMind";
    final emailAtleta = user?["email"]?.toString().trim() ?? "-";
    final paceRefSeg = user?["pace_referencia_segundos"];
    final metaSemanal = user?["objetivo_semanal_km"];

    final resumo = dashboard?["resumo"] ?? {};
    final kmTotal = double.tryParse(resumo["total_km"]?.toString() ?? "0") ?? 0.0;
    final ritmoMedio = int.tryParse(resumo["ritmo_medio"]?.toString() ?? "0") ?? 0;
    final totalTreinos = int.tryParse(resumo["total_treinos"]?.toString() ?? "0") ?? 0;
    final acwr = double.tryParse(overtraining?["acwr"]?.toString() ?? "0") ?? 1.0;

    // Formatação de Pace
    String formatarPace(dynamic segundos) {
      if (segundos == null) return "-";
      final total = int.tryParse(segundos.toString()) ?? 0;
      if (total <= 0) return "-";
      final min = total ~/ 60;
      final seg = total % 60;
      return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')} min/km";
    }

    final paceRefStr = formatarPace(paceRefSeg);
    final paceMedioStr = formatarPace(ritmoMedio);

    // Cores oficiais do tema PaceMind
    final primaryColor = PdfColor.fromHex("#0052D4");
    final secondaryBlue = PdfColor.fromHex("#0066FF");
    final slateCard = PdfColor.fromHex("#F8FAFC");
    final slateBorder = PdfColor.fromHex("#E2E8F0");
    final textDark = PdfColor.fromHex("#1E293B");
    final textMuted = PdfColor.fromHex("#64748B");
    final successColor = PdfColor.fromHex("#10B981");
    final dangerColor = PdfColor.fromHex("#EF4444");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: slateBorder, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "PaceMind Analytics • Documento Confidencial do Atleta",
                style: pw.TextStyle(color: textMuted, fontSize: 9),
              ),
              pw.Text(
                "Página ${context.pageNumber} de ${context.pagesCount}",
                style: pw.TextStyle(color: textMuted, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        build: (context) => [
          // 🔵 HEADER DO RELATÓRIO
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "PaceMind",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "RELATÓRIO DE DESEMPENHO E SAÚDE RESPIRATÓRIA",
                      style: pw.TextStyle(
                        color: PdfColor.fromHex("#BAE6FD"),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Emitido em:",
                      style: pw.TextStyle(color: PdfColor.fromHex("#E0F2FE"), fontSize: 9),
                    ),
                    pw.Text(
                      dataAtual,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // 👤 DADOS DO ATLETA
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: slateCard,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: slateBorder),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "ATLETA",
                        style: pw.TextStyle(color: textMuted, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        nomeAtleta,
                        style: pw.TextStyle(color: textDark, fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        emailAtleta,
                        style: pw.TextStyle(color: textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 36, color: slateBorder),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "PACE DE REFERÊNCIA",
                      style: pw.TextStyle(color: textMuted, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      paceRefStr,
                      style: pw.TextStyle(color: secondaryBlue, fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "META SEMANAL",
                      style: pw.TextStyle(color: textMuted, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      metaSemanal != null ? "$metaSemanal km" : "Sem meta",
                      style: pw.TextStyle(color: textDark, fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // 🏃 KPI STRIP (Grid de 4 métricas)
          pw.Row(
            children: [
              _buildPdfKpiCard(
                titulo: "DISTÂNCIA TOTAL",
                valor: "${kmTotal.toStringAsFixed(1)} km",
                subtitulo: "Volume acumulado",
                cor: secondaryBlue,
                slateCard: slateCard,
                slateBorder: slateBorder,
                textDark: textDark,
                textMuted: textMuted,
              ),
              pw.SizedBox(width: 10),
              _buildPdfKpiCard(
                titulo: "TREINOS FEITOS",
                valor: "$totalTreinos",
                subtitulo: "Sessões concluídas",
                cor: successColor,
                slateCard: slateCard,
                slateBorder: slateBorder,
                textDark: textDark,
                textMuted: textMuted,
              ),
              pw.SizedBox(width: 10),
              _buildPdfKpiCard(
                titulo: "PACE MÉDIO GERAL",
                valor: paceMedioStr,
                subtitulo: "Média de velocidade",
                cor: secondaryBlue,
                slateCard: slateCard,
                slateBorder: slateBorder,
                textDark: textDark,
                textMuted: textMuted,
              ),
              pw.SizedBox(width: 10),
              _buildPdfKpiCard(
                titulo: "CARGA (ACWR)",
                valor: "${acwr.toStringAsFixed(2)}x",
                subtitulo: acwr > 1.5 ? "Alto Risco" : "Equilibrado",
                cor: acwr > 1.5 ? dangerColor : successColor,
                slateCard: slateCard,
                slateBorder: slateBorder,
                textDark: textDark,
                textMuted: textMuted,
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // 📊 1. TABELA DE PERFORMANCE DE CORRIDA
          pw.Text(
            "1. DESEMPENHO E INDICADORES DE CORRIDA",
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: slateBorder, width: 0.8),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: slateCard),
                children: [
                  _tableHeaderCell("Indicador"),
                  _tableHeaderCell("Valor Registrado"),
                  _tableHeaderCell("Parâmetro de Referência / Status"),
                ],
              ),
              _tableDataRow(
                "Quilometragem Total",
                "${kmTotal.toStringAsFixed(1)} km",
                "Volume total registrado no aplicativo",
                textDark,
                textMuted,
              ),
              _tableDataRow(
                "Treinos Concluídos",
                "$totalTreinos treinos",
                "Frequência de treinamento registrada",
                textDark,
                textMuted,
              ),
              _tableDataRow(
                "Pace Médio Geral",
                paceMedioStr,
                "Ritmo médio ponderado das sessões",
                textDark,
                textMuted,
              ),
              _tableDataRow(
                "Índice Agudo/Crônico (ACWR)",
                "${acwr.toStringAsFixed(2)}x",
                acwr > 1.5
                    ? "Zona de Alto Risco (>1.5x): Atenção a lesões"
                    : "Zona Segura / Sweet Spot (0.8x - 1.3x)",
                textDark,
                textMuted,
              ),
              if (ultimo3km != null)
                _tableDataRow(
                  "Velocidade Aeróbica Máx. (vVO2max)",
                  "${ultimo3km['vvo2max_kmh'] ?? '-'} km/h",
                  "Apurado via Teste de Campo de 3km",
                  textDark,
                  textMuted,
                ),
            ],
          ),

          pw.SizedBox(height: 20),

          // 🫁 2. SAÚDE RESPIRATÓRIA E AVALIAÇÃO CLÍNICA
          pw.Text(
            "2. SAÚDE RESPIRATÓRIA E CONTROLE DE ASMA",
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.3,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: slateBorder, width: 0.8),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: slateCard),
                children: [
                  _tableHeaderCell("Avaliação Clínica"),
                  _tableHeaderCell("Pontuação"),
                  _tableHeaderCell("Classificação Clínica"),
                  _tableHeaderCell("Data"),
                ],
              ),
              _tableDataRow4(
                "Score ACQ-5 (Controle)",
                ultimoACQ5 != null ? "${ultimoACQ5['pontuacao_media']} pts" : "Nenhum",
                ultimoACQ5 != null
                    ? (ultimoACQ5['classificacao'] ?? "Controlada")
                    : "Sem registros",
                ultimoACQ5 != null
                    ? (ultimoACQ5['criado_em']?.toString().split("T")[0] ?? "-")
                    : "-",
                textDark,
                textMuted,
              ),
              _tableDataRow4(
                "MiniAQLQ (Qualidade de Vida)",
                ultimoMiniAQLQ != null
                    ? "${ultimoMiniAQLQ['pontuacao_media']} / 7.0 pts"
                    : "Nenhum",
                ultimoMiniAQLQ != null
                    ? (ultimoMiniAQLQ['classificacao'] ?? "Excelente")
                    : "Sem registros",
                ultimoMiniAQLQ != null
                    ? (ultimoMiniAQLQ['criado_em']?.toString().split("T")[0] ?? "-")
                    : "-",
                textDark,
                textMuted,
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // 🩺 3. PARECER TÉCNICO PARA O TREINADOR E MÉDICO
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: slateCard,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: slateBorder),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex(parecer.corHexStatus),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          "3. PARECER TÉCNICO DE PRESCRIÇÃO E SEGURANÇA",
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex("#E2E8F0"),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        parecer.badgeTexto.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex(parecer.corHexStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  parecer.diagnosticoCarga,
                  style: pw.TextStyle(color: textDark, fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  parecer.avaliacaoRespiratoria,
                  style: pw.TextStyle(color: textDark, fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  parecer.prescricaoVelocidade,
                  style: pw.TextStyle(color: textDark, fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "DIRETRIZES PRÁTICAS INDIVIDUALIZADAS:",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...parecer.diretrizesPraticas.map(
                  (diretriz) => _bulletPdf(diretriz, textMuted),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // AVISO LEGAL
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber300, width: 0.8),
            ),
            child: pw.Text(
              "Aviso Legal: Este documento é gerado pelo aplicativo PaceMind para fins de monitoramento e apoio ao treinamento físico. "
              "Não substitui laudo médico formal ou exame clínico presencial. Consulte seu pneumologista e educador físico regularmente.",
              style: pw.TextStyle(color: PdfColors.amber900, fontSize: 8.5, height: 1.3),
            ),
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  // ===========================================================================
  // 🚀 AÇÕES DE COMPARTILHAMENTO E SALVAMENTO
  // ===========================================================================

  /// Compartilha o PDF diretamente via WhatsApp, E-mail, Telegram, Drive, etc.
  static Future<void> compartilharPdf({
    required Uint8List pdfBytes,
    required String nomeAtleta,
  }) async {
    final nomeFormatado = nomeAtleta.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final dataStr = DateFormat("yyyyMMdd").format(DateTime.now());
    final nomeArquivo = "relatorio_pacemind_${nomeFormatado}_$dataStr.pdf";

    // Utiliza Printing.sharePdf para acionar a folha de compartilhamento nativa com suporte completo a apps (WhatsApp, etc.)
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: nomeArquivo,
    );
  }

  /// Salva o arquivo PDF no armazenamento local do dispositivo
  static Future<String> salvarNoDispositivo({
    required Uint8List pdfBytes,
    required String nomeAtleta,
  }) async {
    final nomeFormatado = nomeAtleta.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final dataStr = DateFormat("yyyyMMdd_HHmm").format(DateTime.now());
    final nomeArquivo = "relatorio_pacemind_${nomeFormatado}_$dataStr.pdf";

    Directory? diretorio;

    if (Platform.isAndroid) {
      diretorio = await getExternalStorageDirectory();
      // Tenta a pasta de Downloads caso esteja disponível
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        diretorio = downloads;
      }
    } else {
      diretorio = await getApplicationDocumentsDirectory();
    }

    diretorio ??= await getApplicationDocumentsDirectory();

    final filePath = "${diretorio.path}/$nomeArquivo";
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    return filePath;
  }

  /// Abre a tela nativa de pré-visualização e impressão do sistema
  static Future<void> visualizarOuImprimirPdf({
    required Uint8List pdfBytes,
    required String nomeAtleta,
  }) async {
    final nomeFormatado = nomeAtleta.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final dataStr = DateFormat("yyyyMMdd").format(DateTime.now());

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: "relatorio_pacemind_${nomeFormatado}_$dataStr",
    );
  }

  // ===========================================================================
  // 🧩 HELPERS DO PDF
  // ===========================================================================
  static pw.Widget _buildPdfKpiCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required PdfColor cor,
    required PdfColor slateCard,
    required PdfColor slateBorder,
    required PdfColor textDark,
    required PdfColor textMuted,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: slateCard,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: slateBorder),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: pw.TextStyle(color: textMuted, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              valor,
              style: pw.TextStyle(color: cor, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitulo,
              style: pw.TextStyle(color: textMuted, fontSize: 7.5),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex("#0F172A"),
        ),
      ),
    );
  }

  static pw.TableRow _tableDataRow(
    String col1,
    String col2,
    String col3,
    PdfColor textDark,
    PdfColor textMuted,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col1, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col2, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#0066FF"))),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col3, style: pw.TextStyle(fontSize: 8, color: textMuted)),
        ),
      ],
    );
  }

  static pw.TableRow _tableDataRow4(
    String col1,
    String col2,
    String col3,
    String col4,
    PdfColor textDark,
    PdfColor textMuted,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col1, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col2, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#10B981"))),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col3, style: pw.TextStyle(fontSize: 8, color: textMuted)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(col4, style: pw.TextStyle(fontSize: 8, color: textMuted)),
        ),
      ],
    );
  }

  static pw.Widget _bulletPdf(String texto, PdfColor cor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4),
            width: 3.5,
            height: 3.5,
            decoration: pw.BoxDecoration(color: PdfColor.fromHex("#0066FF"), shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(texto, style: pw.TextStyle(fontSize: 8.5, color: cor, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
