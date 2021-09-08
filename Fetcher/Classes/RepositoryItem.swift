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

public class RepositoryItem: NSObject, RepositoryDelegate
{
    private static let queue = DispatchQueue( label: "com.xs-labs.Fetcher.StatusQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil )
    
    public var repository: Repository
    
    @objc public private( set ) dynamic var name:           String
    @objc public private( set ) dynamic var path:           String
    @objc public private( set ) dynamic var icon:           NSImage?
    @objc public private( set ) dynamic var head:           String?
    @objc public private( set ) dynamic var headTextColor:  NSColor?
    @objc public private( set ) dynamic var tooltip:        String?
    @objc public private( set ) dynamic var lastCommitDate: Date?
    @objc public private( set ) dynamic var ahead           = 0
    @objc public private( set ) dynamic var behind          = 0
    @objc public private( set ) dynamic var isDirty         = false
    
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
            self.repository = try Repository( url: url )
            self.path       = url.deletingLastPathComponent().path
            self.name       = url.lastPathComponent
            self.icon       = RepositoryItem.icon( for: url )
            
            super.init()
            
            self.repository.delegate = self
            
            self.update()
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
    
    public func update()
    {
        self.head           = nil
        self.headTextColor  = nil
        self.tooltip        = nil
        self.lastCommitDate = nil
        self.ahead          = 0
        self.behind         = 0
        self.isDirty        = false
        
        if let head = self.repository.head
        {
            switch head
            {
                case .first( let branch ):
                    
                    self.head          = branch.name
                    self.headTextColor = NSColor.secondaryLabelColor
                    
                    if let commit = branch.lastCommit
                    {
                        self.tooltip        = RepositoryItem.tooltip( for: commit )
                        self.lastCommitDate = commit.date
                    }
                    
                    if let origin = repository.branches.first( where: { $0.name == "origin/\( branch.name )" } ),
                       let diff    = branch.graph( with: origin )
                    {
                        self.ahead  = diff.ahead
                        self.behind = diff.behind
                    }
                    
                case .second( let commit ):
                    
                    self.head           = String( commit.commitHash.prefix( 7 ) )
                    self.headTextColor  = NSColor.systemOrange
                    self.tooltip        = RepositoryItem.tooltip( for: commit )
                    self.lastCommitDate = commit.date
            }
        }
        
        RepositoryItem.queue.async
        {
            let dirty = self.repository.isDirty()
            
            DispatchQueue.main.async
            {
                self.isDirty = dirty
            }
        }
    }
    
    public override func isEqual( _ object: Any?) -> Bool
    {
        guard let item = object as? RepositoryItem else
        {
            return false
        }
        
        return self.repository == item.repository
    }
    
    public override func isEqual( to object: Any? ) -> Bool
    {
        self.isEqual( object )
    }
    
    public func reveal()
    {
        NSWorkspace.shared.open( self.repository.url )
    }
    
    @discardableResult
    public func openIn( bundleID: String ) -> Bool
    {
        guard let app = Application.applicationWithBundleID( bundleID ) else
        {
            return false
        }
        
        return self.openIn( app: app, url: self.repository.url )
    }
    
    @discardableResult
    public func openIn( bundleID: String, url: URL ) -> Bool
    {
        guard let app = Application.applicationWithBundleID( bundleID ) else
        {
            return false
        }
        
        return self.openIn( app: app, url: url )
    }
    
    @discardableResult
    public func openIn( app: Application ) -> Bool
    {
        self.openIn( app: app, url: self.repository.url )
    }
    
    @discardableResult
    public func openIn( app: Application, url: URL ) -> Bool
    {
        let config               = NSWorkspace.OpenConfiguration()
        config.activates         = true
        config.addsToRecentItems = true
        config.hides             = false
        config.hidesOthers       = false
        
        NSWorkspace.shared.open( [ url ] , withApplicationAt: app.url, configuration: config, completionHandler: nil )
        
        return true
    }
    
    @discardableResult
    public func openInTerminal() -> Bool
    {
        self.openIn( bundleID: "com.apple.Terminal" )
    }
    
    @discardableResult
    public func openInBBEdit() -> Bool
    {
        self.openIn( bundleID: "com.barebones.bbedit" )
    }
    
    @discardableResult
    public func openInVSCode() -> Bool
    {
        self.openIn( bundleID: "com.microsoft.VSCode" )
    }
    
    @discardableResult
    public func openInXcode() -> Bool
    {
        if let project = RepositoryItem.xcodeProject( for: self.repository.url )
        {
            return self.openIn( bundleID: "com.apple.dt.Xcode", url: project )
        }
        
        return false
    }
    
    public func open()
    {
        if Preferences.shared.smartOpen
        {
            if let project = RepositoryItem.xcodeProject( for: self.repository.url ),
               let xcode   = Application.applicationWithBundleID( "com.apple.dt.Xcode" )
            {
                self.openIn( app: xcode, url: project )
                
                return
            }
            
            if self.hasVSCode
            {
                self.openInVSCode()
                
                return
            }
            
            self.reveal()
        }
        else if Preferences.shared.openAction == 1
        {
            self.openInTerminal()
        }
        else if Preferences.shared.openAction == 2
        {
            if self.openInVSCode() == false
            {
                self.reveal()
            }
        }
        else if Preferences.shared.openAction == 3
        {
            if self.openInBBEdit() == false
            {
                self.reveal()
            }
        }
        else
        {
            self.reveal()
        }
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
    
    private class func tooltip( for commit: Commit ) -> String
    {
        let formatter                        = DateFormatter()
        formatter.dateStyle                  = .medium
        formatter.timeStyle                  = .short
        formatter.doesRelativeDateFormatting = true
        
        return String(
            format: "Author: %@ <%@>\nDate: %@\nHash: %@\n\n%@",
            commit.author.name,
            commit.author.email,
            formatter.string( from: commit.date ),
            String( commit.commitHash.prefix( 7 ) ),
            commit.message?.trimmingCharacters( in: .whitespacesAndNewlines ) ?? "<empty>"
        )
    }
    
    public func httpAuthentication( for url: URL ) -> HTTPCredentials?
    {
        let item = KeychainPassword( service: "Fetcher HTTP Credentials" )
        
        guard let username = item.username,
              let password = item.password
        else
        {
            return nil
        }
        
        return HTTPCredentials( username: username, password: password )
    }
    
    public func sshAuthentication( for url: URL ) -> SSHCredentials?
    {
        let item = KeychainPassword( service: "Fetcher SSH Credentials" )
        
        guard let publicKey  = Preferences.shared.publicKeyPath,
              let privateKey = Preferences.shared.privateKeyPath,
              let password   = item.password
        else
        {
            return nil
        }
        
        return SSHCredentials(
            publicKey:  URL( fileURLWithPath: publicKey ),
            privateKey: URL( fileURLWithPath: privateKey ),
            password:   password
        )
    }
    
    public func fetchDidFail( for url: URL, status: Int, message: String? )
    {
        let message: String =
        {
            if let message = message
            {
                 return message.prefix( 1 ).capitalized + message.dropFirst()
            }
            
            return "Unknown error"
        }()
        
        let error = FetchError(
            url:     url,
            status:  status,
            message: message,
            date:    Date()
        )
        
        Logger.shared.log( error: error )
    }
}
