import streamDeck, { LogLevel } from "@elgato/streamDeck";
import { EndMeetingForAll, MuteZoom, StartZoomVideo, StopZoomVideo, UnmuteZoom } from "./actions/zoom-actions";

streamDeck.logger.setLevel(LogLevel.TRACE);

// Register the actions
streamDeck.actions.registerAction(new MuteZoom());
streamDeck.actions.registerAction(new UnmuteZoom());
streamDeck.actions.registerAction(new StopZoomVideo());
streamDeck.actions.registerAction(new StartZoomVideo());
streamDeck.actions.registerAction(new EndMeetingForAll());

// Finally, connect to the Stream Deck.
streamDeck.connect();

// TODO:  Start a connection checker
