import Foundation

/// A container for slider-driven narrative constraints.
public struct GenerationConfig: Codable, Equatable {
  public var schema: GenerationConstraintSchema
  public var values: GenerationConstraintValues

  public init(schema: GenerationConstraintSchema = .default, values: GenerationConstraintValues? = nil) {
    self.schema = schema
    if let provided = values {
      self.values = provided.clamped(to: schema)
    } else {
      self.values = GenerationConstraintValues(schema: schema)
    }
  }

  /// Returns a preview paragraph showing how the active values influence narration.
  public func previewParagraph() -> String {
    Self.previewParagraph(for: values)
  }

  /// Builds a preview paragraph for a custom set of values.
  public static func previewParagraph(for values: GenerationConstraintValues) -> String {
    PreviewBuilder(values: values).compose()
  }

  /// Updates the stored value for a slider axis while clamping to the schema's range.
  public mutating func setValue(_ newValue: Double, for axis: GenerationConstraintSchema.Dimension.Axis) {
    values.setValue(newValue, for: axis, clampedTo: schema.range(for: axis))
  }
}

// MARK: - Schema

public struct GenerationConstraintSchema: Codable, Equatable {
  public struct Dimension: Codable, Equatable, Identifiable {
    public enum Axis: String, Codable, CaseIterable {
      case tone
      case pacing
      case dialogueDensity
    }

    public var id: Axis { axis }

    public let axis: Axis
    public let title: String
    public let description: String
    public let range: ClosedRange<Double>
    public let defaultValue: Double
    public let step: Double

    public init(
      axis: Axis,
      title: String,
      description: String,
      range: ClosedRange<Double>,
      defaultValue: Double,
      step: Double
    ) {
      self.axis = axis
      self.title = title
      self.description = description
      self.range = range
      self.defaultValue = defaultValue
      self.step = step
    }
  }

  public let dimensions: [Dimension]

  public init(dimensions: [Dimension]) {
    self.dimensions = dimensions
  }

  public func range(for axis: Dimension.Axis) -> ClosedRange<Double> {
    definition(for: axis).range
  }

  public func definition(for axis: Dimension.Axis) -> Dimension {
    guard let dimension = dimensions.first(where: { $0.axis == axis }) else {
      fatalError("Schema missing definition for axis \(axis)")
    }
    return dimension
  }

  public func caption(for axis: Dimension.Axis, value: Double) -> String {
    axis.caption(for: value)
  }

  public static let `default` = GenerationConstraintSchema(
    dimensions: [
      Dimension(
        axis: .tone,
        title: "Tone",
        description: "Slide between uplifting and brooding moods.",
        range: 0.0...1.0,
        defaultValue: 0.5,
        step: 0.05
      ),
      Dimension(
        axis: .pacing,
        title: "Pacing",
        description: "Adjust how quickly the scene moves.",
        range: 0.0...1.0,
        defaultValue: 0.5,
        step: 0.05
      ),
      Dimension(
        axis: .dialogueDensity,
        title: "Dialogue Density",
        description: "Balance narration with spoken lines.",
        range: 0.0...1.0,
        defaultValue: 0.4,
        step: 0.05
      )
    ]
  )
}

// MARK: - Values

public struct GenerationConstraintValues: Codable, Equatable {
  public var tone: Double
  public var pacing: Double
  public var dialogueDensity: Double

  public init(tone: Double, pacing: Double, dialogueDensity: Double) {
    self.tone = tone
    self.pacing = pacing
    self.dialogueDensity = dialogueDensity
  }

  public init(schema: GenerationConstraintSchema = .default) {
    self.init(
      tone: schema.definition(for: .tone).defaultValue,
      pacing: schema.definition(for: .pacing).defaultValue,
      dialogueDensity: schema.definition(for: .dialogueDensity).defaultValue
    )
  }

  public func value(for axis: GenerationConstraintSchema.Dimension.Axis) -> Double {
    switch axis {
    case .tone:
      return tone
    case .pacing:
      return pacing
    case .dialogueDensity:
      return dialogueDensity
    }
  }

  public mutating func setValue(
    _ newValue: Double,
    for axis: GenerationConstraintSchema.Dimension.Axis,
    clampedTo range: ClosedRange<Double>
  ) {
    let clampedValue = newValue.clamped(to: range)
    switch axis {
    case .tone:
      tone = clampedValue
    case .pacing:
      pacing = clampedValue
    case .dialogueDensity:
      dialogueDensity = clampedValue
    }
  }

  public func clamped(to schema: GenerationConstraintSchema) -> GenerationConstraintValues {
    var values = self
    for dimension in schema.dimensions {
      values.setValue(value(for: dimension.axis), for: dimension.axis, clampedTo: dimension.range)
    }
    return values
  }

  public func formattedPercentage(for axis: GenerationConstraintSchema.Dimension.Axis) -> String {
    String(format: "%.0f%%", value(for: axis) * 100)
  }
}

private extension Double {
  func clamped(to range: ClosedRange<Double>) -> Double {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

// MARK: - Captions

private extension GenerationConstraintSchema.Dimension.Axis {
  func caption(for value: Double) -> String {
    switch self {
    case .tone:
      if value < 0.34 { return "Playful, optimistic cadence." }
      if value > 0.66 { return "Brooding with dramatic tension." }
      return "Balanced tone with layered nuance."
    case .pacing:
      if value < 0.34 { return "Slow burn with lingering detail." }
      if value > 0.66 { return "Tight, high-energy beats." }
      return "Measured rhythm with room to breathe."
    case .dialogueDensity:
      if value < 0.34 { return "Primarily descriptive narration." }
      if value > 0.66 { return "Dialogue-driven interaction." }
      return "Even split between action and voice."
    }
  }
}

// MARK: - Preview Builder

private struct PreviewBuilder {
  let values: GenerationConstraintValues

  func compose() -> String {
    let toneStyle = ToneStyle(value: values.tone)
    let pacingStyle = PacingStyle(value: values.pacing)
    let dialogueStyle = DialogueStyle(value: values.dialogueDensity)

    var sentences: [String] = []

    sentences.append(introSentence(for: toneStyle))
    sentences.append(contentsOf: middleSentences(for: toneStyle, pacing: pacingStyle))

    if let dialogue = dialogueSentence(for: toneStyle, dialogue: dialogueStyle) {
      sentences.append(dialogue)
    }

    sentences.append(closer(for: toneStyle, pacing: pacingStyle, dialogue: dialogueStyle))

    return sentences.joined(separator: " ")
  }

  private func introSentence(for tone: ToneStyle) -> String {
    switch tone {
    case .bright:
      return "Sunlight combs the studio, painting the sketches in a gold hush."
    case .balanced:
      return "Morning light filters through the blinds, sketching stripes across the floor."
    case .brooding:
      return "Clouded dawn presses against the window, smudging the studio in smoke-grey hues."
    }
  }

  private func middleSentences(for tone: ToneStyle, pacing: PacingStyle) -> [String] {
    let anchor: String
    switch tone {
    case .bright:
      anchor = "Ideas spark like quicksilver, eager to be shaped."
    case .balanced:
      anchor = "Each idea settles into place, waiting to be coaxed alive."
    case .brooding:
      anchor = "Every outline feels heavy, dragging new tension into the room."
    }

    switch pacing {
    case .slow:
      return [
        "Breaths slow, letting texture and color seep into every thought.",
        "The next beat waits patiently, savoring the pause between decisions.",
        anchor
      ]
    case .moderate:
      return [
        "Steps sweep from canvas to storyboard in a steady rhythm.",
        anchor
      ]
    case .fast:
      return [
        "Notes scatter across the table as momentum snaps forward.",
        anchor.rephrasedAsMomentum()
      ]
    }
  }

  private func dialogueSentence(for tone: ToneStyle, dialogue: DialogueStyle) -> String? {
    switch dialogue {
    case .sparse:
      return nil
    case .balanced:
      return "\"Let’s frame it around the reveal,\" someone says, voice matching the \(tone.dialogueMood)."
    case .dense:
      return "\"Cut to the twist,\" one voice urges. \"Hold the silence,\" another counters, their exchange charged with \(tone.dialogueMood)."
    }
  }

  private func closer(for tone: ToneStyle, pacing: PacingStyle, dialogue: DialogueStyle) -> String {
    let pacingTag: String
    switch pacing {
    case .slow:
      pacingTag = "The scene settles like ink in water, deliberate and sure."
    case .moderate:
      pacingTag = "The scene finds its cadence, ready for the next revision."
    case .fast:
      pacingTag = "The scene snaps into focus, already racing toward the next beat."
    }

    let dialogueTail = dialogue == .dense ? "Voices overlap with a kinetic hum." : (dialogue == .balanced ? "A quiet agreement follows." : "Silence seals the choice.")

    return "\(tone.afterglow) \(pacingTag) \(dialogueTail)"
  }
}

private enum ToneStyle {
  case bright
  case balanced
  case brooding

  init(value: Double) {
    if value < 0.34 {
      self = .bright
    } else if value > 0.66 {
      self = .brooding
    } else {
      self = .balanced
    }
  }

  var dialogueMood: String {
    switch self {
    case .bright:
      return "hopeful spark"
    case .balanced:
      return "collected focus"
    case .brooding:
      return "restless grit"
    }
  }

  var afterglow: String {
    switch self {
    case .bright:
      return "A warm buzz lingers across the room."
    case .balanced:
      return "Calm energy hangs between the team."
    case .brooding:
      return "A taut quiet clings to the drafting table."
    }
  }
}

private enum PacingStyle {
  case slow
  case moderate
  case fast

  init(value: Double) {
    if value < 0.34 {
      self = .slow
    } else if value > 0.66 {
      self = .fast
    } else {
      self = .moderate
    }
  }
}

private enum DialogueStyle {
  case sparse
  case balanced
  case dense

  init(value: Double) {
    if value < 0.34 {
      self = .sparse
    } else if value > 0.66 {
      self = .dense
    } else {
      self = .balanced
    }
  }
}

private extension String {
  func rephrasedAsMomentum() -> String {
    guard let commaIndex = firstIndex(of: ",") else {
      return replacingOccurrences(of: " feels", with: " flashes").replacingOccurrences(of: " settles", with: " surges")
    }
    let prefix = String(self[..<commaIndex])
    let suffix = String(self[commaIndex...]).replacingOccurrences(of: " feels", with: " crackles")
    return prefix + suffix
  }
}
