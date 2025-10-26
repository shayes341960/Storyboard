import Foundation
#if canImport(SwiftUI)
import SwiftUI
import StoryboardCore

public struct DynamicConstraintsPlayground: View {
  @State private var config = GenerationConfig()

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        ForEach(config.schema.dimensions) { dimension in
          slider(for: dimension)
        }
        previewSection
      }
      .padding()
    }
    .animation(.easeInOut(duration: 0.2), value: config.values)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Dynamic Constraints Playground")
        .font(.title2)
        .bold()
      Text("Tune tone, pacing, and dialogue density to see an updated sample paragraph instantly.")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
  }

  private func slider(for dimension: GenerationConstraintSchema.Dimension) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(dimension.title)
            .font(.headline)
          Text(dimension.description)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Text(config.values.formattedPercentage(for: dimension.axis))
          .font(.callout)
          .monospacedDigit()
          .foregroundColor(.secondary)
      }

      Slider(
        value: binding(for: dimension.axis),
        in: dimension.range,
        step: dimension.step
      )

      Text(config.schema.caption(for: dimension.axis, value: config.values.value(for: dimension.axis)))
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.secondary.opacity(0.1))
    )
  }

  private var previewSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Preview")
        .font(.headline)
      Text(config.previewParagraph())
        .font(.body)
        .foregroundColor(.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
  }

  private func binding(for axis: GenerationConstraintSchema.Dimension.Axis) -> Binding<Double> {
    Binding(
      get: { config.values.value(for: axis) },
      set: { newValue in
        config.setValue(newValue, for: axis)
      }
    )
  }
}

struct DynamicConstraintsPlayground_Previews: PreviewProvider {
  static var previews: some View {
    DynamicConstraintsPlayground()
      .previewLayout(.sizeThatFits)
  }
}
#endif

#if !canImport(SwiftUI)
public struct DynamicConstraintsPlayground {
  public init() {}
}
#endif
