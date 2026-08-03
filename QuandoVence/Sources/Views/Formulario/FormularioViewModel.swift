// FormularioViewModel.swift — estado e regras do formulário (spec 8.3/8.4).
//
// Serve tanto ao cadastro (Novo) quanto à edição, reaproveitando a mesma tela
// (spec 8.4). Aplica a única validação bloqueante — nome não vazio após trim
// (regra 11.7) — e, ao salvar, grava o documento, pede permissão de notificação na
// primeira vez (assunção 6) e (re)agenda os avisos cancelando os antigos (regra
// 11.3/11.4). A data padrão de um novo documento é hoje + 30 dias (spec 8.3).

import Foundation
import SwiftData

/// Modo de operação do formulário (spec 8.3/8.4).
enum ModoFormulario {
    case novo
    case editar(Documento)
}

@MainActor
final class FormularioViewModel: ObservableObject {

    @Published var nome: String
    @Published var categoria: categoria_documento
    @Published var dataVencimento: Date
    @Published var fotoData: Data?
    /// Primeiro dia do mês visível no calendário (spec 8.3).
    @Published var mesVisivel: Date

    private let modo: ModoFormulario

    init(modo: ModoFormulario) {
        self.modo = modo
        let calendario = Calendar.current
        let nomeInicial: String
        let categoriaInicial: categoria_documento
        let dataInicial: Date
        let fotoInicial: Data?
        switch modo {
        case .novo:
            nomeInicial = ""
            categoriaInicial = .pessoal
            // Data padrão: hoje + 30 dias (spec 8.3).
            dataInicial = calendario.date(byAdding: .day, value: 30,
                                          to: calendario.startOfDay(for: Date()))!
            fotoInicial = nil
        case .editar(let doc):
            nomeInicial = doc.nome
            categoriaInicial = doc.categoria
            dataInicial = doc.data_vencimento
            fotoInicial = doc.foto
        }
        nome = nomeInicial
        categoria = categoriaInicial
        dataVencimento = dataInicial
        fotoData = fotoInicial
        mesVisivel = calendario.startOfDay(for: calendario.dateInterval(of: .month, for: dataInicial)!.start)
    }

    /// Título da tela (spec 8.4): "Novo documento" ou "Editar".
    var titulo: String {
        if case .editar = modo { return "Editar" }
        return "Novo documento"
    }

    /// Validação da regra 11.7: nome não pode ser vazio após trim. Única regra
    /// bloqueante — habilita/desabilita o botão Salvar (spec 8.3).
    var nomeValido: Bool {
        !nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Avança/retrocede o mês visível no calendário (spec 8.3).
    func mudarMes(_ passo: Int) {
        let calendario = Calendar.current
        if let novo = calendario.date(byAdding: .month, value: passo, to: mesVisivel) {
            mesVisivel = calendario.startOfDay(for: calendario.dateInterval(of: .month, for: novo)!.start)
        }
    }

    // Seleciona um dia do calendário como data de vencimento (spec 8.3).
    func selecionar(dia: Date) {
        dataVencimento = Calendar.current.startOfDay(for: dia)
    }

    // Grava o documento e (re)agenda os avisos (spec 8.3/8.4, regra 11.3/11.4).
    // Pede permissão de notificação na primeira vez (assunção 6) — o cadastro nunca
    // é bloqueado por recusa (spec 8.7). Devolve o documento salvo para a navegação.
    func salvar(context: ModelContext, todos documentos: [Documento]) async -> Documento {
        let nomeLimpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let doc: Documento

        switch modo {
        case .novo:
            doc = Documento(nome: nomeLimpo, categoria: categoria,
                            data_vencimento: dataVencimento, foto: fotoData)
            context.insert(doc)
        case .editar(let existente):
            existente.nome = nomeLimpo
            existente.categoria = categoria
            existente.data_vencimento = dataVencimento
            existente.foto = fotoData
            existente.atualizado_em = Date()
            doc = existente
        }
        try? context.save()

        // Permissão pedida no 1º cadastro; só prompta se ainda não decidida (spec 8.7).
        await AgendadorDeAvisos.solicitarPermissaoSeNecessario()
        // (Re)agenda cancelando os antigos daquele documento (regra 11.3/11.4).
        AgendadorDeAvisos.agendar(documento: doc, config: ConfiguracaoAvisos())
        return doc
    }
}
