//
//  AppDelegate.swift
//  Screen
//
//  Created by Jesus Rodriguez on 6/16/16.
//  Copyright © 2016 net.omnipixel. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let defaults = NSUserDefaults.standardUserDefaults()
    let fileManager = NSFileManager.defaultManager()
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var configuration: NSWindow!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        guard let path = screenshotDirectoryURL?.path else {
            print("Unable to get screenshot directory")
            return
        }
        
        guard let icon = NSImage(named: "statusIcon") else {
            print("Could not set image.")
            return
        }
        
        // Set image as template
        icon.template = true
        
        statusItem.menu = self.menu
        statusItem.button!.image = icon
        
        let fs = FileSystemWatcher(path: path)
        fs.start()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    var screenshotDirectoryURL: NSURL? {
        // Check for custom screenshot location chosen by user
        if let path = defaults.persistentDomainForName("com.apple.screencapture")?["location"] as? NSString {
            let standardizedPath = path.stringByStandardizingPath
            
            // Check that the chosen directory exists, otherwise screencapture will not use it
            var isDir = ObjCBool(false)
            if fileManager.fileExistsAtPath(standardizedPath, isDirectory: &isDir) && isDir {
                return NSURL(fileURLWithPath: standardizedPath)
            }
        }
        
        // If a custom location is not defined (or invalid) return the default screenshot location (~/Desktop)
        return fileManager.URLsForDirectory(.DesktopDirectory, inDomains: .UserDomainMask).first
    }

    @IBAction func openPreferencesWindow(sender: AnyObject) {
        
        guard let screen = NSScreen.mainScreen() else {
            return
        }
        
        guard let configurationWindow = self.configuration else {
            return
        }
        
        let windowWidth = configurationWindow.frame.width / 2
        let windowHeight = configurationWindow.frame.height / 2
        
        let screenCenterY = (screen.frame.height / 2) + windowHeight
        let screenCenterX = (screen.frame.width / 2) - windowWidth
        let screenCenterPoint = CGPoint(x: screenCenterX, y: screenCenterY)
        
        self.configuration.setFrameTopLeftPoint(screenCenterPoint)
        
        self.configuration.makeKeyAndOrderFront(self)
        
    }
}

