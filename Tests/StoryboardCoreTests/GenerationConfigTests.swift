import XCTest
@testable import StoryboardCore

final class GenerationConfigTests: XCTestCase {
  func testDefaultValuesMatchSchema() {
    let config = GenerationConfig()
    XCTAssertEqual(config.schema.dimensions.count, 3)
    XCTAssertEqual(config.schema.definition(for: .tone).defaultValue, config.values.tone, accuracy: 0.0001)
    XCTAssertEqual(config.schema.definition(for: .pacing).defaultValue, config.values.pacing, accuracy: 0.0001)
    XCTAssertEqual(config.schema.definition(for: .dialogueDensity).defaultValue, config.values.dialogueDensity, accuracy: 0.0001)
  }

  func testPreviewRespondsToDialogueDensity() {
    var config = GenerationConfig()
    let baseline = config.previewParagraph()

    config.setValue(0.8, for: .dialogueDensity)
    let dialogueHeavy = config.previewParagraph()

    XCTAssertNotEqual(baseline, dialogueHeavy)
    XCTAssertTrue(dialogueHeavy.contains("\""))
  }

  func testPreviewRespondsToToneAndPacing() {
    var config = GenerationConfig()
    config.setValue(0.2, for: .tone)
    config.setValue(0.2, for: .pacing)
    let warmSlow = config.previewParagraph()

    config.setValue(0.9, for: .tone)
    config.setValue(0.9, for: .pacing)
    let darkFast = config.previewParagraph()

    XCTAssertNotEqual(warmSlow, darkFast)
    XCTAssertTrue(warmSlow.contains("Sunlight") || warmSlow.contains("Morning"))
    XCTAssertTrue(darkFast.contains("Clouded") || darkFast.contains("momentum"))
  }
}
