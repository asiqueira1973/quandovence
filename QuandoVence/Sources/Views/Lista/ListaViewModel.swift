// ListaViewModel.swift — agrupamento e resumo da Home (spec 8.1, regras 11.1/11.2).
//
// Recebe os documentos do @Query e os organiza em três grupos por urgência —
// Vencidos / Vence em breve / Em dia — sempre com o mais urgente primeiro, e monta
// o texto de resumo do topo. Toda a lógica é derivada em tempo de leitura, nunca
// persistida (spec 7/11). Recebe `hoje` explícito para permitir teste (spec 22).

import Foundation

/// Resultado do agrupamento da lista (spec 8.1).
struct GrupoDocumentos {
    let vencidos: [Documento]      // dias < 0
    let emBreve: [Documento]       // 0...30 dias
    let emDia: [Documento]         // > 30 dias
    let resumo: String             // texto do topo (spec 15)

    /// True quando não há nenhum documento cadastrado (estado vazio, spec 8.1).
    var vazio: Bool { vencidos.isEmpty && emBreve.isEmpty && emDia.isEmpty }
}

enum ListaViewModel {

    // Agrupa e ordena os documentos por urgência (spec 8.1). Ordena todos por dias
    // crescente (mais urgente primeiro) e distribui nos três grupos (regra 11.1). O
    // resumo conta apenas vencidos + vence em breve (spec 8.1/15).
    static func agrupar(_ documentos: [Documento], hoje: Date? = nil) -> GrupoDocumentos {
        let base = hoje ?? CalculadoraDeStatus.hoje()

        let ordenados = documentos.sorted {
            CalculadoraDeStatus.dias(ate: $0.data_vencimento, hoje: base)
                < CalculadoraDeStatus.dias(ate: $1.data_vencimento, hoje: base)
        }

        let vencidos = ordenados.filter { CalculadoraDeStatus.dias(ate: $0.data_vencimento, hoje: base) < 0 }
        let emBreve = ordenados.filter {
            let d = CalculadoraDeStatus.dias(ate: $0.data_vencimento, hoje: base)
            return d >= 0 && d <= 30
        }
        let emDia = ordenados.filter { CalculadoraDeStatus.dias(ate: $0.data_vencimento, hoje: base) > 30 }

        return GrupoDocumentos(
            vencidos: vencidos, emBreve: emBreve, emDia: emDia,
            resumo: resumo(atencao: vencidos.count + emBreve.count))
    }

    // Texto do resumo do topo, com singular/plural corretos (spec 8.1/15).
    static func resumo(atencao: Int) -> String {
        switch atencao {
        case 0: return "Tudo em dia — nada a fazer agora"
        case 1: return "1 documento precisa de atenção"
        default: return "\(atencao) documentos precisam de atenção"
        }
    }
}
