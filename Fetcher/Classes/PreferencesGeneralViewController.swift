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

import Foundation

public class PreferencesGeneralViewController: PreferencesViewController
{
    private var observations = [ NSKeyValueObservation ]()
    
    public init()
    {
        super.init( title: "General", icon: NSImage( named: NSImage.preferencesGeneralName ), sorting: 0 )
    }
    
    required init?( coder: NSCoder )
    {
        nil
    }
    
    public override var nibName: NSNib.Name?
    {
        "PreferencesGeneralViewController"
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.sortBy          = Preferences.shared.sorting
        self.checkForUpdates = Preferences.shared.autoCheckForUpdates
        self.startAtLogin    = NSApp.isLoginItemEnabled()
        self.smartOpen       = Preferences.shared.smartOpen
        self.openAction      = Preferences.shared.openAction
        self.fetchInterval   = Preferences.shared.fetchInterval
        
        let o1 = Preferences.shared.observe( \.sorting )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.sortBy = Preferences.shared.sorting
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
    
    @objc public private( set ) dynamic var sortBy = 0
    {
        didSet
        {
            if self.sortBy != Preferences.shared.sorting
            {
                Preferences.shared.sorting = self.sortBy
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
}
