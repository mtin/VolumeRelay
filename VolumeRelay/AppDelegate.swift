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

    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var volumeTap: SPMediaKeyTap!
    
    var volume_up : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_%2B&amount=5"
    var volume_down : String = "http://192.168.178.20/elropi.py?remote=yamaha&command=VOLUME_-&amount=5"
    
    var airplayDeviceNames: [String] = ["Pioneer USB Audio Device", "Pioneer N-50"]
    
    var increaseNotification: NSUserNotification = NSUserNotification()
    var decreaseNotification: NSUserNotification = NSUserNotification()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // status bar image
        if let button = statusBarItem.button {
            button.image = NSImage(named: NSImage.Name("StatusBarButtonImageDisabled"))
        }
        
        // status bar menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit VolumeRelay", action: Selector("terminate:"), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        
        // set up notifications
        increaseNotification.title = "Increasing Volume"
        increaseNotification.informativeText = "Turning up the volume for audio device"
        increaseNotification.soundName = nil
        increaseNotification.contentImage = NSImage(named: NSImage.Name("VolumeUpImage"))
        
        decreaseNotification.title = "Decreasing Volume"
        decreaseNotification.informativeText = "Turning down the volume for audio device"
        decreaseNotification.soundName = nil
        decreaseNotification.contentImage = NSImage(named: NSImage.Name("VolumeDownImage"))
        
        // volume key listener
        volumeTap = SPMediaKeyTap(delegate: self)
        setupVolumeKeyTap()
        
        // audio device listener http://stackoverflow.com/questions/26070058/how-to-get-notification-if-system-preferences-default-sound-changed
        
        // tell HAL to manage its own thread for notifications 
        var runLoopAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyRunLoop),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        var runLoop: CFRunLoop? = nil
        let size = UInt32(MemoryLayout.size(ofValue: runLoop))
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

    func applicationWillTerminate(_ aNotification: Notification) {
        volumeTap.stopWatchingMediaKeys()
    }
    
    // Audio device change listener helper functions
    
    func getDefaultAudioOutputDevice () -> AudioObjectID {
        var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var deviceID: AudioObjectID = 0
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        let systemObjectID = AudioObjectID(bitPattern: kAudioObjectSystemObject)
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(systemObjectID, &devicePropertyAddress, 0, nil, &dataSize, &deviceID)) { return 0 }
        return deviceID
    }
    
    func getAudioOutputDeviceName(audioDevice: AudioObjectID) -> String {
        var devicePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var dataSize: UInt32 = UInt32(MemoryLayout<CFString>.size)
        var deviceName: CFString = "" as CFString
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(audioDevice, &devicePropertyAddress, 0, nil, &dataSize, &deviceName)) { return "error retrieving output device name" }
        return deviceName as String;
    }
        
    
    func getNameOfActiveDataSourceOfAudioDevice(audioDevice: AudioObjectID) -> String {
        // get the active data source id of default device
        var sourceAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDataSource, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        var dataSourceId: UInt32 = 0
        var dataSourceIdSize: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(getDefaultAudioOutputDevice(), &sourceAddress, 0, nil, &dataSourceIdSize, &dataSourceId)) { return "error retrieving active data source" }
        
        //return dataSourceId;
        
        // get the name of the active data source
        var nameAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDataSourceNameForIDCFString, mScope: kAudioObjectPropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        var value: CFString = "" as CFString
        
        var audioValueTranslation = AudioValueTranslation(
            mInputData: &dataSourceId,
            mInputDataSize: UInt32(MemoryLayout<AudioDeviceID>.size),
            mOutputData: &value,
            mOutputDataSize: UInt32(MemoryLayout<CFString>.size))
        
        var propsize: UInt32 = UInt32(MemoryLayout<AudioValueTranslation>.size)
        
        if (kAudioHardwareNoError != AudioObjectGetPropertyData(getDefaultAudioOutputDevice(), &nameAddr, 0, nil, &propsize, &audioValueTranslation)) { return "error retrieving name of active data source" }
        
        return value as String;
    }
    
    // Audio device change listener callback
    
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
    
    override func mediaKeyTap(_ keyTap: SPMediaKeyTap!, receivedMediaKeyEvent event: NSEvent!) {
        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyFlags = event.data1 & 0x0000FFFF
        let keyPressed = ((keyFlags & 0xFF00) >> 8) == 0xA
        //let keyRepeat = keyFlags & 0x1
        if keyPressed {
            switch keyCode {
            case Int(NX_KEYTYPE_SOUND_UP):
                NSUserNotificationCenter.default.deliver(increaseNotification)
                sendGetRequest(url: volume_up)
                return
            case Int(NX_KEYTYPE_SOUND_DOWN):
                NSUserNotificationCenter.default.deliver(decreaseNotification)
                sendGetRequest(url: volume_down)
                return
            case Int(NX_KEYTYPE_MUTE):
                //print("mute")
                return
            default:
                return
            }
        }
    }
    
    // Volume Key Tap setup
    
    func setupVolumeKeyTap() {
        print(getAudioOutputDeviceName(audioDevice: getDefaultAudioOutputDevice())) // + " (" + getNameOfActiveDataSourceOfAudioDevice(audioDevice: getDefaultAudioOutputDevice()) + ")")
        if let index = airplayDeviceNames.index(of: getAudioOutputDeviceName(audioDevice: getDefaultAudioOutputDevice())) {
            increaseNotification.informativeText = "Turning up the volume for " + airplayDeviceNames[index]
            decreaseNotification.informativeText = "Turning down the volume for " + airplayDeviceNames[index]
            volumeTap.startWatchingMediaKeys()
            if let button = statusBarItem.button {
                DispatchQueue.main.async {
                    button.image = NSImage(named: NSImage.Name("StatusBarButtonImageEnabled"))
                }
            }
        } else {
            volumeTap.stopWatchingMediaKeys()
            if let button = statusBarItem.button {
                DispatchQueue.main.async {
                    button.image = NSImage(named: NSImage.Name("StatusBarButtonImageDisabled"))
                }
            }
        }
        
    }
    
    // GET request
    
    func sendGetRequest(url: String) {
        let session = URLSession.shared
        let url = NSURL(string: url)!
        let task = session.dataTask(with: url as URL) { (data, response, error) in
            //print(NSString(data: data!, encoding:NSUTF8StringEncoding))
        }
        task.resume()
    }
}

