//  Created by Matt Schouten on 5/1/25.
//

import ArgumentParser
import SwiftUI

struct ControlArguments: ParsableCommand {
    @Option(name: [.customLong("command")],
            help: "Command to execute:  mute, unmute, status")
    var command: String?
    
    mutating func run() throws {
        if let command {
            print("Executing command: \(command)")
            switch command {
            case "mute":
                muteZoom()
            case "unmute":
                unmuteZoom()
            case "status":
                let audioStatus = getAudioStatus()
                print("Audio:  \(audioStatus)")
            case "grantaccessibility":
                print("Requesting perms")
                requestAccessibilityPermissions()
            default:
                print("Unknown command: \(command)")
                throw ExitCode(1)
            }
        }
        else
        {
            // No command given.  Run the GUI.
            print("no command");
            RapidsControlApp.main()
        }
    }
}

ControlArguments.main()
