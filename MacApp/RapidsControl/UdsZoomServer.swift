//
//  UdsZoomServer.swift
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
    
    private let channel: Channel
    private var messageBuffer = ""
    
    init(channel: Channel) {
        self.channel = channel
    }
    
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
                        response = "status broke"
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
    
    public func sendStatus(statusMessage: ZoomStatusMessage) {
        guard channel.isActive else {
            print("Channel is not active; cannot send status")
            return
        }
        
        guard let jsonData = try? JSONEncoder().encode(statusMessage),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to encode status message")
            return
        }
        
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString(jsonString + "\n")
        channel.writeAndFlush(buffer, promise: nil)
    }
}

public class UDSZoomServer {
    private var socketPath: String = ""
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var channel: Channel?
    private var handler: ZoomCommandHandler?
    
    public init() {}

    func start(socketPath: String = "/tmp/rapidscontrol.sock") {
        self.socketPath = socketPath
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let handler = ZoomCommandHandler(channel: channel)
                self.handler = handler
                return channel.pipeline.addHandler(handler)
            }
        
        unlink(socketPath)
        
        do {
            self.channel = try bootstrap.bind(unixDomainSocketPath: socketPath).wait()
            print("UDS Server started and listening on \(socketPath)")
        } catch {
            print("Failed to start UDS Server: \(error)")
        }
    }
    
    // TODO:  Better data type for params
    func sendStatusUpdate(audioStatus: ZoomAudioStatus, videoStatus: ZoomVideoStatus) {
        let statusMessage = ZoomStatusMessage(
            type: "status",
            audioStatus: String(describing: audioStatus),
            videoStatus: String(describing: videoStatus))
        
        handler?.sendStatus(statusMessage: statusMessage)
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
