// ContainerModelo.swift — construção do ModelContainer do SwiftData (spec 4/7).
//
// O app nasce LOCAL-FIRST, sem exceção (spec 0.1): o container usa armazenamento
// local puro, sem `cloudKitDatabase`, sem App Group, sem nenhuma dependência de
// rede (spec 4/20). A sincronização via CloudKit está fora do MVP por decisão
// explícita (spec 3/28); o modelo foi desenhado para tornar essa mudança pequena
// depois, mas ela NÃO é feita aqui.

import Foundation
import SwiftData

enum ContainerModelo {

    /// Schema com a tabela única do modelo (spec 7): `documento`.
    static let schema = Schema([Documento.self])

    // Cria o container do app. `emMemoria` serve a testes/preview (spec 22). Em uso
    // normal, grava no store local do sandbox do app; nunca sai do aparelho (spec 20).
    static func criar(emMemoria: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: emMemoria)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
