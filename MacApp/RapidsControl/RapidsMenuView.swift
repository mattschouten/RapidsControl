import SwiftUI
import Combine

struct RapidsMenuView: View {
    @EnvironmentObject var controller: RapidsController

    var body: some View {
        VStack {
            // TODO:  ADD a status display, maybe with icons.
            
            Button("Mute Zoom") {
                muteZoom()
                controller.refreshStatus()
            }
            
            Button("Unmute Zoom") {
                unmuteZoom()
                controller.refreshStatus()
            }
            
            Button("Start Video") {
                turnOnZoomVideo()
                controller.refreshStatus()
            }
            
            Button("Stop Video") {
                turnOffZoomVideo()
                controller.refreshStatus()
            }
            
            Button("End Meeting for All") {
                endMeetingForAll()
            }

            Divider()
            
            Button("Force Status Refresh") {
                controller.refreshStatus()
            }
            
            Divider()
            
            Button(action: {
                switch controller.audioStatus {
                case .muted:
                    unmuteZoom()
                case .unmuted:
                    muteZoom()
                case .unknown:
                    break // Only need to update audio status
                }
                controller.refreshStatus()
            }) {
                Label(toggleAudioLabelText(), systemImage: toggleAudioIconName())
            }
            
            Button(action: {
                switch controller.videoStatus {
                case .off:
                    turnOnZoomVideo()
                case .on:
                    turnOffZoomVideo()
                case .unknown:
                    break // Only need to update video status
                }
                controller.refreshStatus()
            }) {
                Label(toggleVideoLabelText(), systemImage: toggleVideoIconName())
            }

            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            controller.refreshStatus()
        }
        .padding()
    }

    func toggleAudioLabelText() -> String {
        switch controller.audioStatus {
        case .muted:
            return "Toggle:  Unmute Zoom"
        case .unmuted:
            return "Toggle:  Mute Zoom"
        case .unknown:
            return "Toggle Mute"
        }
    }
    
    func toggleAudioIconName() -> String {
        switch controller.audioStatus {
        case .muted:
            return "mic.slash.fill"
        case .unmuted:
            return "mic.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
    
    func toggleVideoLabelText() -> String {
        switch controller.videoStatus {
        case .on:
            return "Toggle:  Stop Video"
        case .off:
            return "Toggle:  Start Video"
        case .unknown:
            return "Toggle Video"
        }
    }
    
    func toggleVideoIconName() -> String {
        switch controller.videoStatus {
        case .on:
            return "video.slash.fill"
        case .off:
            return "video.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
}
