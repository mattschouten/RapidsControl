import streamDeck, { LogLevel } from "@elgato/streamDeck";
import { EndMeetingForAll, MuteZoom, StartZoomVideo, StopZoomVideo, UnmuteZoom } from "./actions/zoom-actions";
import { RapidsControlInterface } from "./rapids-control-interface";

streamDeck.logger.setLevel(LogLevel.TRACE);

// Create the interface to RapidsControl
const rci = new RapidsControlInterface();

// Register the actions
streamDeck.actions.registerAction(new MuteZoom(rci));
streamDeck.actions.registerAction(new UnmuteZoom(rci));
streamDeck.actions.registerAction(new StopZoomVideo(rci));
streamDeck.actions.registerAction(new StartZoomVideo(rci));
streamDeck.actions.registerAction(new EndMeetingForAll(rci));

// Begin attempting to connect to RapidsControl
rci.connectToRapidsControl();

// Connect to the Stream Deck.
streamDeck.connect();
