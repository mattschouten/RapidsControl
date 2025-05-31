import SwiftUI
import Combine

struct RapidsMenuView: View {
    @State private var audioStatus: ZoomAudioStatus = .unknown
    @State private var lastAudioStatus: ZoomAudioStatus = .unknown
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // TODO:  ADD a status display, maybe with icons.
            
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

            Divider()
            
            Button("Force Status Refresh") {
                audioStatus = getAudioStatus()
            }
            
            Divider()
            
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
            
            if audioStatus != lastAudioStatus {
                print("Audio status now \(audioStatus)")
            }
            
            lastAudioStatus = audioStatus
        }
        .padding()
    }

    func toggleLabelText() -> String {
        switch audioStatus {
        case .muted:
            return "Toggle:  Unmute Zoom"
        case .unmuted:
            return "Toggle:  Mute Zoom"
        case .unknown:
            return "Toggle Mute Status"
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
