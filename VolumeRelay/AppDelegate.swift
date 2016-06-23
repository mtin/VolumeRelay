//
//  AppDelegate.swift
//  VolumeRelay
//
//  Created by Martin Fritzsche on 23/06/16.
//  Copyright © 2016 Martin Fritzsche. All rights reserved.
//

import Cocoa
import CoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    var volumeTap: SPMediaKeyTap!
    
    var volume_up : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_%2B&amount=10"
    var volume_down : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_-&amount=10"
    
    var airplayDeviceName: String = "Pioneer N-50"

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // status bar image
        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarButtonImageDisabled")
        }
        
        // status bar menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit VolumeRelay", action: Selector("terminate:"), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        
        // volume key listener
        volumeTap = SPMediaKeyTap(delegate: self)
        setupVolumeKeyTap()
        
        // audio device listener http://stackoverflow.com/questions/26070058/how-to-get-notification-if-system-preferences-default-sound-changed
        // tell HAL to manage its own thread for notifications 
        var runLoopAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyRunLoop),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        var runLoop: CFRunLoopRef? = nil
        let size = UInt32(sizeofValue(runLoop))
        if (kAudioHardwareNoError != AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &runLoopAddress,
            0,
            nil,
            size,
            &runLoop)) {
                print("error while setting up audio device listener")
        }
        
        var outputDeviceAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        if (kAudioHardwareNoError != AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &outputDeviceAddress,
            nil,
            audioObjectPropertyListenerBlock)) {
                print("error while adding audio device listener")
        }

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        volumeTap.stopWatchingMediaKeys()
    }
    
    // Audio device change listener helper functions
    
    func getDefaultAudioOutputDevice () -> AudioObjectID {
        var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var deviceID: AudioObjectID = 0
        var dataSize = UInt32(truncatingBitPattern: sizeof(AudioDeviceID))
        let systemObjectID = AudioObjectID(bitPattern: kAudioObjectSystemObject)
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(systemObjectID, &devicePropertyAddress, 0, nil, &dataSize, &deviceID)) { return 0 }
        return deviceID
    }
    
    func getDefaultAudioOutputDeviceName () -> String {
        var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var dataSize: UInt32 = UInt32(sizeof(CFStringRef))
        var deviceName: CFStringRef = ""
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(getDefaultAudioOutputDevice(), &devicePropertyAddress, 0, nil, &dataSize, &deviceName)) { return "error" }
        return String(deviceName)
    }
    
    func audioObjectPropertyListenerBlock (numberAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>) {
        var index: UInt32 = 0
        while index < numberAddresses {
            let address: AudioObjectPropertyAddress = addresses[Int(index)]
            switch address.mSelector {
            case kAudioHardwarePropertyDefaultOutputDevice:
                setupVolumeKeyTap()
            default:
                print("We didn't expect this!")
                
            }
            index += 1
        }
    }

    // Volume Key Tap callback
    
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
    
    // GET request
    
    func sendGetRequest(url: String) {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: url)!
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            //print(NSString(data: data!, encoding:NSUTF8StringEncoding))
        }
        task.resume()
    }
    
    func setupVolumeKeyTap() {
        if (getDefaultAudioOutputDeviceName().rangeOfString(airplayDeviceName) != nil) {
            volumeTap.startWatchingMediaKeys()
            if let button = statusBarItem.button {
                button.image = NSImage(named: "StatusBarButtonImageEnabled")
            }
        } else {
            volumeTap.stopWatchingMediaKeys()
            if let button = statusBarItem.button {
                button.image = NSImage(named: "StatusBarButtonImageDisabled")
            }
        }

    }
}

