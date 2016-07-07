//
//  FileWatcher.swift
//  Screen
//
//  Created by Jesus Rodriguez on 6/16/16.
//  Copyright © 2016 net.omnipixel. All rights reserved.
//

import Foundation
import Cocoa

public class FileSystemWatcher {
    
    private var _path: String = ""
    private var started = false
    private var streamRef: FSEventStreamRef
    
    init(path: String) {
        self._path = path
        self.streamRef = nil
    }
    
    private let _callback: FSEventStreamCallback = {
        (stream: ConstFSEventStreamRef, contextInfo: UnsafeMutablePointer<Void>, numEvents: Int, eventPaths: UnsafeMutablePointer<Void>, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIds: UnsafePointer<FSEventStreamEventId>) in
        
        let fileSystemWatcher: FileSystemWatcher = unsafeBitCast(contextInfo, FileSystemWatcher.self)
        let paths = unsafeBitCast(eventPaths, NSArray.self) as! [String]
        
        // handle file event
        
        for index in 0..<numEvents {
            fileSystemWatcher.handleEvent(paths[index])
        }
    }
    
    public func start() {
        
        let allocator: CFAllocator? = kCFAllocatorDefault
        
        
        var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer<Void>(unsafeAddressOf(self))
        let pathsToWatch: CFArray = [self._path]
        let sinceWhen: FSEventStreamEventId = UInt64(kFSEventStreamEventIdSinceNow)
        let latency: CFTimeInterval = 0.0
        let flags: FSEventStreamCreateFlags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        streamRef = FSEventStreamCreate(
            allocator,
            _callback,
            &context,
            pathsToWatch,
            sinceWhen,
            latency,
            flags
        )
        
        FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
        FSEventStreamStart(streamRef)
    }
    
    public func stop() {
        
        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)
        streamRef = nil

    }
    
    private func handleEvent(path: String) {
        do {
            guard let attributes: NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(path) else {
                return // Unable to get file attributes
            }
            
            guard let extendedAttributes = attributes!["NSFileExtendedAttributes"] as? [String: AnyObject] else {
                return // Unable to get extended attributes
            }
            
            if !extendedAttributes.keys.contains("com.apple.metadata:kMDItemIsScreenCapture") {
                return // File is not a screenshot
            }
            
            print(extendedAttributes)
            addToPb(path)
            
        } catch _ {
            print("Error getting attributes")
        }
    }
    
    private func addToPb(path: String) {
        // Clear clip board
        NSPasteboard.generalPasteboard().clearContents()
        
        //create image
        let image = NSImage.init(byReferencingFile: path)
        
        NSPasteboard.generalPasteboard().writeObjects([image!])
        
    }
    
}