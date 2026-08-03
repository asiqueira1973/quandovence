// AppConstants.swift — constantes globais do app (spec 7/8.8/11).
//
// Centraliza os valores fixos citados na spec: o identificador do produto de IAP,
// o limite gratuito do paywall, os 4 horários fixos de aviso e os intervalos de
// antecedência. Evita repetir literais soltos pelo código.

import Foundation

enum AppConstants {

    /// Identificador do produto de IAP não-consumível (spec 24, assunção 7).
    static let iapProductID = "quandovence_desbloqueio_completo"

    /// Limite de documentos gratuitos; o 6º exige a compra (spec 3/8.8/11.6).
    static let limiteGratuito = 5

    /// Horários fixos possíveis para envio dos avisos (spec 3/8.6). O índice padrão
    /// é 1 → "09:00" (spec 7 — `horario_aviso_index`).
    static let horariosAviso = ["08:00", "09:00", "12:00", "19:00"]

    /// Intervalos de antecedência configuráveis, em dias (spec 3/8.6/11.3). A
    /// ordem é a mesma exibida em Ajustes no protótipo (90 → 30 → 7 → 1).
    static let intervalosAviso = [90, 30, 7, 1]
}
