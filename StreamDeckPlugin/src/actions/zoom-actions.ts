import { action, KeyDownEvent, SingletonAction, WillAppearEvent } from "@elgato/streamDeck";
import { RapidsControlInterface } from "../rapids-control-interface";

/**
 * Base class for our actions to derive from on button presses.
 */
class ZoomAction extends SingletonAction<RapidsControlSettings> {
	title: string;
	keyDownFunction: () => void;

	constructor(rci: RapidsControlInterface) {
		super();
		this.title = "NOT SET";
		this.keyDownFunction = () => 1;
	}

	/**
	 * Performs actions needed when the key becomes visible.  Could be at StreamDeck startup, or navigation between pages.
	 *
	 * @param ev Event with settings
	 * @returns
	 */
	override onWillAppear(ev: WillAppearEvent<RapidsControlSettings>): void | Promise<void> {
		const { settings } = ev.payload;

		console.log("Connecting!", this.constructor.name);
		// quickStartupFunction();

		return ev.action.setTitle(this.title);
	}

	/**
	 * Fires when the user hits the button.  The event {@link ev} contains information about the event and settings.
	 */
	override async onKeyDown(ev: KeyDownEvent<RapidsControlSettings>): Promise<void> {
		// Send the mute command
		this.keyDownFunction();
		// And that's all
		// TODO:  Can I flash a key?
	}
}

@action({ UUID: "com.cybadger.rapids-control-plugin.mute" })
export class MuteZoom extends ZoomAction {

	constructor(rci: RapidsControlInterface) {
		super(rci);
		this.title = 'Mute';
		this.keyDownFunction = rci.sendMute;
	}
}

@action({ UUID: "com.cybadger.rapids-control-plugin.unmute" })
export class UnmuteZoom extends ZoomAction {

	constructor(rci: RapidsControlInterface) {
		super(rci);
		this.title = 'Unmute';
		this.keyDownFunction = rci.sendUnmute;
	}
}

@action({ UUID: "com.cybadger.rapids-control-plugin.stop-video" })
export class StopZoomVideo extends ZoomAction {

	constructor(rci: RapidsControlInterface) {
		super(rci);
		this.title = 'Stop Video';
		this.keyDownFunction = rci.sendVideoOff;
	}
}

@action({ UUID: "com.cybadger.rapids-control-plugin.start-video" })
export class StartZoomVideo extends ZoomAction {

	constructor(rci: RapidsControlInterface) {
		super(rci);
		this.title = 'Start\nVideo';
		this.keyDownFunction = rci.sendVideoOn;
	}
}

@action({ UUID: "com.cybadger.rapids-control-plugin.end-for-all" })
export class EndMeetingForAll extends ZoomAction {

	constructor(rci: RapidsControlInterface) {
		super(rci);
		this.title = 'End For All';
		this.keyDownFunction = rci.sendEndForAll;
	}
}

/**
 * Settings for all actions, as far as I know.
 */
type RapidsControlSettings = {
	port?: number;
};
