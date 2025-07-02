import { streamDeck } from "@elgato/streamDeck";

// TODO:  make a type or enum, not just strings
export function updateKeyIconsForStatus(audioStatus: string, videoStatus: string, callIsActive: Boolean, isConnected: Boolean) {
    streamDeck.actions.forEach((action) => {
        if (!isConnected && action.manifestId.startsWith('com.cybadger.rapids-control-plugin')) {
            action.setImage('imgs/actions/zoom/inactive-square.svg');
            return;
        }

        if (action.manifestId === 'com.cybadger.rapids-control-plugin.mute' ||
            action.manifestId === 'com.cybadger.rapids-control-plugin.unmute') {
            switch (audioStatus) {
                case 'muted':
                    action.setImage('imgs/actions/zoom/red-square.svg');
                    break;
                case 'unmuted':
                    action.setImage('imgs/actions/zoom/green-square.svg');
                    break;
                case 'unknown':
                    action.setImage('imgs/actions/zoom/gray-square.svg');
                    break;
            }
        }

        if (action.manifestId === 'com.cybadger.rapids-control-plugin.stop-video' ||
            action.manifestId === 'com.cybadger.rapids-control-plugin.start-video') {
            switch (videoStatus) {
                case 'off':
                    action.setImage('imgs/actions/zoom/red-square.svg');
                    break;
                case 'on':
                    action.setImage('imgs/actions/zoom/green-square.svg');
                    break;
                case 'unknown':
                    action.setImage('imgs/actions/zoom/gray-square.svg');
                    break;
            }
        }

        if (action.manifestId === 'com.cybadger.rapids-control-plugin.end-for-all') {
            switch (callIsActive) {
                case true:
                    action.setImage('imgs/actions/zoom/green-square.svg');
                    // TODO:  A better icon would be nice.
                    break;
                case false:
                    action.setImage('imgs/actions/zoom/gray-square.svg');
                    break;
            }
        }
    });

}

