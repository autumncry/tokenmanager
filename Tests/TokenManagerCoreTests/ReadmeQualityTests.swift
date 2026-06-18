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
        XCTAssertLessThan(
            readme.range(of: "## 中文")!.lowerBound,
            readme.range(of: "## English")!.lowerBound)
        XCTAssertTrue(readme.contains("100% 本地"))
        XCTAssertTrue(readme.contains("没有项目服务器"))
        XCTAssertTrue(readme.contains("无任何隐私风险"))
        XCTAssertTrue(readme.contains("macOS 钥匙串"))
        XCTAssertFalse(readme.contains("中文优先"))
        XCTAssertFalse(readme.contains("中文默认"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("Chinese UI by default"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("Chinese-default"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("CodexBar"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("Thaw"))
    }
}
