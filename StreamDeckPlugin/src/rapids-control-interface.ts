import { streamDeck } from "@elgato/streamDeck";
import * as net from 'net';
import { updateKeyIconsForStatus } from "./key-icon-controller";

let udsClient: net.Socket | null = null;

/**
 * Shape of a message to RapidsControl
 */
interface RapidsControlMessage {
    type: string;
    command: string;
};

export function connectToRapidsControlApp() {
    if (udsClient) return;

    udsClient = net.createConnection('/tmp/rapidscontrol.sock');

    udsClient.on('connect', () => {
        streamDeck.logger.info("Connected via UDS");

        // Request initial status
        udsClient?.write(JSON.stringify({type: 'getStatus'}) + '\n');
    });

    udsClient.on('data', (data: Buffer) => {
        const messages = data.toString().split('\n').filter(line => line.trim() != '');

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

    udsClient.on('error', (err) => {
        streamDeck.logger.error('UDS Connection Error: ', err);
        udsClient?.destroy();
        udsClient = null;
    });

    udsClient.on('close', () => {
        streamDeck.logger.info('UDS connection closed');
        udsClient = null;
    })
}

function connectIfNotConnected(commandVerb: string): boolean {
    if (!udsClient || udsClient.destroyed) {
        streamDeck.logger.warn('Not connected to RapidsControl app.  Attempting to reconnect...')
        connectToRapidsControlApp();

        if (!udsClient || udsClient.destroyed) {
            streamDeck.logger.warn(`Not connected after attempt to reconnect.  Not able to send ${commandVerb}.`);
            return false;
        }
    }

    return true;
}

function sendMessage(message: RapidsControlMessage, messageDescription: string) {
    if (connectIfNotConnected(message.command)) {
        try {
            udsClient?.write(JSON.stringify(message) + '\n');
            streamDeck.logger.info(`Sent ${messageDescription} to RapidsControl app`);
        } catch (err) {
            streamDeck.logger.error(`Failed to send ${messageDescription}:`, err);
        }
    }
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
