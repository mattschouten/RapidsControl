import { Logger, streamDeck } from "@elgato/streamDeck";
import { RapidsSocketClient } from "./rapids-socket-client";

/**
 * Shape of a message to RapidsControl
 */
interface RapidsControlMessage {
    type: string;
    command: string;
};

export class RapidsControlInterface {
    socketClient: RapidsSocketClient = new RapidsSocketClient();
    logger: Logger = streamDeck.logger.createScope("RCI");
    self: this;

    constructor() {
        this._addSocketClientListeners();
    }

    connectToRapidsControl() {
        this.logger.info("Connecting to RapidsControl");
        this.socketClient.start();
    }

    _addSocketClientListeners() {
        this.socketClient.on("connected", () => {
            streamDeck.logger.info("Connection opened to RapidsControl");

            this.sendStatusRequest();
        });

        this.socketClient.on("disconnected", () => {
            streamDeck.logger.info("Disconnected from RapidsControl");
        });
    }

    _sendMessage(message: RapidsControlMessage, messageDescription: string) {
        if (!this.socketClient.isConnected) {
            streamDeck.logger.info("---- Should connect here ---");
            this.socketClient.start();
        }

        streamDeck.logger.info(`Sending ${messageDescription} to RapidsControl app`);

        const messageString = JSON.stringify(message) + '\n';
        this.socketClient.send(messageString);
    }

    sendMute() {
        const muteCommand: RapidsControlMessage = {
            type: 'command',
            command: 'mute'
        };

        streamDeck.logger.info("THIS", this);
        self._sendMessage(muteCommand, 'mute command');
    }

    sendUnmute() {
        const unmuteCommand: RapidsControlMessage = {
            type: 'command',
            command: 'unmute'
        };

        this._sendMessage(unmuteCommand, 'unmute command');
    }

    sendVideoOff() {
        const videoOffCommand: RapidsControlMessage = {
            type: 'command',
            command: 'videoOff'
        };

        this._sendMessage(videoOffCommand, 'video off command');
    }

    sendVideoOn() {
        const videoOnCommand: RapidsControlMessage = {
            type: 'command',
            command: 'videoOn'
        };

        this._sendMessage(videoOnCommand, 'video on command');
    }

    sendEndForAll() {
        const endForAllCommand: RapidsControlMessage = {
            type: 'command',
            command: 'endForAll'
        };

        this._sendMessage(endForAllCommand, 'end for all command');
    }

    sendStatusRequest() {
        const getStatusCommand: RapidsControlMessage = {
            type: 'getStatus',
            command: ''
        };

        this._sendMessage(getStatusCommand, 'status request');
    }
}
