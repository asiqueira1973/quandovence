// AgendadorDeAvisos.swift — módulo de notificações locais (spec 13, regras 11.3/11.4).
//
// Garante o princípio 0.5: todo documento cadastrado tem aviso agendado; a ausência
// de aviso é sempre escolha explícita da pessoa em Ajustes, nunca esquecimento do
// app. Usa `UNCalendarNotificationTrigger` (sem push remoto — não há servidor,
// spec 4). Identificadores são previsíveis (`"<uuid>-90"`, `"<uuid>-0"`...) para
// permitir cancelar/reagendar sem deixar notificação órfã (spec 13/8.7).
//
// Regra 11.3: para cada intervalo ativo (90/30/7/1) cuja data resultante ainda
// esteja no futuro, uma notificação; MAIS uma sempre no dia exato do vencimento
// (identificador "-0"), independente dos toggles — essa nunca é desligável.
// Regra 11.4: qualquer mudança cancela as pendentes do documento e recria do zero.

import Foundation
import UserNotifications

enum AgendadorDeAvisos {

    /// Identificador "0" reservado ao aviso do dia exato do vencimento (regra 11.3).
    private static let idDiaDoVencimento = 0

    /// Todos os sufixos de identificador que um documento pode ter: os 4 intervalos
    /// + o dia do vencimento (spec 13). Usado para cancelar sem sobrar órfã.
    private static let sufixos = AppConstants.intervalosAviso + [idDiaDoVencimento]

    // Solicita permissão de notificação se ainda não foi concedida nem negada
    // (spec 8.7 / assunção 6 — pedida no 1º cadastro, não no launch). Devolve se o
    // app está autorizado ao final. O cadastro NUNCA é bloqueado por recusa (spec 8.7).
    @discardableResult
    static func solicitarPermissaoSeNecessario() async -> Bool {
        let centro = UNUserNotificationCenter.current()
        let settings = await centro.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let concedido = (try? await centro.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return concedido
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    // Status atual de autorização (spec 8.7) — usado pela Lista para mostrar o aviso
    // discreto de "notificações desativadas" quando negada.
    static func statusAutorizacao() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // Agenda (ou reagenda) todos os avisos de UM documento (regra 11.3). Cancela
    // primeiro os pendentes daquele documento para nunca duplicar (regra 11.4).
    // Agenda mesmo sem permissão concedida — o SO simplesmente não entrega; assim
    // a pessoa não perde avisos se conceder a permissão depois (spec 9).
    static func agendar(documento: Documento, config: ConfiguracaoAvisos, agora: Date = Date()) {
        cancelar(documentoId: documento.id)

        let centro = UNUserNotificationCenter.current()
        let calendario = Calendar.current
        let (hora, minuto) = config.horaMinuto
        let diaVencimento = calendario.startOfDay(for: documento.data_vencimento)

        // Um aviso por intervalo ativo cuja data/hora resultante ainda seja futura.
        for intervalo in config.intervalosAtivos {
            guard let dia = calendario.date(byAdding: .day, value: -intervalo, to: diaVencimento) else { continue }
            agendarSe(centro: centro, calendario: calendario, dia: dia, hora: hora, minuto: minuto,
                      agora: agora, identificador: "\(documento.id.uuidString)-\(intervalo)",
                      corpo: corpo(nome: documento.nome, diasAntes: intervalo))
        }

        // Aviso do dia exato do vencimento — sempre (regra 11.3), se ainda no futuro.
        agendarSe(centro: centro, calendario: calendario, dia: diaVencimento, hora: hora, minuto: minuto,
                  agora: agora, identificador: "\(documento.id.uuidString)-\(idDiaDoVencimento)",
                  corpo: corpo(nome: documento.nome, diasAntes: 0))
    }

    // Cancela TODAS as notificações pendentes de um documento (spec 13/8.5/8.7).
    // Remove os 5 identificadores previsíveis — nunca deixa órfã.
    static func cancelar(documentoId: UUID) {
        let ids = sufixos.map { "\(documentoId.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Reagenda do zero para TODOS os documentos (regra 11.4). Chamado quando os
    // toggles ou o horário de Ajustes mudam (spec 8.6) — cancela e recria tudo.
    static func reagendarTudo(documentos: [Documento], config: ConfiguracaoAvisos, agora: Date = Date()) {
        for documento in documentos {
            agendar(documento: documento, config: config, agora: agora)
        }
    }

    // --- internos --------------------------------------------------------

    // Agenda uma notificação para (dia + hora:minuto) só se esse instante ainda for
    // futuro em relação a `agora` (regra 11.3 — "ainda esteja no futuro").
    private static func agendarSe(centro: UNUserNotificationCenter, calendario: Calendar,
                                  dia: Date, hora: Int, minuto: Int, agora: Date,
                                  identificador: String, corpo: String) {
        var componentes = calendario.dateComponents([.year, .month, .day], from: dia)
        componentes.hour = hora
        componentes.minute = minuto
        guard let dataDisparo = calendario.date(from: componentes), dataDisparo > agora else { return }

        let conteudo = UNMutableNotificationContent()
        conteudo.title = "Quando Vence?"
        conteudo.body = corpo
        conteudo.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendario.dateComponents([.year, .month, .day, .hour, .minute], from: dataDisparo),
            repeats: false)
        centro.add(UNNotificationRequest(identifier: identificador, content: conteudo, trigger: trigger))
    }

    // Texto do corpo da notificação (copy criada aqui — o protótipo não define copy
    // de notificação; registrado como adição em DOCUMENTACAO-TECNICA, spec 19.6).
    // Tom direto, coerente com a spec 15.
    private static func corpo(nome: String, diasAntes: Int) -> String {
        switch diasAntes {
        case 0: return "\(nome) vence hoje."
        case 1: return "\(nome) vence amanhã."
        default: return "\(nome) vence em \(diasAntes) dias."
        }
    }
}
