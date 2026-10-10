import SwiftUI

struct ConfigureView: View {
    @State var settings: SaverSettings
    let onCancel: () -> Void
    let onSave: (SaverSettings) -> Void

    private var bundle: Bundle { WordclockBundle.bundle }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Wordclock")
                .font(.title2.weight(.semibold))

            Picker(selection: $settings.language) {
                ForEach(ClockLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            } label: {
                Text("Language", bundle: bundle)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Toggle(isOn: $settings.variety) {
                Text("Vary the wording", bundle: bundle)
            }
            Toggle(isOn: $settings.drift) {
                Text("Shift the text to spare the display", bundle: bundle)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Text size", bundle: bundle)
                    Spacer()
                    Text(settings.textScale, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.textScale, in: SaverSettings.textScaleRange)
            }

            HStack {
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel", bundle: bundle)
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    onSave(settings)
                } label: {
                    Text("Done", bundle: bundle)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
