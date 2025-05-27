//
//  IpcSocket.swift
//  RapidsControl
//  Purpose is to create a Unix Domain Socket to communicate to plugins or other
//  local applications.  For example, to allow a StreamDeck to command Zoom.
//
//  Created by Matt Schouten on 5/18/25.
//

import Foundation
import NIO

struct CommandMessage: Decodable {
    let type: String
    let command: String
}

struct ZoomStatusMessage: Codable {
    let type: String
    let audioStatus: String
    let videoStatus: String
}

class ZoomCommandHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private var messageBuffer = ""
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        if let received = buffer.readString(length: buffer.readableBytes) {
            print("Received: \(received)")
            messageBuffer += received
           
            // Process newline-delimited messages individually
            while let newlineRange = messageBuffer.range(of: "\n") {
                let message = String(messageBuffer[..<newlineRange.lowerBound])
                messageBuffer = String(messageBuffer[newlineRange.upperBound...])
                
                print("Processing \(message)")
                
                guard let data = message.data(using: .utf8),
                      let parsed = try? JSONDecoder().decode(CommandMessage.self, from: data) else {
                    print("Invalid message")
                    print(data)
                    return
                }
                
                let response: String
                
                switch parsed.command.trimmingCharacters(in: .whitespacesAndNewlines) {
                case "mute":
                    muteZoom()
                    response = "Muted"
                case "unmute":
                    unmuteZoom()
                    response = "Unmuted"
                case "videoOff":
                    turnOffZoomVideo()
                    response = "Video Off"
                case "videoOn":
                    turnOnZoomVideo()
                    response = "Video On"
                case "endForAll":
                    endMeetingForAll()
                    response = "End For All"
                case "getStatus":
                    let audioStatus = getAudioStatus()
                    let responseMessage = ZoomStatusMessage(type: "status", audioStatus: String(describing: audioStatus), videoStatus: "unknown")
                    if let jsonData = try? JSONEncoder().encode(responseMessage),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        response = jsonString
                    } else {
                        response = "staus broke"
                    }
                default:
                    response = "Unknown Command"
                }
                
                var outBuffer = context.channel.allocator.buffer(capacity: 256)
                outBuffer.writeString(response + "\n")
                context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
            }
        }
    }
}

public class UDSZoomServer {
    private var socketPath: String = ""
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var channel: Channel?
    
    public init() {}

    func start(socketPath: String = "/tmp/rapidscontrol.sock") {
        self.socketPath = socketPath
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in channel.pipeline.addHandler((ZoomCommandHandler())) }
        
        unlink(socketPath)
        
        do {
            self.channel = try bootstrap.bind(unixDomainSocketPath: socketPath).wait()
            print("UDS Server started and listening on \(socketPath)")
        } catch {
            print("Failed to start UDS Server: \(error)")
        }
    }
    
    public func stop() {
        print("SHUTTING DOWN")
        do {
            try channel?.close().wait()
            try group.syncShutdownGracefully()
        } catch {
            print("Error shutting down UDS server: \(error)")
        }
    }
}
