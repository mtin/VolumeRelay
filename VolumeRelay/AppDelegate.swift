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
    
    var volume_up : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_%2B&amount=10"
    var volume_down : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_-&amount=10"

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
                sendGetRequest(volume_up)
                return
            case Int(NX_KEYTYPE_SOUND_DOWN):
                sendGetRequest(volume_down)
                return
            case Int(NX_KEYTYPE_MUTE):
                //print("mute")
                return
            default:
                return
            }
        }
    }
    
    func sendGetRequest(url: String) {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: url)!
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            print(NSString(data: data!, encoding:NSUTF8StringEncoding))
        }
        task.resume()
    }
}

