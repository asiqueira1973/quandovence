// ConfiguracaoAvisos.swift — snapshot das preferências de aviso (spec 7/8.6).
//
// Os ajustes de aviso NÃO são tabela: são 5 escalares em `@AppStorage`/UserDefaults
// (spec 7). Esta struct é o snapshot imutável que o `AgendadorDeAvisos` recebe para
// agendar/reagendar (spec 13) sem depender de SwiftUI. As chaves e os defaults são
// exatamente os da seção 7 (90/30/7 ligados, 1 dia desligado, horário índice 1 =
// 09:00). Registrar os defaults (spec) garante que o serviço e a UI leiam o mesmo
// valor mesmo antes de a pessoa abrir Ajustes.

import Foundation

enum ChavesAviso {
    static let aviso90 = "aviso_90_dias"
    static let aviso30 = "aviso_30_dias"
    static let aviso7 = "aviso_7_dias"
    static let aviso1 = "aviso_1_dia"
    static let horarioIndex = "horario_aviso_index"

    /// Defaults da seção 7 — registrados na abertura do app.
    static let defaults: [String: Any] = [
        aviso90: true, aviso30: true, aviso7: true, aviso1: false, horarioIndex: 1,
    ]
}

/// Snapshot das preferências de aviso num instante (spec 7/8.6/11.3).
struct ConfiguracaoAvisos {
    var aviso90: Bool
    var aviso30: Bool
    var aviso7: Bool
    var aviso1: Bool
    var horarioIndex: Int

    // Lê o estado atual dos ajustes do UserDefaults (spec 7). Usa os defaults da
    // seção 7 quando a chave ainda não existe.
    init(defaults: UserDefaults = .standard) {
        defaults.register(defaults: ChavesAviso.defaults)
        aviso90 = defaults.bool(forKey: ChavesAviso.aviso90)
        aviso30 = defaults.bool(forKey: ChavesAviso.aviso30)
        aviso7 = defaults.bool(forKey: ChavesAviso.aviso7)
        aviso1 = defaults.bool(forKey: ChavesAviso.aviso1)
        horarioIndex = defaults.integer(forKey: ChavesAviso.horarioIndex)
    }

    /// Intervalos de antecedência ligados, em dias, na ordem 90→30→7→1 (spec 8.6).
    /// Base do resumo "90, 30, 7 dias antes" e do agendamento (regra 11.3).
    var intervalosAtivos: [Int] {
        var out: [Int] = []
        if aviso90 { out.append(90) }
        if aviso30 { out.append(30) }
        if aviso7 { out.append(7) }
        if aviso1 { out.append(1) }
        return out
    }

    /// Hora e minuto configurados, a partir do índice no array fixo (spec 3/7).
    var horaMinuto: (hora: Int, minuto: Int) {
        let idx = min(max(horarioIndex, 0), AppConstants.horariosAviso.count - 1)
        let partes = AppConstants.horariosAviso[idx].split(separator: ":")
        return (Int(partes[0]) ?? 9, Int(partes[1]) ?? 0)
    }

    /// Rótulo dos avisos ativos para o Detalhe (spec 8.2) — ex.: "90, 30, 7 dias
    /// antes" ou "Desativados" se nenhum intervalo estiver ligado. O aviso do dia
    /// exato (regra 11.3) é sempre enviado e não entra nesse rótulo.
    var rotuloAvisos: String {
        let ativos = intervalosAtivos
        return ativos.isEmpty ? "Desativados" : ativos.map(String.init).joined(separator: ", ") + " dias antes"
    }
}
