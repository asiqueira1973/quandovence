// Formatters.swift — formatação de datas em português (spec 15/16).
//
// Reproduz LITERALMENTE os formatos do protótipo (arrays `MONTHS`/`MON3`), em vez
// de depender do locale do sistema, para garantir saída idêntica pixel a pixel
// (spec 16). Todos os textos são pt-BR (spec 17).

import Foundation

enum Formatters {

    /// Meses por extenso (protótipo — `MONTHS`).
    static let meses = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
                        "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]

    /// Meses abreviados em 3 letras (protótipo — `MON3`).
    static let mesesCurtos = ["jan", "fev", "mar", "abr", "mai", "jun",
                              "jul", "ago", "set", "out", "nov", "dez"]

    /// Iniciais dos dias da semana começando no domingo (protótipo — `weekdays`).
    static let diasDaSemana = ["D", "S", "T", "Q", "Q", "S", "S"]

    // Componentes dia/mês(1-based)/ano de uma data no calendário local.
    private static func partes(_ data: Date, calendario: Calendar = .current) -> (dia: Int, mes: Int, ano: Int) {
        let c = calendario.dateComponents([.day, .month, .year], from: data)
        return (c.day ?? 1, c.month ?? 1, c.year ?? 2000)
    }

    /// Data curta do card da lista — ex.: "18 ago 2025" (protótipo — `dateLabel`).
    static func dataCurta(_ data: Date, calendario: Calendar = .current) -> String {
        let p = partes(data, calendario: calendario)
        return "\(p.dia) \(mesesCurtos[p.mes - 1]) \(p.ano)"
    }

    /// Data por extenso — ex.: "18 de agosto de 2025" (protótipo — `longDate` e
    /// `selectedDateLabel`). Usada no Detalhe e no rodapé do calendário.
    static func dataLonga(_ data: Date, calendario: Calendar = .current) -> String {
        let p = partes(data, calendario: calendario)
        return "\(p.dia) de \(meses[p.mes - 1]) de \(p.ano)"
    }

    /// Cabeçalho do mês no calendário — ex.: "Agosto 2025" (protótipo — `monthLabel`),
    /// com a primeira letra do mês em maiúscula.
    static func mesAno(_ data: Date, calendario: Calendar = .current) -> String {
        let p = partes(data, calendario: calendario)
        return meses[p.mes - 1].capitalizedFirst + " \(p.ano)"
    }
}

private extension String {
    /// Primeira letra em maiúscula, resto intacto (para "Agosto", "Março"...).
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
