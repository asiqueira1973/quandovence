// CalculadoraDeStatusTests.swift — testes das regras 11.1/11.2 (spec 22).
//
// Cobre os casos de borda pedidos na seção 22: vence hoje, venceu ontem, amanhã, os
// limites entre dias/meses/anos e a virada de mês/ano. Testa as funções puras da
// CalculadoraDeStatus (rótulo, urgência, número grande) com entradas inteiras e a
// diferença de dias com datas construídas (para pegar viradas de ano).

import XCTest
@testable import QuandoVence

final class CalculadoraDeStatusTests: XCTestCase {

    // Constrói uma data à meia-noite local (spec 11 — cálculo à meia-noite).
    private func data(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // --- Rótulo de status (regra 11.2) -----------------------------------
    func testStatusLabelVencidos() {
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: -1), "Venceu ontem")
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: -21), "Venceu há 21 dias")
    }

    func testStatusLabelProximos() {
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 0), "Vence hoje")
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 1), "Amanhã")
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 18), "Em 18 dias")
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 30), "Em 30 dias")
    }

    func testStatusLabelMeses() {
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 31), "Em 1 meses")   // round(31/30)=1
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 45), "Em 2 meses")   // round(45/30)=2
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 364), "Em 12 meses") // round(364/30)=12
    }

    func testStatusLabelAnos() {
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 365), "Em 1 ano")    // singular <730
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 729), "Em 1 ano")    // ainda singular
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 730), "Em 2 anos")   // plural ≥730
        XCTAssertEqual(CalculadoraDeStatus.statusLabel(dias: 950), "Em 2 anos")   // exemplo do protótipo
    }

    // --- Urgência (regra 11.1) -------------------------------------------
    func testUrgencia() {
        XCTAssertEqual(CalculadoraDeStatus.urgencia(dias: -1), .vencido)
        XCTAssertEqual(CalculadoraDeStatus.urgencia(dias: 0), .venceEmBreve)
        XCTAssertEqual(CalculadoraDeStatus.urgencia(dias: 30), .venceEmBreve)
        XCTAssertEqual(CalculadoraDeStatus.urgencia(dias: 31), .emDia)
    }

    // --- Número grande e legenda (spec 8.2) ------------------------------
    func testNumeroGrandeELegenda() {
        XCTAssertEqual(CalculadoraDeStatus.bigNumber(dias: -21), "21")
        XCTAssertEqual(CalculadoraDeStatus.bigCaption(dias: -1), "dia desde o vencimento")
        XCTAssertEqual(CalculadoraDeStatus.bigCaption(dias: -21), "dias desde o vencimento")
        XCTAssertEqual(CalculadoraDeStatus.bigCaption(dias: 0), "vence hoje")
        XCTAssertEqual(CalculadoraDeStatus.bigCaption(dias: 1), "dia até o vencimento")
        XCTAssertEqual(CalculadoraDeStatus.bigCaption(dias: 18), "dias até o vencimento")
    }

    // --- Diferença de dias com virada de mês/ano (spec 22) ---------------
    func testDiasViradaDeAno() {
        let fim = data(2026, 12, 31)
        XCTAssertEqual(CalculadoraDeStatus.dias(ate: data(2027, 1, 1), hoje: fim), 1)   // Amanhã
        XCTAssertEqual(CalculadoraDeStatus.dias(ate: fim, hoje: fim), 0)                // Vence hoje
        XCTAssertEqual(CalculadoraDeStatus.dias(ate: data(2026, 12, 30), hoje: fim), -1) // Venceu ontem
    }

    func testDiasViradaDeMes() {
        let hoje = data(2026, 1, 31)
        XCTAssertEqual(CalculadoraDeStatus.dias(ate: data(2026, 2, 1), hoje: hoje), 1)
    }
}
