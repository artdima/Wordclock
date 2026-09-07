import SwiftUI

struct ConfigureView: View {
    @State var settings: SaverSettings
    let onCancel: () -> Void
    let onSave: (SaverSettings) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Wordclock")
                .font(.title2.weight(.semibold))

            Picker("Язык", selection: $settings.language) {
                ForEach(ClockLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Toggle("Менять формулировки", isOn: $settings.variety)
            Toggle("Смещать текст (защита экрана)", isOn: $settings.drift)

            VStack(alignment: .leading, spacing: 6) {
                Text("Размер текста")
                Slider(value: $settings.textScale, in: 0.5...1.6)
            }

            HStack {
                Spacer()
                Button("Отмена", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Готово") { onSave(settings) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
