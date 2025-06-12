import { streamDeck } from "@elgato/streamDeck";

// TODO:  make a type or enum, not just strings
export function updateKeyIconsForStatus(audioStatus: string, videoStatus: string) {
    streamDeck.actions.forEach((action) => {
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
    });

}

