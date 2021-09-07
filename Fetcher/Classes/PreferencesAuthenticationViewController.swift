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

public class PreferencesAuthenticationViewController: PreferencesViewController
{
    @objc private dynamic var username:   String?
    @objc private dynamic var password:   String?
    @objc private dynamic var passphrase: String?
    
    @objc private dynamic var publicKeyPath: String?
    {
        didSet
        {
            if self.publicKeyPath != Preferences.shared.publicKeyPath
            {
                Preferences.shared.publicKeyPath = self.publicKeyPath
            }
        }
    }
    
    @objc private dynamic var privateKeyPath: String?
    {
        didSet
        {
            if self.privateKeyPath != Preferences.shared.privateKeyPath
            {
                Preferences.shared.privateKeyPath = self.privateKeyPath
            }
        }
    }
    
    private var observations: [ NSKeyValueObservation ] = []
    private var httpKeychainItem: KeychainPassword?
    private var sshKeychainItem:  KeychainPassword?
    
    public init()
    {
        super.init( title: "Authentication", icon: NSImage( named: NSImage.userAccountsName ), sorting: 2 )
    }
    
    required init?( coder: NSCoder )
    {
        nil
    }
    
    public override var nibName: NSNib.Name?
    {
        "PreferencesAuthenticationViewController"
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.httpKeychainItem = KeychainPassword( service: "Fetcher HTTP Credentials" )
        self.sshKeychainItem  = KeychainPassword( service: "Fetcher SSH Credentials" )
        self.username         = self.httpKeychainItem?.username ?? ""
        self.password         = self.httpKeychainItem?.password ?? ""
        self.passphrase       = self.sshKeychainItem?.password
        self.publicKeyPath    = Preferences.shared.publicKeyPath
        self.privateKeyPath   = Preferences.shared.privateKeyPath
        
        let o1 = Preferences.shared.observe( \.publicKeyPath )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.publicKeyPath = Preferences.shared.publicKeyPath
        }
        
        let o2 = Preferences.shared.observe( \.privateKeyPath )
        {
            [ weak self ] o, c in guard let self = self else { return }
            
            self.privateKeyPath = Preferences.shared.privateKeyPath
        }
        
        self.observations.append( contentsOf: [ o1, o2 ] )
    }
    
    @IBAction private func savePasswordInKeychain( _ sender: Any? )
    {
        guard let item = self.httpKeychainItem, let username = self.username, let password = self.password, username.count > 0, password.count > 0 else
        {
            NSSound.beep()
            
            return
        }
        
        item.username = username
        item.password = password
        
        do
        {
            try self.httpKeychainItem?.save()
        }
        catch let error
        {
            let alert = NSAlert( error: error )
            
            if let window = self.view.window
            {
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
            else
            {
                alert.runModal()
            }
        }
    }
    
    @IBAction private func savePassphraseInKeychain( _ sender: Any? )
    {
        guard let item = self.sshKeychainItem, let password = self.passphrase, password.count > 0 else
        {
            NSSound.beep()
            
            return
        }
        
        item.username = ""
        item.password = password
        
        do
        {
            try self.sshKeychainItem?.save()
        }
        catch let error
        {
            let alert = NSAlert( error: error )
            
            if let window = self.view.window
            {
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
            else
            {
                alert.runModal()
            }
        }
    }
    
    @IBAction private func choosePublicKey( _ sender: Any? )
    {
        self.chooseKey { self.publicKeyPath = $0.path }
    }
    
    @IBAction private func choosePrivateKey( _ sender: Any? )
    {
        self.chooseKey { self.privateKeyPath = $0.path }
    }
    
    private func chooseKey( completion: @escaping ( URL ) -> Void )
    {
        guard let window = self.view.window else
        {
            NSSound.beep()
            
            return
        }
        
        let panel                     = NSOpenPanel()
        panel.canChooseFiles          = true
        panel.canChooseDirectories    = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories    = false
        panel.showsHiddenFiles        = true
        
        panel.beginSheetModal( for: window )
        {
            guard let url = panel.url, $0 == .OK else
            {
                return
            }
            
            completion( url )
        }
    }
}
