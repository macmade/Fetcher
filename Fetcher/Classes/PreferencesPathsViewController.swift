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

public class PreferencesPathsViewController: PreferencesViewController
{
    @IBOutlet private var arrayController: NSArrayController!
    
    public init()
    {
        super.init( title: "Paths", icon: NSImage( named: NSImage.folderName ), sorting: 1 )
    }
    
    required init?( coder: NSCoder )
    {
        nil
    }
    
    public override var nibName: NSNib.Name?
    {
        "PreferencesPathsViewController"
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        self.reload()
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
        guard let window = self.view.window else
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
}
