// CalendarioView.swift — calendário customizado de seleção de data (spec 8.3).
//
// Requisito explícito da spec: NÃO usar o DatePicker nativo em roda; recriar o
// calendário do protótipo, que permite navegar entre meses e tocar no dia. O dia de
// hoje é destacado (azul) mesmo sem estar selecionado; o dia selecionado tem
// círculo escuro (spec 8.3). Reproduz o layout do protótipo: navegação de mês,
// linha de iniciais de dia da semana, grade 7×N e rodapé com a data selecionada.

import SwiftUI

struct CalendarioView: View {
    @ObservedObject var vm: FormularioViewModel

    private let colunas = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let calendario = Calendar.current

    // Células do mês visível (nil = espaço antes do dia 1), espelhando `calendar()`
    // do protótipo.
    private var dias: [Date?] {
        let first = vm.mesVisivel
        let lead = calendario.component(.weekday, from: first) - 1   // 0 = domingo
        let total = calendario.range(of: .day, in: .month, for: first)?.count ?? 30
        var out: [Date?] = Array(repeating: nil, count: lead)
        for n in 0..<total {
            out.append(calendario.date(byAdding: .day, value: n, to: first))
        }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            navegacaoMes
            LazyVGrid(columns: colunas, spacing: 0) {
                ForEach(Formatters.diasDaSemana.indices, id: \.self) { i in
                    Text(Formatters.diasDaSemana[i])
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(Palette.sectionLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: colunas, spacing: 2) {
                ForEach(Array(dias.enumerated()), id: \.offset) { _, dia in
                    celula(dia)
                }
            }
            rodapeSelecionado
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .documentoCard()
    }

    // Navegação de mês: ‹ mês › (spec 8.3).
    private var navegacaoMes: some View {
        HStack {
            Button { vm.mudarMes(-1) } label: {
                Text("‹").font(.system(size: 22, weight: .light))
                    .frame(width: 44, height: 38)
            }
            .accessibilityLabel("Mês anterior")
            Spacer()
            Text(Formatters.mesAno(vm.mesVisivel))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Button { vm.mudarMes(1) } label: {
                Text("›").font(.system(size: 22, weight: .light))
                    .frame(width: 44, height: 38)
            }
            .accessibilityLabel("Próximo mês")
        }
        .tint(Palette.systemBlue)
        .padding(.horizontal, 4)
        .padding(.bottom, 10)
    }

    // Uma célula de dia (ou espaço vazio antes do dia 1), spec 8.3.
    @ViewBuilder
    private func celula(_ dia: Date?) -> some View {
        if let dia {
            let selecionado = calendario.isDate(dia, inSameDayAs: vm.dataVencimento)
            let hoje = calendario.isDateInToday(dia)
            Button { vm.selecionar(dia: dia) } label: {
                Text("\(calendario.component(.day, from: dia))")
                    .font(.system(size: 15, weight: selecionado || hoje ? .semibold : .regular))
                    .foregroundStyle(corTexto(selecionado: selecionado, hoje: hoje))
                    .frame(width: 36, height: 36)
                    .background(selecionado ? Palette.primaryButton : .clear)
                    .clipShape(Circle())
                    .frame(height: 42)
            }
            .accessibilityLabel(Formatters.dataLonga(dia))
            .accessibilityAddTraits(selecionado ? [.isButton, .isSelected] : .isButton)
        } else {
            Color.clear.frame(height: 42)
        }
    }

    // Cor do texto do dia (spec 8.3): selecionado = branco; hoje = azul; senão
    // texto primário.
    private func corTexto(selecionado: Bool, hoje: Bool) -> Color {
        if selecionado { return Palette.primaryButtonText }
        if hoje { return Palette.systemBlue }
        return Palette.textPrimary
    }

    // Rodapé com a data selecionada por extenso (spec 8.3).
    private var rodapeSelecionado: some View {
        HStack {
            Text("Selecionado").font(.system(size: 14)).foregroundStyle(Palette.textSecondary)
            Spacer()
            Text(Formatters.dataLonga(vm.dataVencimento))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
        .overlay(alignment: .top) { Divider().overlay(Palette.hairline) }
        .padding(.top, 10)
    }
}
