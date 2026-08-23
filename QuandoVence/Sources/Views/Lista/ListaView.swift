// ListaView.swift — Home: lista de documentos agrupada por urgência (spec 8.1).
//
// Raiz de navegação do app (spec 10). Redesenhada no padrão nativo do iOS
// (/design opção B, "estilo Lembretes"): título grande, seções agrupadas "inset"
// com contador, cada linha com ponto de urgência à esquerda (regra 11.1), e a ação
// primária "Adicionar documento" fixa na base no estilo do app Lembretes. Só as
// seções com itens aparecem; há resumo no topo, estado vazio, aviso discreto quando
// as notificações estão desativadas (spec 8.7) e o gate do paywall no 6º documento
// (regra 11.6 / spec 8.3/8.8). A nav bar do sistema fica oculta — o cabeçalho é
// recriado à mão para o título grande + engrenagem baterem com o design.

import SwiftUI
import SwiftData

/// Marcador de rota para empurrar a tela de Ajustes (spec 10).
struct RotaAjustes: Hashable {}

/// Folha modal apresentada a partir da Lista (spec 10).
enum FolhaLista: Identifiable {
    case novo
    case paywall
    var id: String { self == .novo ? "novo" : "paywall" }
}

struct ListaView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var compra: GerenciadorDeCompra
    @Query private var documentos: [Documento]

    @State private var path = NavigationPath()
    @State private var folha: FolhaLista?
    @State private var notificacoesNegadas = false

    private var grupos: GrupoDocumentos { ListaViewModel.agrupar(documentos) }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                conteudo
            }
            .background(Palette.groupedBackground)
            .safeAreaInset(edge: .bottom) { rodape }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Documento.self) { DetalheView(documento: $0) }
            .navigationDestination(for: RotaAjustes.self) { _ in AjustesView() }
            .sheet(item: $folha) { folha in
                switch folha {
                case .novo:
                    FormularioView(modo: .novo) { novo in path.append(novo) }
                case .paywall:
                    PaywallView()
                }
            }
        }
        // Verifica o estado da permissão para o aviso discreto (spec 8.7).
        .task { await atualizarStatusNotificacao() }
    }

    // Cabeçalho: título grande + resumo, com a engrenagem de Ajustes à direita
    // (padrão de tela com "large title" do iOS).
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quando Vence?")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text(grupos.resumo)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Button { path.append(RotaAjustes()) } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.systemBlue)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Ajustes")
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var conteudo: some View {
        if grupos.vazio {
            estadoVazio
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if notificacoesNegadas { avisoNotificacoes }
                    secao("Vencidos", grupos.vencidos, primeira: true)
                    secao("Vence em breve", grupos.emBreve, primeira: grupos.vencidos.isEmpty)
                    secao("Em dia", grupos.emDia, primeira: grupos.vencidos.isEmpty && grupos.emBreve.isEmpty)
                }
                .padding(.bottom, 16)
            }
        }
    }

    // Uma seção agrupada só é exibida quando tem itens (spec 8.1): cabeçalho com o
    // nome e o contador à direita, e as linhas dentro de um cartão "inset".
    @ViewBuilder
    private func secao(_ titulo: String, _ docs: [Documento], primeira: Bool) -> some View {
        if !docs.isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text(titulo)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.sectionLabel)
                Spacer()
                Text("\(docs.count)")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.top, primeira ? 12 : 22)
            .padding(.bottom, 7)

            VStack(spacing: 0) {
                ForEach(Array(docs.enumerated()), id: \.element.id) { indice, doc in
                    Button { path.append(doc) } label: { LinhaDocumento(documento: doc) }
                        .buttonStyle(.plain)
                    if indice < docs.count - 1 {
                        Divider().overlay(Palette.separator).padding(.leading, 41)
                    }
                }
            }
            .groupedCard()
            .padding(.horizontal, 16)
        }
    }

    // Estado vazio — nenhum documento cadastrado ainda (spec 8.1).
    private var estadoVazio: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Adicione seu primeiro documento")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Text("Cadastre um documento com data de vencimento e receba avisos antes que ele vença.")
                .font(.system(size: 14))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Aviso discreto de notificações desativadas (spec 8.7). Toca → Ajustes do SO.
    private var avisoNotificacoes: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 14))
                Text("Notificações desativadas. Toque para ativar nos Ajustes do iPhone.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.textSecondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .groupedCard()
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .buttonStyle(.plain)
    }

    // Ação primária fixa na base, no estilo "Novo lembrete" do app Lembretes
    // (spec 8.1). Aplica o gate do paywall (regra 11.6).
    private var rodape: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.separator)
            Button(action: adicionar) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Palette.systemBlue).frame(width: 28, height: 28)
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("Adicionar documento")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.systemBlue)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 2)
            }
        }
        .background(Palette.groupedBackground.opacity(0.94))
    }

    // Abre o formulário de novo documento, ou o Paywall se atingiu o limite
    // gratuito sem ter comprado (regra 11.6 / spec 8.3 / 8.8).
    private func adicionar() {
        if documentos.count >= AppConstants.limiteGratuito && !compra.compraDesbloqueada {
            folha = .paywall
        } else {
            folha = .novo
        }
    }

    // Marca se as notificações estão negadas, para o aviso discreto (spec 8.7).
    private func atualizarStatusNotificacao() async {
        notificacoesNegadas = await AgendadorDeAvisos.statusAutorizacao() == .denied
    }
}

#Preview {
    ListaView()
        .environmentObject(GerenciadorDeCompra())
        .modelContainer(SeedData.containerDePreview())
}
