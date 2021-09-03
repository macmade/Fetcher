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
import ApplicationServices

public class Application: NSObject
{
    @objc public dynamic let url:      URL
    @objc public dynamic let bundleID: String
    @objc public dynamic let name:     String
    @objc public dynamic let icon:     NSImage?
    
    public class func applicationWithBundleID( _ bundleID: String ) -> Application?
    {
        guard let urls = LSCopyApplicationURLsForBundleIdentifier( bundleID as CFString, nil )?.takeRetainedValue() as? [ URL ],
              let url  = urls.first
        else
        {
            return nil
        }
        
        return Application( url: url )
    }
    
    private init?( url: URL )
    {
        guard let info     = NSDictionary( contentsOf: url.appendingPathComponent( "Contents/Info.plist" ) ) as? [ AnyHashable : Any ],
              let bundleID = info[ "CFBundleIdentifier" ] as? String
        else
        {
            return nil
        }
        
        self.bundleID = bundleID
        self.url      = url
        self.name     = FileManager.default.displayName( atPath: url.path )
        self.icon     = NSWorkspace.shared.icon( forFile: url.path )
    }
}
