// FlowLayout.swift — layout de quebra de linha para os chips (spec 8.3/16).
//
// SwiftUI não tem um layout "flex-wrap" nativo; este recria o comportamento dos
// chips de categoria do protótipo (`flex-wrap: wrap; gap: 8`), posicionando os
// itens em linha e quebrando para a próxima quando não cabem. Genérico e sem estado.

import SwiftUI

struct FlowLayout: Layout {
    var espacamento: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let largura = proposal.width ?? .infinity
        return arranjar(subviews: subviews, larguraMax: largura).tamanho
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let resultado = arranjar(subviews: subviews, larguraMax: bounds.width)
        for (indice, ponto) in resultado.pontos.enumerated() {
            subviews[indice].place(
                at: CGPoint(x: bounds.minX + ponto.x, y: bounds.minY + ponto.y),
                proposal: .unspecified)
        }
    }

    // Calcula a posição de cada item e o tamanho total ocupado.
    private func arranjar(subviews: Subviews, larguraMax: CGFloat) -> (pontos: [CGPoint], tamanho: CGSize) {
        var pontos: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, alturaLinha: CGFloat = 0, larguraTotal: CGFloat = 0
        for sub in subviews {
            let tamanho = sub.sizeThatFits(.unspecified)
            if x + tamanho.width > larguraMax, x > 0 {
                x = 0
                y += alturaLinha + espacamento
                alturaLinha = 0
            }
            pontos.append(CGPoint(x: x, y: y))
            x += tamanho.width + espacamento
            alturaLinha = max(alturaLinha, tamanho.height)
            larguraTotal = max(larguraTotal, x - espacamento)
        }
        return (pontos, CGSize(width: larguraTotal, height: y + alturaLinha))
    }
}
