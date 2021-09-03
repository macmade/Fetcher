/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2021 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa
import GitKit

public class RepositoryItem: NSObject
{
    public var repository: Repository
    
    @objc public dynamic let name: String
    @objc public dynamic let path: String
    @objc public dynamic let icon: NSImage?
    
    public var hasXcodeProject: Bool
    {
        RepositoryItem.xcodeProject( for: self.repository.url ) != nil
    }
    
    public var hasVSCode: Bool
    {
        FileManager.default.fileExists( atPath: self.repository.url.appendingPathComponent( ".vscode" ).path )
    }
    
    public convenience init?( path: String )
    {
        self.init( url: URL( fileURLWithPath: path ) )
    }
    
    public init?( url: URL )
    {
        do
        {
            self.repository    = try Repository( url: url )
            self.path          = url.deletingLastPathComponent().path
            self.name          = url.lastPathComponent
            self.icon          = RepositoryItem.icon( for: url )
        }
        catch let error as GitKit.Error
        {
            #if DEBUG
            print( error.message )
            #endif
            
            return nil
        }
        catch let error
        {
            #if DEBUG
            print( error.localizedDescription )
            #endif
            
            return nil
        }
    }
    
    public func open()
    {
        if Preferences.shared.smartOpen
        {
            if let xcode = RepositoryItem.xcodeProject( for: self.repository.url )
            {
                NSWorkspace.shared.open( xcode )
                
                return
            }
            
            if self.hasVSCode
            {
                let config               = NSWorkspace.OpenConfiguration()
                config.activates         = true
                config.addsToRecentItems = true
                config.hides             = false
                config.hidesOthers       = false
                
                if let vsCode = Application.applicationWithBundleID( "com.microsoft.VSCode" )
                {
                    NSWorkspace.shared.open( [ self.repository.url ] , withApplicationAt: vsCode.url, configuration: config, completionHandler: nil )
                }
                
                return
            }
        }
        
        NSWorkspace.shared.open( self.repository.url )
    }
    
    private class func xcodeProject( for url: URL ) -> URL?
    {
        guard let enumerator = FileManager.default.enumerator( atPath: url.path ) else
        {
            return nil
        }
        
        for sub in enumerator
        {
            enumerator.skipDescendents()
            
            guard let name = sub as? String else
            {
                continue
            }
            
            let url = url.appendingPathComponent( name )
            
            if ( url.lastPathComponent as NSString ).pathExtension == "xcodeproj"
            {
                return url
            }
        }
        
        return nil
    }
    
    private class func icon( for url: URL ) -> NSImage?
    {
        if let _ = RepositoryItem.xcodeProject( for: url )
        {
            return NSImage( named: "Xcode" )
        }
        
        if FileManager.default.fileExists( atPath: url.appendingPathComponent( ".vscode" ).path )
        {
            return NSImage( named: "VSCode" )
        }
        
        return NSImage( named: "Public" )
    }
}
