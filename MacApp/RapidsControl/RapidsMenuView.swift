import SwiftUI
import Combine

struct RapidsMenuView: View {
    @State private var audioStatus: ZoomAudioStatus = .unknown
    @State private var lastAudioStatus: ZoomAudioStatus = .unknown
    @State private var videoStatus: ZoomVideoStatus = .unknown
    @State private var lastVideoStatus: ZoomVideoStatus = .unknown

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
                Label(toggleAudioLabelText(), systemImage: toggleAudioIconName())
            }
            
            Button(action: {
                switch videoStatus {
                case .off:
                    turnOnZoomVideo()
                case .on:
                    turnOffZoomVideo()
                case .unknown:
                    break // Only need to update video status
                }
                videoStatus = getVideoStatus()
            }) {
                Label(toggleVideoLabelText(), systemImage: toggleVideoIconName())
            }

            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            audioStatus = getAudioStatus()
            videoStatus = getVideoStatus()
        }
        .onReceive(timer) { _ in
            audioStatus = getAudioStatus()
            videoStatus = getVideoStatus()

            if audioStatus != lastAudioStatus {
                print("Audio status now \(audioStatus)")
            }
            
            if videoStatus != lastVideoStatus {
                print("Video status now \(videoStatus)")
            }

            lastAudioStatus = audioStatus
            lastVideoStatus = videoStatus
        }
        .padding()
    }

    func toggleAudioLabelText() -> String {
        switch audioStatus {
        case .muted:
            return "Toggle:  Unmute Zoom"
        case .unmuted:
            return "Toggle:  Mute Zoom"
        case .unknown:
            return "Toggle Mute"
        }
    }
    
    func toggleAudioIconName() -> String {
        switch audioStatus {
        case .muted:
            return "mic.slash.fill"
        case .unmuted:
            return "mic.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
    
    func toggleVideoLabelText() -> String {
        switch videoStatus {
        case .on:
            return "Toggle:  Stop Video"
        case .off:
            return "Toggle:  Start Video"
        case .unknown:
            return "Toggle Video"
        }
    }
    
    func toggleVideoIconName() -> String {
        switch videoStatus {
        case .on:
            return "video.slash.fill"
        case .off:
            return "video.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
}
