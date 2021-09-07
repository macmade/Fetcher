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

public class KeychainPassword
{
    public private( set ) var service:  String
    public private( set ) var exists:   Bool
    public                var username: String?
    public                var password: String?
    
    public init( service: String )
    {
        self.service = service
        self.exists  = false
        
        let query: [ AnyHashable : Any ] =
        [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecMatchLimit:       kSecMatchLimitOne,
            kSecReturnAttributes: NSNumber( booleanLiteral: true ),
            kSecReturnData:       NSNumber( booleanLiteral: true )
        ]
        
        var item: CFTypeRef?
        
        guard SecItemCopyMatching( query as CFDictionary, &item ) == noErr, CFGetTypeID( item ) == CFDictionaryGetTypeID(), let item = item else
        {
            return
        }
        
        let dict = item as! [ AnyHashable : Any ]
        
        guard let data     = dict[ kSecValueData ]   as? Data,
              let password = String( data: data, encoding: .utf8 )
        else
        {
            return
        }
        
        self.username = dict[ kSecAttrAccount ] as? String ?? ""
        self.password = password
        self.exists   = true
    }
    
    public func save() throws
    {
        guard let username = self.username else
        {
            throw NSError( title: "Cannot Create Keychain Item", message: "Username is not set to a valid value." )
        }
        
        guard let password = self.password else
        {
            throw NSError( title: "Cannot Create Keychain Item", message: "Username is not set to a valid value." )
        }
        
        if self.exists
        {
            try self.update( service: self.service, username: username, password: password )
        }
        else
        {
            try self.create( service: self.service, username: username, password: password )
        }
        
        self.exists = true
    }
    
    private func create( service: String, username: String, password: String ) throws
    {
        guard let data = password.data( using: .utf8 ) else
        {
            throw NSError( title: "Invalid Password", message: "Cannot create data from the provided password." )
        }
        
        let query: [ AnyHashable : Any ] =
        [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: username,
            kSecValueData:   data
        ]
        
        guard SecItemAdd( query as CFDictionary, nil ) == noErr else
        {
            throw NSError( title: "Keychain Error", message: "Cannot add generic password item to the keychain." )
        }
    }
    
    private func update( service: String, username: String, password: String ) throws
    {
        guard let data = password.data( using: .utf8 ) else
        {
            throw NSError( title: "Invalid Password", message: "Cannot create data from the provided password." )
        }
        
        let query: [ AnyHashable : Any ] =
        [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service
        ]
        
        let attributes: [ AnyHashable : Any ] =
        [
            kSecAttrAccount: username,
            kSecValueData:   data
        ]
        
        guard SecItemUpdate( query as CFDictionary, attributes as CFDictionary ) == 0 else
        {
            throw NSError( title: "Keychain Error", message: "Cannot update generic password item to the keychain." )
        }
    }
}
