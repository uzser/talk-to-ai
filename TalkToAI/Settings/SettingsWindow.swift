import SwiftUI

struct SettingsWindow: View {
    @Binding var isSettingsWindowOpen: Bool

    var body: some View {
        SettingsView()
            .frame(width: 400, height: 300)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SettingsWindow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsWindow(isSettingsWindowOpen: .constant(true))
    }
}
