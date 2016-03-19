#virtual-tourist
iOS app where you can explore the world with an interactive map and view photos related to a specific location.

## Features
- Add and move pins on interactive map of favorite locations.
- Load images related to location from Flickr.

## Setup
NOTE: You'll need your own Flickr API Key.

Import project into Xcode.
Duplicate the "Keys.sample.plist" file.
Rename the duplicate file as "Keys.plist" and edit it within Xcode.
Replace value "INSERT_FLICKR_API_KEY_HERE" with your own Flickr API Key.

## Current Status of App
Currently in a beta stage. There are quite a few issues that need to be rectified.

## Known Issues
- When loading a pin, the Photo Album View Controller displays every image that's ever been loaded.
- After placing a pin, have to tap and load a pin once in order to drag it.
- Pins don't load upon opening app.
