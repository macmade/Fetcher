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

public class FetchError: NSObject
{
    @objc public private( set ) dynamic var url:   URL
    @objc public private( set ) dynamic var error: Error
    @objc public private( set ) dynamic var date:  Date
    
    public convenience init( url: URL, status: Int, message: String, date: Date )
    {
        let error = NSError(
            domain:   "com.xs-labs.Fetcher",
            code:     Int( status ),
            userInfo: [ NSLocalizedDescriptionKey : message ]
        )
        
        self.init( url: url, error: error, date: date )
    }
    
    public init( url: URL, error: Error, date: Date )
    {
        self.url   = url
        self.error = error
        self.date  = date
    }
    
    public override func isEqual( _ object: Any?) -> Bool
    {
        guard let object = object as? FetchError else
        {
            return false
        }
        
        return self.url == object.url && self.error.localizedDescription == object.error.localizedDescription && self.date == object.date
    }
    
    public override func isEqual( to object: Any? ) -> Bool
    {
        self.isEqual( object )
    }
}
