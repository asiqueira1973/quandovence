// AjustesView.swift — controle de quando e como os avisos chegam (spec 8.6).
//
// Recria o protótipo: quatro toggles de antecedência (90/30/7/1 dias — 90/30/7
// ligados por padrão, 1 desligado), o horário de envio (ciclando entre os 4 valores
// fixos), a contagem de documentos e a confirmação de privacidade (spec 8.6/15).
// QUALQUER mudança de toggle ou de horário reagenda TODAS as notificações futuras de
// TODOS os documentos (regra 11.4) — de forma assíncrona para não travar a UI
// (risco 23). As preferências vivem em @AppStorage (spec 7).

import SwiftUI
import SwiftData

struct AjustesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var documentos: [Documento]

    @AppStorage(ChavesAviso.aviso90) private var aviso90 = true
    @AppStorage(ChavesAviso.aviso30) private var aviso30 = true
    @AppStorage(ChavesAviso.aviso7) private var aviso7 = true
    @AppStorage(ChavesAviso.aviso1) private var aviso1 = false
    @AppStorage(ChavesAviso.horarioIndex) private var horarioIndex = 1

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    rotuloSecao("Avisar com antecedência", primeira: true)
                    cardAvisos
                    legenda("Você recebe um aviso em cada intervalo marcado antes do vencimento — e mais um no dia.")

                    rotuloSecao("Horário dos avisos")
                    cardHorario

                    rotuloSecao("Sobre")
                    cardSobre
                    legenda("Sem conta, sem nuvem, sem sincronização. Nada sai do seu iPhone.")
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .background(Palette.screen)
        .toolbar(.hidden, for: .navigationBar)
    }

    // Cabeçalho: ‹ Documentos + título centralizado (spec 16).
    private var cabecalho: some View {
        ZStack {
            Text("Ajustes").font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 2) {
                        Text("‹").font(.system(size: 24, weight: .light))
                        Text("Documentos").font(.system(size: 17))
                    }
                    .frame(minHeight: 44).padding(.horizontal, 8)
                }
                .tint(Palette.systemBlue)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { Divider().overlay(Palette.barBorder) }
    }

    private func rotuloSecao(_ texto: String, primeira: Bool = false) -> some View {
        Text(texto.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Palette.sectionLabel)
            .padding(.top, primeira ? 0 : 26)
            .padding(.bottom, 8)
            .padding(.horizontal, 4)
    }

    private func legenda(_ texto: String) -> some View {
        Text(texto)
            .font(.system(size: 13))
            .foregroundStyle(Palette.textMuted)
            .lineSpacing(2)
            .padding(.horizontal, 6)
            .padding(.top, 10)
    }

    // Card com os 4 toggles (spec 8.6). O track fica escuro quando ligado, como no
    // protótipo (tint = botão primário). Cada mudança reagenda tudo (regra 11.4).
    private var cardAvisos: some View {
        VStack(spacing: 0) {
            toggle("90 dias antes", $aviso90, divisor: true)
            toggle("30 dias antes", $aviso30, divisor: true)
            toggle("7 dias antes", $aviso7, divisor: true)
            toggle("1 dia antes", $aviso1, divisor: false)
        }
        .documentoCard()
    }

    private func toggle(_ rotulo: String, _ ligado: Binding<Bool>, divisor: Bool) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: ligado) {
                Text(rotulo).font(.system(size: 16)).foregroundStyle(Palette.textPrimary)
            }
            .tint(Palette.primaryButton)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .onChange(of: ligado.wrappedValue) { _, _ in reagendarTudo() }
            if divisor { Divider().overlay(Palette.hairline).padding(.leading, 18) }
        }
    }

    // Card do horário — pill tocável que cicla entre os 4 valores fixos (spec 8.6).
    private var cardHorario: some View {
        HStack {
            Text("Enviar às").font(.system(size: 16)).foregroundStyle(Palette.textPrimary)
            Spacer()
            Button { ciclarHorario() } label: {
                Text(AppConstants.horariosAviso[horarioIndex])
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .frame(minHeight: 36)
                    .background(Palette.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .accessibilityLabel("Horário dos avisos: \(AppConstants.horariosAviso[horarioIndex]). Toque para mudar.")
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .frame(minHeight: 52)
        .documentoCard()
    }

    // Card "Sobre": contagem de documentos e confirmação de local (spec 8.6).
    private var cardSobre: some View {
        VStack(spacing: 0) {
            linhaSobre("Documentos salvos", "\(documentos.count)", divisor: true)
            linhaSobre("Dados", "Só neste aparelho", divisor: false)
        }
        .documentoCard()
    }

    private func linhaSobre(_ rotulo: String, _ valor: String, divisor: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(rotulo).font(.system(size: 16)).foregroundStyle(Palette.textPrimary)
                Spacer()
                Text(valor).font(.system(size: 16)).foregroundStyle(Palette.textMuted)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(minHeight: 52)
            if divisor { Divider().overlay(Palette.hairline).padding(.leading, 18) }
        }
    }

    // Cicla o horário e reagenda tudo (spec 8.6, regra 11.4).
    private func ciclarHorario() {
        horarioIndex = (horarioIndex + 1) % AppConstants.horariosAviso.count
        reagendarTudo()
    }

    // Reagenda TODAS as notificações de TODOS os documentos após mudança de ajuste
    // (regra 11.4). Assíncrono para não travar a UI (risco 23).
    private func reagendarTudo() {
        let docs = documentos
        let config = ConfiguracaoAvisos()
        Task.detached { await MainActor.run { AgendadorDeAvisos.reagendarTudo(documentos: docs, config: config) } }
    }
}

#Preview {
    NavigationStack { AjustesView() }
        .modelContainer(SeedData.containerDePreview())
}
