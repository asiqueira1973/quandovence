// AccessibilityLabels.swift — rótulos de VoiceOver (spec 17).
//
// A spec exige que cada card da lista seja lido como uma frase única e descritiva
// ("CNH, vence em 18 dias") em vez de os elementos soltos (spec 17). Centraliza a
// construção desses rótulos para manter consistência.

import Foundation

enum AccessibilityLabels {

    // Rótulo único de um card da lista, combinando nome + situação (spec 17).
    // Ex.: "CNH, venceu há 21 dias" / "Passaporte, em 18 dias".
    static func card(nome: String, statusLabel: String) -> String {
        "\(nome), \(statusLabel.lowercasedFirst)"
    }
}

private extension String {
    /// Primeira letra em minúscula (para encaixar o statusLabel após a vírgula).
    var lowercasedFirst: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
