// RegrasTests.swift — testes de agrupamento, resumo e configuração (spec 8.1/8.6).
//
// Cobre o agrupamento por urgência da Home (spec 8.1), o texto de resumo com
// singular/plural (spec 15) e o snapshot de ConfiguracaoAvisos lido do UserDefaults
// (spec 7): intervalos ativos, horário e rótulo dos avisos.

import XCTest
@testable import QuandoVence

final class RegrasTests: XCTestCase {

    private func data(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // --- Agrupamento da Home (spec 8.1) ----------------------------------
    func testAgrupamentoPorUrgencia() {
        let hoje = data(2026, 6, 15)
        let cal = Calendar.current
        func doc(_ nome: String, _ offset: Int) -> Documento {
            Documento(nome: nome, categoria: .pessoal,
                      data_vencimento: cal.date(byAdding: .day, value: offset, to: hoje)!)
        }
        let docs = [doc("Vencido", -5), doc("Breve", 10), doc("EmDia", 100), doc("Hoje", 0)]
        let g = ListaViewModel.agrupar(docs, hoje: hoje)

        XCTAssertEqual(g.vencidos.map(\.nome), ["Vencido"])
        XCTAssertEqual(g.emBreve.map(\.nome), ["Hoje", "Breve"])  // ordenado por dias asc
        XCTAssertEqual(g.emDia.map(\.nome), ["EmDia"])
        XCTAssertFalse(g.vazio)
    }

    func testEstadoVazio() {
        let g = ListaViewModel.agrupar([], hoje: data(2026, 6, 15))
        XCTAssertTrue(g.vazio)
        XCTAssertEqual(g.resumo, "Tudo em dia — nada a fazer agora")
    }

    // --- Resumo do topo (spec 8.1/15) ------------------------------------
    func testResumo() {
        XCTAssertEqual(ListaViewModel.resumo(atencao: 0), "Tudo em dia — nada a fazer agora")
        XCTAssertEqual(ListaViewModel.resumo(atencao: 1), "1 documento precisa de atenção")
        XCTAssertEqual(ListaViewModel.resumo(atencao: 3), "3 documentos precisam de atenção")
    }

    // --- ConfiguracaoAvisos (spec 7/8.6) ---------------------------------
    func testConfiguracaoPadrao() {
        let suite = UserDefaults(suiteName: "teste_padrao_\(UUID().uuidString)")!
        let config = ConfiguracaoAvisos(defaults: suite)
        XCTAssertEqual(config.intervalosAtivos, [90, 30, 7])   // 1 dia desligado por padrão
        XCTAssertEqual(config.horaMinuto.hora, 9)              // índice 1 = 09:00
        XCTAssertEqual(config.horaMinuto.minuto, 0)
        XCTAssertEqual(config.rotuloAvisos, "90, 30, 7 dias antes")
    }

    func testConfiguracaoTodosDesligados() {
        let suite = UserDefaults(suiteName: "teste_off_\(UUID().uuidString)")!
        suite.set(false, forKey: ChavesAviso.aviso90)
        suite.set(false, forKey: ChavesAviso.aviso30)
        suite.set(false, forKey: ChavesAviso.aviso7)
        suite.set(false, forKey: ChavesAviso.aviso1)
        suite.set(3, forKey: ChavesAviso.horarioIndex)        // índice 3 = 19:00
        let config = ConfiguracaoAvisos(defaults: suite)
        XCTAssertTrue(config.intervalosAtivos.isEmpty)
        XCTAssertEqual(config.rotuloAvisos, "Desativados")
        XCTAssertEqual(config.horaMinuto.hora, 19)
    }
}
