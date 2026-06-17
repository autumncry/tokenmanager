import XCTest

final class ReadmeQualityTests: XCTestCase {
    func testReadmeIsBilingualAndDoesNotMentionExternalReferenceProjects() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)

        XCTAssertTrue(readme.contains("## English"))
        XCTAssertTrue(readme.contains("## 中文"))
        XCTAssertTrue(readme.contains("docs/screenshots/"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("CodexBar"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("Thaw"))
    }
}
