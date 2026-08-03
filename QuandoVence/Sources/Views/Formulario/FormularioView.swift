// FormularioView.swift — cadastro e edição de documento (spec 8.3/8.4).
//
// Uma única tela serve a Novo e Editar (spec 8.4), com título dinâmico. Recria o
// protótipo: seção Documento (nome), Categoria (chips com seleção única, Pessoal
// pré-selecionada), Vencimento (calendário customizado) e Foto opcional com a
// legenda "Fica salva só neste aparelho" (spec 8.3/15). O botão Salvar fica cinza
// (#C7C7CC) enquanto o nome estiver vazio (regra 11.7). Ao salvar, grava, agenda os
// avisos e devolve o documento para a navegação (spec 8.3).

import SwiftUI
import SwiftData
import PhotosUI

struct FormularioView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var documentos: [Documento]

    @StateObject private var vm: FormularioViewModel
    @State private var itemFoto: PhotosPickerItem?
    @State private var salvando = false

    /// Callback chamado após salvar, com o documento resultante (spec 8.3) — a Lista
    /// usa para navegar ao Detalhe do novo documento.
    let onSalvou: (Documento) -> Void

    init(modo: ModoFormulario, onSalvou: @escaping (Documento) -> Void) {
        _vm = StateObject(wrappedValue: FormularioViewModel(modo: modo))
        self.onSalvou = onSalvou
    }

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    rotuloSecao("Documento", primeira: true)
                    campoNome
                    rotuloSecao("Categoria")
                    chipsCategoria
                    rotuloSecao("Vencimento")
                    CalendarioView(vm: vm)
                    rotuloSecao("Foto (opcional)")
                    linhaFoto
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 24)
            }
        }
        .background(Palette.screen)
        .safeAreaInset(edge: .bottom) { rodapeSalvar }
    }

    // Cabeçalho: Cancelar / título / espaço (spec 8.3/16).
    private var cabecalho: some View {
        HStack {
            Button("Cancelar") { dismiss() }
                .font(.system(size: 17))
                .tint(Palette.systemBlue)
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
            Spacer()
            Text(vm.titulo).font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Color.clear.frame(width: 78, height: 1)
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
            .padding(.top, primeira ? 0 : 22)
            .padding(.bottom, 8)
            .padding(.horizontal, 4)
    }

    // Campo de nome do documento (spec 8.3).
    private var campoNome: some View {
        TextField("Nome do documento", text: $vm.nome)
            .font(.system(size: 16))
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .documentoCard()
    }

    // Chips de categoria com seleção única (spec 8.3). Ativo = fundo escuro/texto
    // branco; inativo = card branco. Ordem exata do protótipo.
    private var chipsCategoria: some View {
        FlowLayout(espacamento: 8) {
            ForEach(categoria_documento.allCases) { cat in
                let ativo = vm.categoria == cat
                Button { vm.categoria = cat } label: {
                    HStack(spacing: 7) {
                        CategoriaIconView(categoria: cat, size: 16,
                                          color: ativo ? Palette.primaryButtonText : Palette.textMuted)
                        Text(cat.displayName).font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(ativo ? Palette.primaryButtonText : Palette.textPrimary)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                    .background(ativo ? Palette.primaryButton : Palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(ativo ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    // Linha de foto opcional (spec 8.3). Sem foto → PhotosPicker "Adicionar foto /
    // Escolher"; com foto → "Foto anexada" + "Remover". Legenda sempre visível.
    @ViewBuilder
    private var linhaFoto: some View {
        if vm.fotoData == nil {
            PhotosPicker(selection: $itemFoto, matching: .images) {
                conteudoLinhaFoto(titulo: "Adicionar foto", acao: "Escolher")
            }
            .onChange(of: itemFoto) { _, novo in Task { await carregarFoto(novo) } }
        } else {
            HStack(spacing: 12) {
                miniaturaFoto
                VStack(alignment: .leading, spacing: 1) {
                    Text("Foto anexada").font(.system(size: 16)).foregroundStyle(Palette.textPrimary)
                    Text("Fica salva só neste aparelho")
                        .font(.system(size: 13)).foregroundStyle(Palette.textMuted)
                }
                Spacer()
                Button("Remover") { vm.fotoData = nil; itemFoto = nil }
                    .font(.system(size: 15)).tint(Palette.systemBlue)
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .frame(minHeight: 56)
            .documentoCard()
        }
    }

    private func conteudoLinhaFoto(titulo: String, acao: String) -> some View {
        HStack(spacing: 12) {
            iconeFotoPlaceholder
            VStack(alignment: .leading, spacing: 1) {
                Text(titulo).font(.system(size: 16)).foregroundStyle(Palette.textPrimary)
                Text("Fica salva só neste aparelho")
                    .font(.system(size: 13)).foregroundStyle(Palette.textMuted)
            }
            Spacer()
            Text(acao).font(.system(size: 15)).foregroundStyle(Palette.systemBlue)
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .frame(minHeight: 56)
        .documentoCard()
    }

    private var iconeFotoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Palette.inset)
            .frame(width: 44, height: 44)
            .overlay { CameraIconView(size: 21, color: Palette.textMuted) }
    }

    private var miniaturaFoto: some View {
        Group {
            if let data = vm.fotoData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else { Palette.inset }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    // Botão Salvar fixo na base; cinza (#C7C7CC) enquanto o nome for inválido
    // (regra 11.7 / spec 8.3).
    private var rodapeSalvar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.barBorder)
            Button(action: salvar) {
                Text("Salvar")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(vm.nomeValido ? Palette.primaryButton : Palette.disabledButton)
                    .foregroundStyle(Palette.primaryButtonText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!vm.nomeValido || salvando)
            .padding(.horizontal, 20).padding(.top, 12)
        }
        .background(Palette.screen.opacity(0.92))
    }

    // Carrega a foto escolhida e a comprime para o modelo (spec 7/8.3).
    private func carregarFoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }
        vm.fotoData = FotoUtil.dadosJPEG(de: ui)
    }

    // Salva o documento, agenda os avisos e navega ao Detalhe do resultado (spec 8.3).
    private func salvar() {
        guard vm.nomeValido, !salvando else { return }
        salvando = true
        Task {
            let doc = await vm.salvar(context: context, todos: documentos)
            dismiss()
            onSalvou(doc)
        }
    }
}

#Preview {
    FormularioView(modo: .novo) { _ in }
        .modelContainer(SeedData.containerDePreview())
}
