// ListaView.swift — Home: lista de documentos agrupada por urgência (spec 8.1).
//
// Raiz de navegação do app (spec 10). Recria o protótipo pixel a pixel: header
// grande com título e engrenagem, três seções (Vencidos / Vence em breve / Em dia)
// só exibidas quando têm itens, resumo no topo, estado vazio, aviso discreto quando
// as notificações estão desativadas (spec 8.7) e o botão "Adicionar documento"
// fixo na base (spec 8.1). O botão aplica o gate do paywall no 6º documento
// (regra 11.6 / spec 8.3/8.8). A nav bar do sistema fica oculta — os cabeçalhos são
// recriados à mão para bater com o design (spec 16).

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
            .background(Palette.screen)
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

    // Cabeçalho grande com título, resumo e engrenagem (spec 16).
    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Quando Vence?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text(grupos.resumo)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Button { path.append(RotaAjustes()) } label: {
                EngrenagemIconView(size: 22, color: Palette.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Ajustes")
        }
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .padding(.top, 8)
        .padding(.bottom, 12)
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
                    secao("Vence em breve", grupos.emBreve, primeira: grupos.vencidos.isEmpty && !notificacoesNegadas)
                    secao("Em dia", grupos.emDia, primeira: grupos.vencidos.isEmpty && grupos.emBreve.isEmpty && !notificacoesNegadas)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }

    // Uma seção só é exibida quando tem itens (spec 8.1). `primeira` reduz o espaço
    // superior do primeiro rótulo para bater com o protótipo (8px vs 22px).
    @ViewBuilder
    private func secao(_ titulo: String, _ docs: [Documento], primeira: Bool) -> some View {
        if !docs.isEmpty {
            Text(titulo.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Palette.sectionLabel)
                .padding(.top, primeira ? 8 : 22)
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(docs) { doc in
                    Button { path.append(doc) } label: { CartaoDocumento(documento: doc) }
                        .buttonStyle(.plain)
                }
            }
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
            .padding(.vertical, 10)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }

    // Botão primário fixo na base (spec 8.1). Aplica o gate do paywall (regra 11.6).
    private var rodape: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.barBorder)
            Button(action: adicionar) {
                HStack(spacing: 8) {
                    Text("+").font(.system(size: 21, weight: .regular))
                    Text("Adicionar documento").font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Palette.primaryButton)
                .foregroundStyle(Palette.primaryButtonText)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Palette.screen.opacity(0.92))
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
