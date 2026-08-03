// IconeCategoria.swift — ícones de linha do app (spec 16, assunção 4).
//
// Recria os 5 ícones de categoria com os PATHS EXATOS do protótipo (objeto `CATS`)
// e os dois ícones de sistema (engrenagem de Ajustes e câmera do formulário),
// desenhados com stroke de linha (sem preenchimento), cantos e pontas
// arredondados, como no design. A espessura do traço acompanha o tamanho para
// manter a proporção original (1.7/24 nos ícones de categoria, 1.6/24 nos de
// sistema — spec 16).

import SwiftUI

/// Paths SVG de cada categoria, copiados LITERALMENTE do objeto `CATS` do
/// protótipo (spec 16). A chave é o mesmo `rawValue` do enum.
enum CategoriaPaths {
    static let paths: [categoria_documento: [String]] = [
        .viagem:   ["M12 3a9 9 0 100 18 9 9 0 000-18", "M3.2 12h17.6",
                    "M12 3c2.6 2.7 2.6 15.3 0 18", "M12 3c-2.6 2.7-2.6 15.3 0 18"],
        .pessoal:  ["M12 11.2a3.6 3.6 0 100-7.2 3.6 3.6 0 000 7.2",
                    "M4.8 20c0-3.4 3.2-5.6 7.2-5.6s7.2 2.2 7.2 5.6"],
        .trabalho: ["M3.6 8.4h16.8v10.8H3.6z", "M9 8.4V6.2h6v2.2", "M3.6 13.2h16.8"],
        .saude:    ["M12 5.4v13.2", "M5.4 12h13.2"],
        .veiculo:  ["M4 15.2l1.7-5.1A2.2 2.2 0 017.8 8.6h8.4a2.2 2.2 0 012.1 1.5l1.7 5.1v3.6h-2.6v-2H6.6v2H4z",
                    "M7.2 15.2h1.6", "M15.2 15.2h1.6"],
    ]
}

/// Shape genérico que desenha uma lista de paths SVG no viewBox 24×24 (spec 16).
struct SVGShape: Shape {
    let commands: [String]
    func path(in rect: CGRect) -> Path {
        SVGPath.path(for: commands, in: rect)
    }
}

/// Ícone de uma categoria, traçado (não preenchido), com espessura proporcional
/// ao tamanho (spec 16, assunção 4).
struct CategoriaIconView: View {
    let categoria: categoria_documento
    var size: CGFloat = 17
    var color: Color = Palette.textMuted

    var body: some View {
        SVGShape(commands: CategoriaPaths.paths[categoria] ?? [])
            .stroke(color, style: StrokeStyle(lineWidth: size / 24 * 1.7,
                                              lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

/// Ícone de engrenagem (Ajustes) — círculo + raios, traço 1.6/24 (protótipo).
struct EngrenagemIconView: View {
    var size: CGFloat = 22
    var color: Color = Palette.textSecondary

    private let paths = [
        "M8.8 12a3.2 3.2 0 106.4 0 3.2 3.2 0 10-6.4 0",
        "M12 3.2v2M12 18.8v2M3.2 12h2M18.8 12h2M5.8 5.8l1.5 1.5M16.7 16.7l1.5 1.5M18.2 5.8l-1.5 1.5M7.3 16.7l-1.5 1.5",
    ]

    var body: some View {
        SVGShape(commands: paths)
            .stroke(color, style: StrokeStyle(lineWidth: size / 24 * 1.6,
                                              lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

/// Ícone de câmera (linha de foto no formulário) — corpo + lente, traço 1.6/24.
struct CameraIconView: View {
    var size: CGFloat = 21
    var color: Color = Palette.textMuted

    private let paths = [
        "M3.6 8.8h3.2l1.4-2.2h7.6l1.4 2.2h3.2v9.6H3.6z",
        "M8.9 13.4a3.1 3.1 0 106.2 0 3.1 3.1 0 10-6.2 0",
    ]

    var body: some View {
        SVGShape(commands: paths)
            .stroke(color, style: StrokeStyle(lineWidth: size / 24 * 1.6,
                                              lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}
