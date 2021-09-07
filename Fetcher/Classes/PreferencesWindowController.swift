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

public class PreferencesWindowController: NSWindowController
{
    @IBOutlet private var arrayController: NSArrayController!
    
    @objc public private( set ) dynamic var fetchInterval = 0
    {
        didSet
        {
            if self.fetchInterval != Preferences.shared.fetchInterval
            {
                Preferences.shared.fetchInterval = self.fetchInterval
            }
        }
    }
    
    @objc public private( set ) dynamic var sorting = 0
    {
        didSet
        {
            if self.sorting != Preferences.shared.sorting
            {
                Preferences.shared.sorting = self.sorting
            }
        }
    }
    
    @objc public private( set ) dynamic var openAction = 0
    {
        didSet
        {
            if self.openAction != Preferences.shared.openAction
            {
                Preferences.shared.openAction = self.openAction
            }
        }
    }
    
    @objc public private( set ) dynamic var checkForUpdates = false
    {
        didSet
        {
            if self.checkForUpdates != Preferences.shared.autoCheckForUpdates
            {
                Preferences.shared.autoCheckForUpdates = self.checkForUpdates
            }
        }
    }
    
    @objc public private( set ) dynamic var smartOpen = false
    {
        didSet
        {
            if self.smartOpen != Preferences.shared.smartOpen
            {
                Preferences.shared.smartOpen = self.smartOpen
            }
        }
    }
    
    @objc public private( set ) dynamic var startAtLogin = false
    {
        didSet
        {
            NSApp.setLoginItemEnabled( self.startAtLogin )
        }
    }
    
    @objc private dynamic var username: String?
    @objc private dynamic var password: String?
    
    private var keychainItem:  KeychainPassword?
    private var observations = [ NSKeyValueObservation ]()
    
    public override var windowNibName: NSNib.Name?
    {
        "PreferencesWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        self.reload()
        
        self.keychainItem    = KeychainPassword( service: "Fetcher Git Credentials" )
        self.username        = self.keychainItem?.username ?? ""
        self.password        = self.keychainItem?.password ?? ""
        self.sorting         = Preferences.shared.sorting
        self.checkForUpdates = Preferences.shared.autoCheckForUpdates
        self.startAtLogin    = NSApp.isLoginItemEnabled()
        self.smartOpen       = Preferences.shared.smartOpen
        self.openAction      = Preferences.shared.openAction
        self.fetchInterval   = Preferences.shared.fetchInterval
        
        let o1 = Preferences.shared.observe( \.sorting )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.sorting = Preferences.shared.sorting
        }
        
        let o2 = Preferences.shared.observe( \.autoCheckForUpdates )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.checkForUpdates = Preferences.shared.autoCheckForUpdates
        }
        
        let o3 = Preferences.shared.observe( \.smartOpen )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.smartOpen = Preferences.shared.smartOpen
        }
        
        let o4 = Preferences.shared.observe( \.openAction )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.openAction = Preferences.shared.openAction
        }
        
        let o5 = Preferences.shared.observe( \.fetchInterval )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.fetchInterval = Preferences.shared.fetchInterval
        }
        
        self.observations.append( contentsOf: [ o1, o2, o3, o4, o5 ] )
    }
    
    private func reload()
    {
        if let existing = self.arrayController.content as? [ FolderItem ]
        {
            self.arrayController.remove( contentsOf: existing )
        }
        
        self.arrayController.add( contentsOf: Preferences.shared.paths.map { FolderItem( path: $0 ) } )
    }
    
    @IBAction private func addRemoveFolder( _ sender: Any? )
    {
        guard let control = sender as? NSSegmentedControl else
        {
            NSSound.beep()
            
            return
        }
        
        if control.selectedSegment == 0
        {
            self.addFolder()
        }
        else if control.selectedSegment == 1
        {
            self.removeFolder()
        }
        else
        {
            NSSound.beep()
        }
    }
    
    private func addFolder()
    {
        guard let window = self.window else
        {
            NSSound.beep()
            
            return
        }
        
        let panel                     = NSOpenPanel()
        panel.canChooseFiles          = false
        panel.canChooseDirectories    = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories    = true
        
        panel.beginSheetModal( for: window )
        {
            guard let url = panel.url, $0 == .OK else
            {
                return
            }
            
            Preferences.shared.addPath( url.path )
            self.reload()
        }
    }
    
    private func removeFolder()
    {
        guard let selected = self.arrayController.selectedObjects.first as? FolderItem else
        {
            NSSound.beep()
            
            return
        }
        
        Preferences.shared.removePath( selected.path )
        self.reload()
    }
    
    @IBAction private func saveInKeychain( _ sender: Any? )
    {
        guard let item = self.keychainItem, let username = self.username, let password = self.password, username.count > 0, password.count > 0 else
        {
            NSSound.beep()
            
            return
        }
        
        item.username = username
        item.password = password
        
        do
        {
            try self.keychainItem?.save()
        }
        catch let error
        {
            let alert = NSAlert( error: error )
            
            if let window = self.window
            {
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
            else
            {
                alert.runModal()
            }
        }
    }
}
