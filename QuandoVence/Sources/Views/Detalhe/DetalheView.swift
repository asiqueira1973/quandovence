// DetalheView.swift — detalhe de um documento (spec 8.2, regra 11.5).
//
// Recria o protótipo: cabeçalho com "‹ Documentos" e "Editar", categoria em
// destaque na cor de urgência, nome grande, cartão do número grande (dias até/desde
// o vencimento, regra 11.2) com barra na cor de status, cartão de informações
// (vencimento por extenso, categoria, avisos ativos) e a foto quando houver
// (spec 8.2). "Excluir documento" pede confirmação nativa (regra 11.5) e, ao
// confirmar, cancela as notificações pendentes do documento e volta para a lista
// (spec 8.2/8.5).

import SwiftUI
import SwiftData

struct DetalheView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let documento: Documento

    @State private var editando = false
    @State private var confirmandoExclusao = false

    private var status: StatusDocumento {
        CalculadoraDeStatus.status(dataVencimento: documento.data_vencimento)
    }
    private var rotuloAvisos: String { ConfiguracaoAvisos().rotuloAvisos }

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(documento.categoria.displayName.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(status.cor)
                    Text(documento.nome)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.top, 6)

                    cartaoNumeroGrande.padding(.top, 20)
                    cartaoInfo.padding(.top, 14)
                    if let foto = documento.foto, let ui = UIImage(data: foto) {
                        cartaoFoto(ui).padding(.top, 14)
                    }
                    botaoExcluir.padding(.top, 26)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Palette.screen)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $editando) {
            FormularioView(modo: .editar(documento)) { _ in }
        }
        // Confirmação de exclusão — ação destrutiva e irreversível (regra 11.5).
        .alert("Excluir documento?", isPresented: $confirmandoExclusao) {
            Button("Excluir", role: .destructive) { excluir() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }

    // Cabeçalho com voltar e editar (spec 8.2 / 16).
    private var cabecalho: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    Text("‹").font(.system(size: 24, weight: .light))
                    Text("Documentos").font(.system(size: 17))
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 8)
            }
            Spacer()
            Button { editando = true } label: {
                Text("Editar").font(.system(size: 17))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
            }
        }
        .tint(Palette.systemBlue)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { Divider().overlay(Palette.barBorder) }
    }

    // Cartão do número grande com a barra de urgência à esquerda (spec 8.2).
    private var cartaoNumeroGrande: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(status.bigNumber)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Palette.textPrimary)
            Text(status.bigCaption)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card)
        .overlay(alignment: .leading) { Rectangle().fill(status.cor).frame(width: 4) }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 4)
        .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.bigNumber) \(status.bigCaption)")
    }

    // Cartão de informações: vencimento, categoria, avisos (spec 8.2).
    private var cartaoInfo: some View {
        VStack(spacing: 0) {
            linhaInfo("Vencimento", Formatters.dataLonga(documento.data_vencimento), divisor: true)
            linhaInfo("Categoria", documento.categoria.displayName, divisor: true)
            linhaInfo("Avisos", rotuloAvisos, divisor: false)
        }
        .documentoCard()
    }

    private func linhaInfo(_ rotulo: String, _ valor: String, divisor: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text(rotulo).font(.system(size: 15)).foregroundStyle(Palette.textSecondary)
                Spacer()
                Text(valor).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            if divisor { Divider().overlay(Palette.hairline).padding(.leading, 18) }
        }
    }

    // Foto de referência, exibida só quando existe (spec 8.2).
    private func cartaoFoto(_ ui: UIImage) -> some View {
        Image(uiImage: ui)
            .resizable()
            .scaledToFill()
            .frame(height: 170)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
            .accessibilityLabel("Foto do documento")
    }

    // Botão destrutivo (spec 15/16 — cor #C0362B, mais escura que o vermelho de status).
    private var botaoExcluir: some View {
        Button { confirmandoExclusao = true } label: {
            Text("Excluir documento")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.destructive)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
        }
    }

    // Exclui o documento (hard delete, spec 7) e cancela suas notificações
    // pendentes antes de voltar à lista (spec 8.2/8.5, regra 11.4).
    private func excluir() {
        AgendadorDeAvisos.cancelar(documentoId: documento.id)
        context.delete(documento)
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DetalheView(documento: SeedData.exemplos[1])
    }
    .modelContainer(SeedData.containerDePreview())
}
