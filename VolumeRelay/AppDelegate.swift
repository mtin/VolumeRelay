//
//  AppDelegate.swift
//  VolumeRelay
//
//  Created by Martin Fritzsche on 23/06/16.
//  Copyright © 2016 Martin Fritzsche. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    var volumeTap: SPMediaKeyTap!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // status bar image
        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
        }
        
        // status bar menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit VolumeRelay", action: Selector("terminate:"), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        
        // event listener
        volumeTap = SPMediaKeyTap(delegate: self)
        volumeTap.startWatchingMediaKeys()

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        volumeTap.stopWatchingMediaKeys()
    }

    override func mediaKeyTap(keyTap: SPMediaKeyTap!, receivedMediaKeyEvent event: NSEvent!) {
        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyFlags = event.data1 & 0x0000FFFF
        let keyPressed = ((keyFlags & 0xFF00) >> 8) == 0xA
        //let keyRepeat = keyFlags & 0x1
        if keyPressed {
            switch keyCode {
            case Int(NX_KEYTYPE_SOUND_UP):
                print("volume_up")
                return
            case Int(NX_KEYTYPE_SOUND_DOWN):
                print("volume_down")
                return
            case Int(NX_KEYTYPE_MUTE):
                print("mute")
                return
            default:
                return
            }
        }
    }
}

