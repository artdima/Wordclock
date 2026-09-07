import SwiftUI

struct ConfigureView: View {
    @State var settings: SaverSettings
    let onCancel: () -> Void
    let onSave: (SaverSettings) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Wordclock")
                .font(.title2.weight(.semibold))

            Picker("Language", selection: $settings.language) {
                ForEach(ClockLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Toggle("Vary the wording", isOn: $settings.variety)
            Toggle("Shift the text to spare the display", isOn: $settings.drift)

            VStack(alignment: .leading, spacing: 6) {
                Text("Text size")
                Slider(value: $settings.textScale, in: 0.5...1.6)
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Done") { onSave(settings) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
