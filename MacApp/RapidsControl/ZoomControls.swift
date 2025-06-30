//
//  ZoomControls.swift
//  RapidsControl
//
//  Created by Matt Schouten on 6/22/25.
//

enum ZoomAudioStatus {
    case muted
    case unmuted
    case unknown
}

enum ZoomVideoStatus {
    case on
    case off
    case unknown
}

func getAudioStatus() -> ZoomAudioStatus {
    if let _ = findZoomMenuItem(title: "Unmute audio") {
        return .muted
    } else if let _ = findZoomMenuItem(title: "Mute audio") {
        return .unmuted
    } else {
        return .unknown
    }
}

func getVideoStatus() -> ZoomVideoStatus {
    if let _ = findZoomMenuItem(title: "Stop video") {
        return .on
    } else if let _ = findZoomMenuItem(title: "Start video") {
        return .off
    } else {
        return .unknown
    }
}

func isMeetingActive() -> Bool {
    // TODO:  Maybe Meeting -> Fullscreen.  But audio status is already tested.
    return getAudioStatus() != .unknown
}

func muteZoom() {
    if getAudioStatus() != .muted {
        print("Muting Zoom Audio")
        if let muteMenuItem = findZoomMenuItem(title: "Mute audio") {
            _ = clickUIElement(in: muteMenuItem)
        }
    }
}

func unmuteZoom() {
    if getAudioStatus() != .unmuted {
        print("Unmuting Zoom Audio")
        if let muteMenuItem = findZoomMenuItem(title: "Unmute audio") {
            _ = clickUIElement(in: muteMenuItem)
        }
    }
}

func turnOffZoomVideo() {
    if getVideoStatus() != .off {
        print("Stopping Zoom Video")
        if let videoMenuItem = findZoomMenuItem(title: "Stop video") {
            _ = clickUIElement(in: videoMenuItem)
        }
    }
}

func turnOnZoomVideo() {
    if getVideoStatus() != .on {
        print("Starting Zoom Video")
        if let videoMenuItem = findZoomMenuItem(title: "Start video") {
            _ = clickUIElement(in: videoMenuItem)
        }
    }
}

func endMeetingForAll() {
    print("Triggering main thread worker")
    
    Task {
        await endMeetingForAllAction()
    }
}
