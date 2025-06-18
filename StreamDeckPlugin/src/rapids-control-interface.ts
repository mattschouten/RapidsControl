import { streamDeck, EventEmitter } from "@elgato/streamDeck";
import * as net from 'net';
import { updateKeyIconsForStatus } from "./key-icon-controller";

/**
 * Shape of a message to RapidsControl
 */
interface RapidsControlMessage {
    type: string;
    command: string;
};

export class RapidsSocketClient extends EventEmitter<string> {
    udsClient: net.Socket | null = null;
    isConnected: boolean;
    reconnectInterval: NodeJS.Timeout | null;
    allowedToReconnect: boolean = true;

    constructor() {
        super();
        this.udsClient = null;
        this.isConnected = false;
        this.reconnectInterval = null;
        this.allowedToReconnect = true;
    }

    start() {
        streamDeck.logger.trace("_start()");
        this._scheduleReconnect();
        this._connect();
    }

    _connect() {
        streamDeck.logger.trace("Attempting to _connect()", this.udsClient);
        if (this.udsClient) return;

        streamDeck.logger.trace("...and going");
        this.udsClient = net.createConnection('/tmp/rapidscontrol.sock');

        this.udsClient.on('connect', () => {
            this.isConnected = true;
            this.emit("connected");
            streamDeck.logger.info("Connected via UDS");

            this._clearReconnectInterval();


            if (!this.udsClient) {
                this.emit("error", "Null client after connection");
                return;
            }

            this.udsClient.on('data', (data: Buffer) => {
                const messages = data.toString().split('\n').filter(line => line.trim() != '');

                // TODO:  Pass message handling up to a higher level; this should only be concerned with
                //        receiving the message.
                for (const message of messages) {
                    try {
                        const parsed = JSON.parse(message);
                        streamDeck.logger.info("Received from RapidsControl:  ", parsed);
                        if ((parsed.type ?? '') === 'status') {
                            const audioStatus = parsed.audioStatus ?? 'unknown';
                            const videoStatus = parsed.videoStatus ?? 'unknown';

                            updateKeyIconsForStatus(audioStatus, videoStatus);
                        }
                    } catch (err) {
                        streamDeck.logger.error("Invalid JSON from RapidsControl", err, data);
                    }
                }
            });

            this.udsClient.on('error', (err) => {
                streamDeck.logger.error('UDS Connection Error: ', err);
                this._handleDisconnect();
            });

            this.udsClient.on('close', () => {
                streamDeck.logger.info('UDS connection closed');
                this._handleDisconnect();
            });
        });
    }

    _handleDisconnect() {
        streamDeck.logger.debug("_handleDisconnect")
        this.udsClient?.destroy();
        this.udsClient = null;

        if (this.isConnected) {
            this.isConnected = false;
            this.emit("disconnected");
        }

        this._scheduleReconnect();
    }

    _clearReconnectInterval() {
        streamDeck.logger.trace("_clearReconnectInterval");
        if (this.reconnectInterval) {
            clearInterval(this.reconnectInterval);
            this.reconnectInterval = null;
        }
    }

    _scheduleReconnect() {
        streamDeck.logger.info("_scheduleReconnect");

        // If we are allowed to reconnect, and we're not connected, and the interval does not already exist
        if (this.allowedToReconnect && !this.isConnected && !this.reconnectInterval) {
            this.reconnectInterval = setInterval(() => {
                streamDeck.logger.debug("Attempting to connect to RapidsControl");
                this._connect()
            }, 10000);
        }
    }

    stop() {
        this.allowedToReconnect = false;
        this._clearReconnectInterval();
        if (this.udsClient) {
            this.udsClient.end();
            this.udsClient = null;
        }

        this.isConnected = false;
    }

    send(message: String) {
        try {
            if (this.isConnected && this.udsClient) {
                // this.udsClient.write(JSON.stringify(message) + '\n');
                this.udsClient.write(message + '\n');
                streamDeck.logger.info(`Sent ${message.length} character message`)
            } else {
                streamDeck.logger.warn("Attempted to send when not connected");
                this._connect();
            }
        } catch (err) {
            streamDeck.logger.error(`Failed to send message:`, err);
        }
    }
}

const socketClient = new RapidsSocketClient();

socketClient.on("connected", () => {
    streamDeck.logger.info("Connection opened to RapidsControl");

    sendStatusRequest();
});

socketClient.on("disconnected", () => {
    streamDeck.logger.info("Disconnected from RapidsControl");
});

function sendMessage(message: RapidsControlMessage, messageDescription: string) {
    if (!socketClient.isConnected) {
        streamDeck.logger.info("---- Should connect here ---");
        socketClient.start();
    }

    streamDeck.logger.info(`Sending ${messageDescription} to RapidsControl app`);

    const messageString = JSON.stringify(message) + '\n';
    socketClient.send(messageString);
}

export function quickStartupFunction() {
    streamDeck.logger.info("Starting connection ... ");
    socketClient.start();
}

export function sendMute() {
    const muteCommand: RapidsControlMessage = {
        type: 'command',
        command: 'mute'
    };

    sendMessage(muteCommand, 'mute command');
}

export function sendUnmute() {
    const unmuteCommand: RapidsControlMessage = {
        type: 'command',
        command: 'unmute'
    };

    sendMessage(unmuteCommand, 'unmute command');
}

export function sendVideoOff() {
    const videoOffCommand: RapidsControlMessage = {
        type: 'command',
        command: 'videoOff'
    };

    sendMessage(videoOffCommand, 'video off command');
}

export function sendVideoOn() {
    const videoOnCommand: RapidsControlMessage = {
        type: 'command',
        command: 'videoOn'
    };

    sendMessage(videoOnCommand, 'video on command');
}

export function sendEndForAll() {
    const endForAllCommand: RapidsControlMessage = {
        type: 'command',
        command: 'endForAll'
    };

    sendMessage(endForAllCommand, 'end for all command');
}

export function sendStatusRequest() {
    const getStatusCommand: RapidsControlMessage = {
        type: 'getStatus',
        command: ''
    };

    sendMessage(getStatusCommand, 'status request');
}
