import streamDeck, { LogLevel } from "@elgato/streamDeck";
import { EndMeetingForAll, MuteZoom, StartZoomVideo, StopZoomVideo, UnmuteZoom } from "./actions/zoom-actions";
import { quickStartupFunction } from "./rapids-control-interface";

streamDeck.logger.setLevel(LogLevel.TRACE);

// Register the actions
streamDeck.actions.registerAction(new MuteZoom());
streamDeck.actions.registerAction(new UnmuteZoom());
streamDeck.actions.registerAction(new StopZoomVideo());
streamDeck.actions.registerAction(new StartZoomVideo());
streamDeck.actions.registerAction(new EndMeetingForAll());

// Connect to the Stream Deck.
streamDeck.connect();

// Start a connection checker
setTimeout(() => {
    quickStartupFunction();
}, 100);
