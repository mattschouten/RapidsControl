import { Logger, streamDeck } from "@elgato/streamDeck";
import { RapidsSocketClient } from "./rapids-socket-client";
import { updateKeyIconsForStatus } from "./key-icon-controller";

/**
 * Shape of a message to RapidsControl
 */
interface RapidsControlMessage {
    type: string;
    command: string;
};

const logger: Logger = streamDeck.logger.createScope("RCI");
const socketClient: RapidsSocketClient = new RapidsSocketClient();

addSocketClientListeners();

function addSocketClientListeners() {
    socketClient.on("connected", () => {
        streamDeck.logger.info("Connection opened to RapidsControl");

        sendStatusRequest();
    });

    socketClient.on("disconnected", () => {
        streamDeck.logger.info("Disconnected from RapidsControl");
    });

    socketClient.on("message", onMessage);
}

/**
 * Called to initiate the connection when ready
 */
export function connectToRapidsControl() {
    logger.info("Connecting to RapidsControl");
    socketClient.start();
}

function onMessage(unparsedMessage: string) {
    try {
        const parsed = JSON.parse(unparsedMessage);
        logger.info("Received from RapidsControl:  ", parsed);
        if ((parsed.type ?? '') === 'status') {
            const audioStatus = parsed.audioStatus ?? 'unknown';
            const videoStatus = parsed.videoStatus ?? 'unknown';

            updateKeyIconsForStatus(audioStatus, videoStatus);
        }
    } catch (err) {
        logger.error("Invalid JSON from RapidsControl", err, unparsedMessage);
    }
}

function sendMessage(message: RapidsControlMessage, messageDescription: string) {
    if (!socketClient.isConnected) {
        streamDeck.logger.info("---- Should connect here ---");
        socketClient.start();
    }

    logger.info(`Sending ${messageDescription} to RapidsControl app`);

    const messageString = JSON.stringify(message) + '\n';
    logger.debug(messageString);
    socketClient.send(messageString);
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
