class AppDateUtils {
  /// Formata uma data para exibição no padrão brasileiro (dd/MM/yyyy ou dd/MM/yyyy às HH:mm).
  /// Evita qualquer variação de timezone que retroceda 1 dia em fusos como o de Brasília (UTC-3).
  static String formatarData(dynamic dataRaw, {bool incluirHoraSeHouver = true}) {
    if (dataRaw == null) return "Hoje";

    // 1. Se já for instância de DateTime
    if (dataRaw is DateTime) {
      final dia = dataRaw.day.toString().padLeft(2, '0');
      final mes = dataRaw.month.toString().padLeft(2, '0');
      final ano = dataRaw.year;
      if (incluirHoraSeHouver && (dataRaw.hour != 0 || dataRaw.minute != 0)) {
        final h = dataRaw.hour.toString().padLeft(2, '0');
        final m = dataRaw.minute.toString().padLeft(2, '0');
        return "$dia/$mes/$ano às $h:$m";
      }
      return "$dia/$mes/$ano";
    }

    final str = dataRaw.toString().trim();
    if (str.isEmpty) return "Hoje";

    try {
      // 2. Se já estiver no formato brasileiro DD/MM/YYYY
      final matchBr = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(str);
      if (matchBr != null) {
        return str;
      }

      // 3. Caso o formato inicie com YYYY-MM-DD
      final regexIso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
      final matchIso = regexIso.firstMatch(str);

      if (matchIso != null) {
        final ano = matchIso.group(1)!;
        final mes = matchIso.group(2)!;
        final dia = matchIso.group(3)!;

        // Se tem horário real (diferente de T00:00:00 ou T12:00:00 de proteção)
        if (incluirHoraSeHouver && (str.contains("T") || str.contains(" "))) {
          final parteHora = str.contains("T") ? str.split("T")[1] : str.split(" ")[1];
          if (!parteHora.startsWith("00:00:00") && !parteHora.startsWith("12:00:00")) {
            final dt = DateTime.tryParse(str);
            if (dt != null) {
              final local = dt.toLocal();
              final h = local.hour.toString().padLeft(2, '0');
              final m = local.minute.toString().padLeft(2, '0');
              return "$dia/$mes/$ano às $h:$m";
            }
          }
        }

        return "$dia/$mes/$ano";
      }

      // 4. Fallback com DateTime.tryParse
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final dia = dt.day.toString().padLeft(2, '0');
        final mes = dt.month.toString().padLeft(2, '0');
        final ano = dt.year;
        return "$dia/$mes/$ano";
      }
    } catch (_) {}

    return str;
  }

  /// Extrai apenas a data (sem hora) para comparação de dias de treino e metas
  static DateTime? extrairDataPura(dynamic dataRaw) {
    if (dataRaw == null) return null;
    if (dataRaw is DateTime) {
      return DateTime(dataRaw.year, dataRaw.month, dataRaw.day);
    }

    final str = dataRaw.toString().trim();
    if (str.isEmpty) return null;

    // 1. Formato brasileiro DD/MM/YYYY
    final matchBr = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(str);
    if (matchBr != null) {
      final dia = int.tryParse(matchBr.group(1)!);
      final mes = int.tryParse(matchBr.group(2)!);
      final ano = int.tryParse(matchBr.group(3)!);
      if (ano != null && mes != null && dia != null) {
        return DateTime(ano, mes, dia);
      }
    }

    // 2. Formato ISO YYYY-MM-DD
    final matchIso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(str);
    if (matchIso != null) {
      final ano = int.tryParse(matchIso.group(1)!);
      final mes = int.tryParse(matchIso.group(2)!);
      final dia = int.tryParse(matchIso.group(3)!);
      if (ano != null && mes != null && dia != null) {
        return DateTime(ano, mes, dia);
      }
    }

    // 3. Fallback
    final dt = DateTime.tryParse(str);
    if (dt != null) {
      return DateTime(dt.year, dt.month, dt.day);
    }

    return null;
  }

  /// Retorna data pura 'YYYY-MM-DD' ideal para colunas SQL tipo DATE
  static String paraDataPura(DateTime data) {
    final a = data.year.toString().padLeft(4, '0');
    final m = data.month.toString().padLeft(2, '0');
    final d = data.day.toString().padLeft(2, '0');
    return "$a-$m-$d";
  }

  /// Converte DateTime para string no formato ISO local seguro para envio à API.
  static String paraIsoLocal(DateTime data, {bool usarMeioDia = true}) {
    if (usarMeioDia) {
      final segura = DateTime(data.year, data.month, data.day, 12, 0, 0);
      return segura.toIso8601String();
    }
    return data.toIso8601String();
  }
}
