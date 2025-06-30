//
//  RapidsController.swift
//  RapidsControl
//
//  Created by Matt Schouten on 5/31/25.
//

import Foundation

class RapidsController: ObservableObject {
    @Published var audioStatus: ZoomAudioStatus = .unknown
    @Published var videoStatus: ZoomVideoStatus = .unknown
    var lastAudioStatus: ZoomAudioStatus = .unknown
    var lastVideoStatus: ZoomVideoStatus = .unknown
    
    private var inMeeting = false
    
    private let udsServer = UDSZoomServer()
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.refreshStatus()
            // TODO:  Add backoff if Zoom isn't running.  Maybe go to 10s until the app is found.
        }
    }
    
    func refreshStatus() {
        audioStatus = getAudioStatus()
        videoStatus = getVideoStatus()
        inMeeting = isMeetingActive()
        
        var shouldSendStatusUpdate = false

        if audioStatus != lastAudioStatus {
            print("Audio status now \(audioStatus)")
            shouldSendStatusUpdate = true
        }
        
        if videoStatus != lastVideoStatus {
            print("Video status now \(videoStatus)")
            shouldSendStatusUpdate = true
        }
        
        lastAudioStatus = audioStatus
        lastVideoStatus = videoStatus
        
        if shouldSendStatusUpdate {
            print("Sending status update!!!!")
            sendStatusUpdate()
        }
    }
    
    func sendStatusUpdate() {
        udsServer.sendStatusUpdate(audioStatus: audioStatus, videoStatus: videoStatus, inMeeting: inMeeting)
    }
    
    func startServer() {
        udsServer.start()
    }
    
    func stopServer() {
        udsServer.stop()
    }
}
