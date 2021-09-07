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
    @objc private dynamic var username: String?
    @objc private dynamic var password: String?
    
    private var keychainItem:  KeychainPassword?
    
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
        
        self.keychainItem = KeychainPassword( service: "Fetcher Git Credentials" )
        self.username     = self.keychainItem?.username ?? ""
        self.password     = self.keychainItem?.password ?? ""
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
}
