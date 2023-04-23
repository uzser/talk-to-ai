// TODO: Settings
#if os(macOS)
import SwiftUI

struct MainMenu: Commands {
    var viewModel: SpeechRecognitionViewModel

    var body: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.appSettings) {
            Button(action: {
                viewModel.showSettings.toggle()
            }) {
                Text("Settings")
            }
        }
    }
}
#endif
