/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2021 Jean-David Gadina - www-xs-labs.com
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
import GitHubUpdates

@main class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    private var aboutWindowController       = AboutWindowController()
    private var preferencesWindowController = PreferencesWindowController()
    private var mainViewController          = MainViewController()
    private var observations                = [ NSKeyValueObservation ]()
    private var updateCheckTimer:             Timer?
    private var statusItem:                   NSStatusItem?
    private var popover:                      NSPopover?
    
    @objc public dynamic var startAtLogin:                 Bool = false
    @objc public dynamic var automaticallyCheckForUpdates: Bool = false
    
    @IBOutlet private var updater: GitHubUpdater!
    
    func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.startAtLogin               = NSApp.isLoginItemEnabled()
        self.statusItem                 = NSStatusBar.system.statusItem( withLength: NSStatusItem.squareLength )
        self.statusItem?.button?.image  = NSImage( named: "StatusIconTemplate" )
        
        let _ = self.mainViewController.view
        
        let o1 = self.observe( \.startAtLogin )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            if self.startAtLogin
            {
                NSApp.enableLoginItem()
            }
            else
            {
                NSApp.disableLoginItem()
            }
        }
        
        let o2 = self.observe( \.automaticallyCheckForUpdates )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            Preferences.shared.autoCheckForUpdates = self.automaticallyCheckForUpdates
            
            if self.automaticallyCheckForUpdates
            {
                self.updateCheckTimer?.invalidate()
                
                self.updateCheckTimer = Timer( timeInterval: 3600, repeats: true )
                {
                    _ in self.updater.checkForUpdatesInBackground()
                }
                
                DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 5 ) )
                {
                    self.updater.checkForUpdatesInBackground()
                }
            }
            else
            {
                self.updateCheckTimer?.invalidate()
                
                self.updateCheckTimer = nil
            }
        }
        
        self.observations.append( contentsOf: [ o1, o2 ] )
        
        self.automaticallyCheckForUpdates = Preferences.shared.autoCheckForUpdates
        Preferences.shared.lastStart      = Date()
        
        if Preferences.shared.paths.count == 0
        {
            self.showPreferencesWindow( nil )
        }
        
        self.showPreferencesWindow( nil )
    }
    
    @IBAction func showPreferencesWindow( _ sender: Any? )
    {
        if self.popover?.isShown ?? false
        {
            self.popover?.close()
        }
        
        self.preferencesWindowController.window?.layoutIfNeeded()
        
        if self.preferencesWindowController.window?.isVisible == false
        {
            self.preferencesWindowController.window?.center()
        }
        
        NSApp.activate( ignoringOtherApps: true  )
        self.preferencesWindowController.window?.makeKeyAndOrderFront( nil )
    }
    
    @IBAction func showAboutWindow( _ sender: Any? )
    {
        if self.popover?.isShown ?? false
        {
            self.popover?.close()
        }
        
        self.aboutWindowController.window?.layoutIfNeeded()
        
        if self.aboutWindowController.window?.isVisible == false
        {
            self.aboutWindowController.window?.center()
        }
        
        NSApp.activate( ignoringOtherApps: true  )
        self.aboutWindowController.window?.makeKeyAndOrderFront( nil )
    }
    
    @IBAction public func checkForUpdates( _ sender: Any? )
    {
        if self.popover?.isShown ?? false
        {
            self.popover?.close()
        }
        
        NSApp.activate( ignoringOtherApps: true  )
        self.updater.checkForUpdates( sender )
    }
}
