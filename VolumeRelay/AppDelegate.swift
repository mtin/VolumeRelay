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

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // status bar image
        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
        }
        
        // status bar menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit VolumeRelay", action: Selector("terminate:"), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

