import { streamDeck, EventEmitter, Logger } from "@elgato/streamDeck";
import * as net from 'net';
import { updateKeyIconsForStatus } from "./key-icon-controller";

export class RapidsSocketClient extends EventEmitter<string> {
    udsClient: net.Socket | null = null;
    isConnected: boolean;
    reconnectInterval: NodeJS.Timeout | null;
    allowedToReconnect: boolean = true;
    logger: Logger = streamDeck.logger.createScope("RapidsSocketClient");

    constructor() {
        super();
        this.udsClient = null;
        this.isConnected = false;
        this.reconnectInterval = null;
        this.allowedToReconnect = true;
    }

    start() {
        this.logger.trace("_start()");
        this._scheduleReconnect();
        this._connect();
    }

    _connect() {
        this.logger.trace("Attempting to _connect()", this.udsClient);
        if (this.udsClient) return;

        this.logger.trace("...and going");
        this.udsClient = net.createConnection('/tmp/rapidscontrol.sock');

        this.udsClient.on('connectionAttemptFailed', (err) => {
            this.logger.trace('Connection attempt failed.  This is expected if RapidsControl is not running.', err);
            this.udsClient?.destroy();
            this.udsClient = null;
        });

        this.udsClient.on('connect', () => {
            this.isConnected = true;
            this.emit("connected");
            this.logger.info("Connected via UDS");

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
                this.logger.error('UDS Connection Error: ', err);
                this._handleDisconnect();
            });

            this.udsClient.on('close', () => {
                this.logger.info('UDS connection closed');
                this._handleDisconnect();
            });
        });
    }

    _handleDisconnect() {
        this.logger.debug("_handleDisconnect")
        this.udsClient?.destroy();
        this.udsClient = null;

        if (this.isConnected) {
            this.isConnected = false;
            this.emit("disconnected");
        }

        this._scheduleReconnect();
    }

    _clearReconnectInterval() {
        this.logger.trace("_clearReconnectInterval");
        if (this.reconnectInterval) {
            clearInterval(this.reconnectInterval);
            this.reconnectInterval = null;
        }
    }

    _scheduleReconnect() {
        this.logger.info("_scheduleReconnect");

        // If we are allowed to reconnect, and we're not connected, and the interval does not already exist
        if (this.allowedToReconnect && !this.isConnected && !this.reconnectInterval) {
            this.reconnectInterval = setInterval(() => {
                this.logger.debug("Attempting to connect to RapidsControl");
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

    send(messageJson: String) {
        try {
            if (this.isConnected && this.udsClient) {
                this.udsClient.write(messageJson + '\n');
                this.logger.info(`Sent ${messageJson.length} character message`)
            } else {
                this.logger.warn("Attempted to send when not connected");
                this._connect();
            }
        } catch (err) {
            this.logger.error(`Failed to send message:`, err);
        }
    }
}

