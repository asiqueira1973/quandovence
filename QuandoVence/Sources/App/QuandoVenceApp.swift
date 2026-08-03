// QuandoVenceApp.swift — ponto de entrada do app "Quando Vence?" (spec 4).
//
// Sobe o ModelContainer local-first (ContainerModelo, spec 0.1/4), registra os
// defaults de aviso da seção 7, injeta o GerenciadorDeCompra e reavalia o
// entitlement a cada abertura (spec 8.8, critério 4). A navegação real (Lista →
// Detalhe/Formulário/Ajustes/Paywall) vive em ListaView (spec 10).

import SwiftUI
import SwiftData

@main
struct QuandoVenceApp: App {

    let container: ModelContainer
    @StateObject private var compra = GerenciadorDeCompra()

    init() {
        // Defaults dos avisos (spec 7) — antes de qualquer leitura de Ajustes.
        UserDefaults.standard.register(defaults: ChavesAviso.defaults)
        do {
            container = try ContainerModelo.criar()
        } catch {
            // Falha ao subir o store local é erro de ambiente, não estado de
            // usuário — travar cedo facilita o diagnóstico.
            fatalError("Falha ao criar o ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ListaView()
                .environmentObject(compra)
                .tint(Palette.systemBlue)   // azul de sistema p/ ‹ voltar e links (spec 16)
                // Reavalia o entitlement a cada abertura (spec 8.8, critério 4).
                // Leitura preguiçosa: não dispara prompt de conta Apple no launch.
                .task { await compra.atualizarEntitlementsSilencioso() }
                #if DEBUG
                // Auto-seed opcional para capturar screenshots com volume de dados
                // (env QUANDOVENCE_SEED=1). Só DEBUG, nunca release (spec 7/18).
                .task { autoSeedSeSolicitado() }
                #endif
        }
        .modelContainer(container)
    }

    #if DEBUG
    // Popula os exemplos do protótipo quando QUANDOVENCE_SEED=1 e a base está vazia
    // — atalho de teste/screenshot (spec 7/22). Nunca roda em release.
    @MainActor
    private func autoSeedSeSolicitado() {
        guard ProcessInfo.processInfo.environment["QUANDOVENCE_SEED"] == "1" else { return }
        let ctx = container.mainContext
        let vazio = (try? ctx.fetch(FetchDescriptor<Documento>()))?.isEmpty ?? true
        if vazio { SeedData.popular(context: ctx) }
    }
    #endif
}
