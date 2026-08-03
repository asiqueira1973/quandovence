// Documento.swift — tabela `documento` do modelo de dados (spec seção 7).
//
// Registro de um documento pessoal com data de vencimento. Tabela ÚNICA, sem
// chave estrangeira e sem relação (princípio 0.3). Exclusão é hard delete (spec 7)
// — não há histórico nem soft delete.
//
// Convenção de idioma (instrução do produto / spec 18): a classe `@Model` é a
// camada de tabela/coluna e usa nomes em português, snake_case, exatamente como na
// seção 7. O resto do código (views, helpers) fica em inglês.
//
// Disciplina CloudKit-ready (spec 4/28): toda propriedade tem valor default e
// nenhuma usa `@Attribute(.unique)` — duas pessoas podem ter dois "Passaporte"
// (spec 7). Todo cálculo de urgência/rótulo vive em código (CalculadoraDeStatus),
// nunca no store (spec 7/11) — assim ligar CloudKit depois é mudança pequena.

import Foundation
import SwiftData

@Model
final class Documento {

    /// Chave primária (spec 7 — `id`).
    var id: UUID = UUID()

    /// Nome livre do documento, inclusive de terceiros — ex.: "RG do meu pai
    /// (Antônio)" (spec 7). Único campo obrigatório do cadastro (regra 11.7).
    var nome: String = ""

    /// Categoria fixa do documento (spec 7 — default `pessoal`).
    var categoria: categoria_documento = categoria_documento.pessoal

    /// Data de vencimento; base do cálculo de urgência e do agendamento de avisos
    /// (spec 7/11). Guardada como a meia-noite local do dia escolhido.
    var data_vencimento: Date = Date()

    /// Foto de referência opcional, guardada como binário fora da linha do store
    /// (`.externalStorage`, spec 7). Nula no caso mais comum — pessoa sem foto.
    /// Dado potencialmente sensível: por isso nunca sai do aparelho (spec 20).
    @Attribute(.externalStorage) var foto: Data?

    /// Quando o registro foi criado (spec 7 — `criado_em`, auditoria, não exibido).
    var criado_em: Date = Date()

    /// Última edição do registro (spec 7 — `atualizado_em`, auditoria, não exibido).
    var atualizado_em: Date = Date()

    // Cria um novo documento. `nome`, `categoria` e `data_vencimento` bastam para
    // salvar; a foto é sempre opcional e nunca bloqueia o cadastro (spec 0.2/8.3).
    init(
        nome: String = "",
        categoria: categoria_documento = .pessoal,
        data_vencimento: Date = Date(),
        foto: Data? = nil
    ) {
        self.id = UUID()
        self.nome = nome
        self.categoria = categoria
        self.data_vencimento = data_vencimento
        self.foto = foto
        self.criado_em = Date()
        self.atualizado_em = Date()
    }
}
