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

public class ErrorLogWindowController: NSWindowController
{
    @IBOutlet private var arrayController: NSArrayController!
    
    private var timer: Timer?
    
    public init()
    {
        super.init( window: nil )
        
        self.timer = Timer.scheduledTimer( withTimeInterval: 0.5, repeats: true )
        {
            [ weak self ] _ in self?.update()
        }
        
        let _ = self.window
    }
    
    required init?( coder: NSCoder )
    {
        nil
    }
    
    public override var windowNibName: NSNib.Name?
    {
        "ErrorLogWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.arrayController.sortDescriptors =
        [
            NSSortDescriptor( key: "date",      ascending: false ),
            NSSortDescriptor( key: "url.path",  ascending: true ),
            NSSortDescriptor( key: "error.localizedDescription", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) )
        ]
    }
    
    private func update()
    {
        guard let existing = self.arrayController.content as? [ FetchError ] else
        {
            return
        }
        
        var add = [ FetchError ]()
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            Logger.shared.errors.forEach
            {
                if existing.contains( $0 ) == false
                {
                    add.append( $0 )
                }
            }
            
            DispatchQueue.main.async
            {
                self.arrayController.add( contentsOf: add )
            }
        }
    }
    
    @IBAction private func clear( _ sender: Any? )
    {
        Logger.shared.clear()
    }
}
