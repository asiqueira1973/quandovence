// SeedData.swift — dados de exemplo para preview/DEBUG (spec 7).
//
// Reaproveita os 7 documentos de exemplo do protótipo do Claude Design (CNH,
// Passaporte, RG do pai, Seguro do carro, Carteirinha do plano, Certificado NR-10,
// Visto EUA), com os mesmos deslocamentos de dias em relação a hoje (spec 7). NUNCA
// entra em build de release — só alimenta os `#Preview` do SwiftUI (spec 7/18).

import Foundation
import SwiftData

enum SeedData {

    // Documento de exemplo com vencimento a `offset` dias de hoje (negativo = já
    // venceu), espelhando o `offsetIso` do protótipo.
    private static func doc(_ nome: String, _ cat: categoria_documento, _ offset: Int) -> Documento {
        let venc = Calendar.current.date(byAdding: .day, value: offset,
                                         to: Calendar.current.startOfDay(for: Date()))!
        return Documento(nome: nome, categoria: cat, data_vencimento: venc)
    }

    /// Os 7 exemplos do protótipo, na mesma ordem (spec 7).
    static var exemplos: [Documento] {
        [
            doc("CNH", .veiculo, -21),
            doc("Passaporte", .viagem, 18),
            doc("RG do meu pai (Antônio)", .pessoal, 26),
            doc("Seguro do carro", .veiculo, 34),
            doc("Carteirinha do plano", .saude, 120),
            doc("Certificado NR-10", .trabalho, 166),
            doc("Visto EUA (B1/B2)", .viagem, 950),
        ]
    }

    // Popula um contexto de preview em memória com os exemplos (spec 22).
    @MainActor
    static func popular(context: ModelContext) {
        for d in exemplos { context.insert(d) }
    }

    // Cria um container em memória já populado — atalho para os `#Preview` (spec 22).
    @MainActor
    static func containerDePreview() -> ModelContainer {
        let container = try! ContainerModelo.criar(emMemoria: true)
        popular(context: container.mainContext)
        return container
    }
}
