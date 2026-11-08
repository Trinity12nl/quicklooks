import Cocoa

@MainActor
final class PreviewViewController: TextPreviewController {
    override class func render(url: URL) throws -> NSAttributedString {
        try MarkdownRenderer.render(url: url)
    }

    override class func makeLayoutManager() -> NSLayoutManager? { MarkdownLayoutManager() }
}
