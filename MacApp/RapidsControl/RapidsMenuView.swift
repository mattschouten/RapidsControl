import SwiftUI
import Combine

struct RapidsMenuView: View {
    @State private var audioStatus: ZoomAudioStatus = .unknown
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Label {
                Text("Mute Status")
            } icon: {
                switch audioStatus {
                case .muted:
                    Image(systemName: "mic.slash.fill")
                        .foregroundColor(.red)
                case .unmuted:
                    Image(systemName: "mic.fill")
                case .unknown:
                    Image(systemName: "questionmark.circle")
                }
            }
            
            Divider()
            
            Button("Mute Zoom") {
                muteZoom()
                audioStatus = getAudioStatus()
            }
            
            Button("Unmute Zoom") {
                unmuteZoom()
                audioStatus = getAudioStatus()
            }
            
            Button("Start Video") {
                turnOnZoomVideo()
            }
            
            Button("Stop Video") {
                turnOffZoomVideo()
            }
            
            Button("End Meeting for All") {
                endMeetingForAll()
            }

            Button("Refresh Status") {
                audioStatus = getAudioStatus()
            }
            
            Button(action: {
                switch audioStatus {
                case .muted:
                    unmuteZoom()
                case .unmuted:
                    muteZoom()
                case .unknown:
                    break // Only need to update audio status
                }
                audioStatus = getAudioStatus()
            }) {
                Label(toggleLabelText(), systemImage: toggleIconName())
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            audioStatus = getAudioStatus()
        }
        .onReceive(timer) { _ in
            audioStatus = getAudioStatus()
            print(audioStatus)
        }
        .padding()
    }
    
    func toggleLabelText() -> String {
        switch audioStatus {
        case .muted:
            return "Unmute Zoom"
        case .unmuted:
            return "Mute Zoom"
        case .unknown:
            return "Refresh Status"
        }
    }
    
    func toggleIconName() -> String {
        switch audioStatus {
        case .muted:
            return "mic.slash.fill"
        case .unmuted:
            return "mic.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
}
