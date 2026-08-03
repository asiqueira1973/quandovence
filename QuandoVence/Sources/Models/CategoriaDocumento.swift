// CategoriaDocumento.swift — enum `categoria_documento` do modelo (spec seção 7).
//
// Convenção de idioma não-negociável (instrução do produto / spec 18): o NOME do
// enum e dos casos espelham exatamente o banco, em português e snake_case
// (`categoria_documento`, `viagem`, `pessoal`, `trabalho`, `saude`, `veiculo`) —
// valores e ordem idênticos ao protótipo (objeto `CATS`, spec 16), sem tradução
// nem sinônimo. Como o nome do caso já é a chave persistida, o `rawValue` coincide
// sem mapeamento. String-backed + Codable para o SwiftData guardar de forma
// estável e deixar barata uma futura migração para CloudKit (spec 24/28).

import Foundation

/// As 5 categorias fixas de documento (spec 7 — enum `categoria_documento`). A
/// ordem dos casos é a mesma dos chips do formulário no protótipo (spec 16).
enum categoria_documento: String, Codable, CaseIterable, Identifiable {
    case viagem
    case pessoal
    case trabalho
    case saude
    case veiculo

    var id: String { rawValue }

    /// Rótulo de exibição em português (spec 15/16 — labels literais do `CATS`).
    var displayName: String {
        switch self {
        case .viagem: return "Viagem"
        case .pessoal: return "Pessoal"
        case .trabalho: return "Trabalho"
        case .saude: return "Saúde"
        case .veiculo: return "Veículo"
        }
    }
}
