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

@objc public class Preferences: NSObject
{
    @objc public dynamic                var lastStart:           Date?
    @objc public dynamic                var autoCheckForUpdates: Bool       = true
    @objc public private( set ) dynamic var paths:               [ String ] = []
    @objc public dynamic                var smartOpen:           Bool       = true
    @objc public dynamic                var sorting:             Int        = 0
    
    @objc public static let shared = Preferences()
    
    public func addPath( _ path: String )
    {
        if self.paths.contains( path )
        {
            return
        }
        
        self.willChangeValue( for: \.paths )
        self.paths.append( path )
        self.didChangeValue( for: \.paths )
    }
    
    public func removePath( _ path: String )
    {
        self.willChangeValue( for: \.paths )
        self.paths.removeAll { $0 == path }
        self.didChangeValue( for: \.paths )
    }
    
    override init()
    {
        super.init()
        
        if let path = Bundle.main.path( forResource: "Defaults", ofType: "plist" )
        {
            UserDefaults.standard.register( defaults: NSDictionary( contentsOfFile: path ) as? [ String : Any ] ?? [ : ] )
        }
        
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            if let value = UserDefaults.standard.object( forKey: key )
            {
                self.setValue( value, forKey: key )
            }
            
            self.addObserver( self, forKeyPath: key, options: .new, context: nil )
        }
    }
    
    deinit
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            self.removeObserver( self, forKeyPath: key )
        }
    }
    
    @objc public override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey : Any ]?, context: UnsafeMutableRawPointer? )
    {
        for c in Mirror( reflecting: self ).children
        {
            guard let key = c.label else
            {
                continue
            }
            
            if( key == keyPath )
            {
                UserDefaults.standard.set( change?[ NSKeyValueChangeKey.newKey ], forKey: key )
            }
        }
    }
}
