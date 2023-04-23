import SwiftUI

// TODO: Settings
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var toggleValue: Bool = false

    var body: some View {
        VStack {
            Form {
                Section(header: Text("General")) {
                    Toggle("Toggle switch", isOn: $toggleValue)
                }
            }
#if os(iOS)
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
#elseif os(macOS)
            .frame(width: 300, height: 200)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
#endif
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
