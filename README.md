# RapidsControl

Simple Zoom controls for Stream Deck.

There are commercial options like MuteDeck and ZoomOSC (a whole Zoom client custom-built to be controllable!) that do way, way more.

This started as some experiments with the Accessibility API on MacOS, and got far enough that it's usable.

## Using RapidsControl on your StreamDeck

1. Build the StreamDeck plugin
2. Build the RapidsControl Mac app
3. Run the RapidsControl app.  Grant Accessibility permissions.  (If you don't grant them, it'll be pretty useless.)
4. Find RapidsControl in your StreamDeck, and add the buttons.
5. Cross your fingers that the buttons work!

(Builds and perhaps an easily downloadable plugin to come.)

## StreamDeck Plugin - Starting and Development

The [Elgato documentation](https://docs.elgato.com/streamdeck/sdk/introduction/getting-started/) covers how to set up your StreamDeck development environment.

Once your environment is set up, you should be able to start the plugin as follows:

```bash
cd StreamDeckPlugin
npm run watch
```

If everything is set up correctly, RapidsControlPlugin should appear in the StreamDeck actions list.

If you get an error to the effect of StreamDeck being unable to find the plugin, try re-linking the plugin to the StreamDeck app.

```bash
streamdeck link com.cybadger....
```

## RapidsControl Mac App

You'll need XCode installed on your Mac.

Open `MacApp/RapidsControl.xcodeproj` in XCode.

Build and run the project.

## Notes

The plugin and the app communicate via a Unix Domain Socket at `/tmp/rapidscontrol.sock`.  The socket is opened by the app.
