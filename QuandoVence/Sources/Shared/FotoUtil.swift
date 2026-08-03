// FotoUtil.swift — preparação da foto de referência para o modelo (spec 7/20).
//
// A foto é guardada como binário no próprio `documento.foto`
// (`@Attribute(.externalStorage)`, spec 7), então aqui só redimensionamos (≤1200px
// no lado maior) e comprimimos em JPEG (~0.7) antes de gravar, para manter o
// tamanho sob controle. A foto nunca sai do aparelho (spec 20).

import UIKit

enum FotoUtil {

    private static let maxDimension: CGFloat = 1200   // lado maior máximo (spec 4)
    private static let jpegQuality: CGFloat = 0.7     // compressão JPEG (spec 4)

    // Converte uma imagem escolhida em `Data` JPEG pronto para o modelo (spec 7).
    // Redimensiona mantendo proporção; imagens já menores não são ampliadas.
    static func dadosJPEG(de image: UIImage) -> Data? {
        redimensionar(image, maxDimension: maxDimension).jpegData(compressionQuality: jpegQuality)
    }

    // Redimensiona mantendo a proporção para o lado maior caber em `maxDimension`.
    private static func redimensionar(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let novoTamanho = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: novoTamanho)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: novoTamanho)) }
    }
}
