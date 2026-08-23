// DetalheView.swift — detalhe de um documento (spec 8.2, regra 11.5).
//
// Redesenhada no padrão nativo do iOS (/design): categoria em rótulo neutro, nome
// como título grande, um "herói" central com o countdown (dias até/desde o
// vencimento — regra 11.2; a cor entra só na urgência, princípio 0.4), os dados em
// lista agrupada "inset" e "Excluir documento" em seção própria, como o padrão de
// exclusão do iOS. Sem barra de cor lateral. Excluir pede confirmação nativa
// (regra 11.5) e, ao confirmar, cancela as notificações pendentes do documento e
// volta para a lista (spec 8.2/8.5).

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

    // Cor do número grande: só urgência ganha cor; "em dia" fica neutro escuro
    // (princípio 0.4) — um número gigante em cinza-claro ficaria ilegível.
    private var corNumero: Color {
        status.urgencia == .emDia ? Palette.textPrimary : status.cor
    }

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(documento.categoria.displayName.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Palette.textMuted)
                    Text(documento.nome)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.top, 5)

                    cartaoNumeroGrande.padding(.top, 20)
                    cartaoInfo.padding(.top, 26)
                    if let foto = documento.foto, let ui = UIImage(data: foto) {
                        cartaoFoto(ui).padding(.top, 20)
                    }
                    botaoExcluir.padding(.top, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .background(Palette.groupedBackground)
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
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium))
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
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    // Herói central com o countdown (spec 8.2). Número grande, cor só na urgência.
    private var cartaoNumeroGrande: some View {
        VStack(spacing: 8) {
            Text(status.bigNumber)
                .font(.system(size: 64, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(corNumero)
            Text(status.bigCaption)
                .font(.system(size: 16))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .groupedCard(cornerRadius: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.bigNumber) \(status.bigCaption)")
    }

    // Lista agrupada de informações: vencimento, categoria, avisos (spec 8.2).
    private var cartaoInfo: some View {
        VStack(spacing: 0) {
            linhaInfo("Vencimento", Formatters.dataLonga(documento.data_vencimento), divisor: true)
            linhaInfo("Categoria", documento.categoria.displayName, divisor: true)
            linhaInfo("Avisos", rotuloAvisos, divisor: false)
        }
        .groupedCard(cornerRadius: 12)
    }

    private func linhaInfo(_ rotulo: String, _ valor: String, divisor: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text(rotulo).font(.system(size: 16)).foregroundStyle(Palette.textSecondary)
                Spacer()
                Text(valor).font(.system(size: 16))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
            if divisor { Divider().overlay(Palette.separator).padding(.leading, 16) }
        }
    }

    // Foto de referência, exibida só quando existe (spec 8.2).
    private func cartaoFoto(_ ui: UIImage) -> some View {
        Image(uiImage: ui)
            .resizable()
            .scaledToFill()
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel("Foto do documento")
    }

    // Ação destrutiva em seção própria, como o "Apagar" padrão do iOS (spec 15/16 —
    // cor #C0362B, mais escura que o vermelho de status).
    private var botaoExcluir: some View {
        Button { confirmandoExclusao = true } label: {
            Text("Excluir documento")
                .font(.system(size: 17))
                .foregroundStyle(Palette.destructive)
                .frame(maxWidth: .infinity, minHeight: 48)
                .groupedCard(cornerRadius: 12)
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
