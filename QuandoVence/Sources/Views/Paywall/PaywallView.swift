// PaywallView.swift — desbloqueio de cadastro ilimitado (spec 8.8, regra 11.6).
//
// Aparece SÓ ao tentar adicionar o 6º documento sem ter comprado (spec 8.8) — nunca
// na abertura, nunca ao ver/editar/excluir. Sem referência visual no protótipo
// (assunção 8): segue apenas a paleta e a tipografia da seção 16, com o mesmo tom
// sóbrio do app (nada de ilustração — princípio 0.4). Oferece a compra única e
// "Restaurar compra" (spec 8.8/13). O preço vem de `product.displayPrice`.

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var compra: GerenciadorDeCompra

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Documentos ilimitados")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                    Text("Os 5 primeiros documentos são gratuitos. Desbloqueie o cadastro ilimitado com um pagamento único — sem assinatura.")
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.textSecondary)
                        .lineSpacing(3)
                        .padding(.top, 10)

                    cardBeneficios.padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            rodape
        }
        .background(Palette.screen)
        .task { await compra.carregar() }
        .onChange(of: compra.compraDesbloqueada) { _, desbloqueou in
            if desbloqueou { dismiss() }   // libera o cadastro imediatamente (spec 8.8)
        }
    }

    private var cabecalho: some View {
        HStack {
            Button("Cancelar") { dismiss() }
                .font(.system(size: 17)).tint(Palette.systemBlue)
                .frame(minHeight: 44).padding(.horizontal, 10)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 10)
        .overlay(alignment: .bottom) { Divider().overlay(Palette.barBorder) }
    }

    // Lista de benefícios (spec 8.8) — três linhas sóbrias, sem cor de marca.
    private var cardBeneficios: some View {
        VStack(spacing: 0) {
            beneficio("Cadastre quantos documentos quiser", divisor: true)
            beneficio("Avisos automáticos antes de cada vencimento", divisor: true)
            beneficio("Tudo salvo só no seu iPhone, sem conta nem nuvem", divisor: false)
        }
        .documentoCard()
    }

    private func beneficio(_ texto: String, divisor: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.top, 2)
                Text(texto).font(.system(size: 15)).foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
            if divisor { Divider().overlay(Palette.hairline).padding(.leading, 18) }
        }
    }

    // Botões de ação: comprar e restaurar (spec 8.8/13).
    private var rodape: some View {
        VStack(spacing: 12) {
            Divider().overlay(Palette.barBorder)
            if let mensagem = compra.mensagem {
                Text(mensagem).font(.system(size: 13)).foregroundStyle(Palette.destructive)
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
            }
            Button { Task { await compra.comprar() } } label: {
                Text(textoBotaoComprar)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Palette.primaryButton)
                    .foregroundStyle(Palette.primaryButtonText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(compra.processando)
            .padding(.horizontal, 20)

            Button { Task { await compra.restaurar() } } label: {
                Text("Restaurar compra").font(.system(size: 15))
            }
            .tint(Palette.systemBlue)
            .disabled(compra.processando)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .background(Palette.screen.opacity(0.92))
    }

    // Texto do botão de compra, com o preço quando disponível (spec 8.8).
    private var textoBotaoComprar: String {
        if compra.processando { return "Processando…" }
        if let preco = compra.precoExibicao { return "Desbloquear por \(preco)" }
        return "Desbloquear"
    }
}

#Preview {
    PaywallView().environmentObject(GerenciadorDeCompra())
}
