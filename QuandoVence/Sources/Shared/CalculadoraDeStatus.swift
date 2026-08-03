// CalculadoraDeStatus.swift — urgência e rótulos de status (spec regras 11.1/11.2).
//
// Toda a lógica de cor, agrupamento e texto de status é DERIVADA em tempo de
// leitura, nunca persistida (spec 7/11) — reproduz fielmente a função `decorate`
// do protótipo. As funções recebem `hoje` explícito (default = início do dia
// local) para permitir teste dos casos de borda da seção 22 sem depender do
// relógio real.

import Foundation
import SwiftUI

/// Faixa de urgência de um documento (spec 11.1). O único "estado" do sistema —
/// sempre recalculado, nunca transicionado (spec 12).
enum Urgencia {
    case vencido        // dias < 0  → vermelho
    case venceEmBreve   // 0...30    → laranja
    case emDia          // > 30      → cinza-neutro

    /// Cor de status correspondente (spec 11.1 / 16). É a cor da barra lateral do
    /// card e do realce no detalhe.
    var cor: Color {
        switch self {
        case .vencido: return Palette.statusRed
        case .venceEmBreve: return Palette.statusOrange
        case .emDia: return Palette.statusNeutral
        }
    }
}

/// Resultado completo do cálculo de status de um documento (spec 11.1/11.2).
struct StatusDocumento {
    let dias: Int            // data_vencimento − hoje (negativo se já venceu)
    let urgencia: Urgencia
    let statusLabel: String  // rótulo curto do card/lista (regra 11.2)
    let bigNumber: String    // número grande da tela de Detalhe
    let bigCaption: String   // legenda do número grande (Detalhe)

    var cor: Color { urgencia.cor }
}

enum CalculadoraDeStatus {

    /// Início do dia (meia-noite local) de uma data — base de todo o cálculo
    /// (spec 11: usa a data local à meia-noite, sem lógica de fuso adicional).
    static func inicioDoDia(_ data: Date, calendario: Calendar = .current) -> Date {
        calendario.startOfDay(for: data)
    }

    /// Início do dia de hoje (`startOfToday` do protótipo).
    static func hoje(calendario: Calendar = .current) -> Date {
        calendario.startOfDay(for: Date())
    }

    // Dias entre hoje e o vencimento (spec 11.1: `dias = data_vencimento − hoje`).
    // Positivo = ainda no futuro; negativo = já vencido. Calculado à meia-noite,
    // então não sofre com horas nem DST.
    static func dias(ate dataVencimento: Date, hoje: Date? = nil, calendario: Calendar = .current) -> Int {
        let base = hoje ?? Self.hoje(calendario: calendario)
        let fim = inicioDoDia(dataVencimento, calendario: calendario)
        return calendario.dateComponents([.day], from: base, to: fim).day ?? 0
    }

    // Faixa de urgência a partir do número de dias (spec 11.1).
    static func urgencia(dias: Int) -> Urgencia {
        if dias < 0 { return .vencido }
        if dias <= 30 { return .venceEmBreve }
        return .emDia
    }

    // Rótulo de status curto (regra 11.2), idêntico ao protótipo:
    //  vencido há 1 → "Venceu ontem"; vencido há N → "Venceu há N dias";
    //  0 → "Vence hoje"; 1 → "Amanhã"; 2–30 → "Em N dias";
    //  31–364 → "Em N meses" (round(dias/30)); ≥365 → "Em N ano(s)"
    //  (floor(dias/365), singular só quando dias < 730).
    static func statusLabel(dias: Int) -> String {
        if dias < 0 {
            return dias == -1 ? "Venceu ontem" : "Venceu há \(-dias) dias"
        }
        if dias == 0 { return "Vence hoje" }
        if dias == 1 { return "Amanhã" }
        if dias <= 30 { return "Em \(dias) dias" }
        if dias < 365 { return "Em \(Int((Double(dias) / 30).rounded())) meses" }
        let anos = dias / 365
        return "Em \(anos)" + (dias < 730 ? " ano" : " anos")
    }

    // Número grande da tela de Detalhe (spec 8.2), idêntico ao protótipo: valor
    // absoluto de dias (sem sinal).
    static func bigNumber(dias: Int) -> String {
        dias < 0 ? String(-dias) : String(dias)
    }

    // Legenda do número grande (spec 8.2), idêntica ao protótipo.
    static func bigCaption(dias: Int) -> String {
        if dias < 0 {
            return dias == -1 ? "dia desde o vencimento" : "dias desde o vencimento"
        }
        if dias == 0 { return "vence hoje" }
        if dias == 1 { return "dia até o vencimento" }
        return "dias até o vencimento"
    }

    // Monta o status completo de um documento (spec 11.1/11.2). É o ponto único
    // usado pela Lista e pelo Detalhe.
    static func status(dataVencimento: Date, hoje: Date? = nil, calendario: Calendar = .current) -> StatusDocumento {
        let d = dias(ate: dataVencimento, hoje: hoje, calendario: calendario)
        return StatusDocumento(
            dias: d,
            urgencia: urgencia(dias: d),
            statusLabel: statusLabel(dias: d),
            bigNumber: bigNumber(dias: d),
            bigCaption: bigCaption(dias: d)
        )
    }
}
