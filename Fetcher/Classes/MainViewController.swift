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

public class MainViewController: NSViewController, NSMenuDelegate
{
    private let queue   = DispatchQueue( label: "com.xs-labs.Fetcher.UpdateQueue" )
    private let limiter = RateLimiter( maxConcurrentOperationCount: 10 )
    
    @objc private dynamic var updating = false
    
    @IBOutlet private var mainMenu:        NSMenu!
    @IBOutlet private var tableView:       NSTableView!
    @IBOutlet private var arrayController: NSArrayController!
    
    private var initialFetchDone = false
    private var observations     = [ NSKeyValueObservation ]()
    private var fetchTimer:        Timer?
    
    public override var nibName: NSNib.Name?
    {
        "MainViewController"
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        self.reload( nil )
        
        self.title = "Fetcher"
        
        let o1 = Preferences.shared.observe( \.paths )
        {
            [ weak self ] _, _ in self?.reload( nil )
        }
        
        let o2 = Preferences.shared.observe( \.sorting )
        {
            [ weak self ] _, _ in self?.updateSortDescriptors()
        }
        
        let o3 = Preferences.shared.observe( \.fetchInterval )
        {
            [ weak self ] _, _ in self?.updateFetchTimer()
        }
        
        self.observations.append( contentsOf: [ o1, o2, o3 ] )
        
        self.updateSortDescriptors()
    }
    
    private func updateFetchTimer()
    {
        self.fetchTimer?.invalidate()
        
        let seconds     = Preferences.shared.fetchInterval * 60
        self.fetchTimer = Timer( timeInterval: TimeInterval( seconds ) , repeats: true )
        {
            _ in self.fetch()
        }
    }
    
    @objc private func fetch()
    {
        guard let repositories = self.arrayController.content as? [ RepositoryItem ] else
        {
            return
        }
        
        repositories.forEach
        {
            repository in self.limiter.execute
            {
                repository.repository.remotes.forEach
                {
                    $0.fetch()
                }
            }
        }
    }
    
    private func updateSortDescriptors()
    {
        var descriptors =
        [
            NSSortDescriptor( key: "name", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ),
            NSSortDescriptor( key: "path", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ),
        ]
        
        if Preferences.shared.sorting == 0
        {
            descriptors.insert( NSSortDescriptor( key: "lastCommitDate", ascending: false ), at: 0 )
        }
        
        self.arrayController.sortDescriptors = descriptors
    }
    
    @IBAction private func showMenu( _ sender: Any? )
    {
        guard let view = sender as? NSView, let event = NSApp.currentEvent else
        {
            NSSound.beep()
            
            return
        }
        
        NSMenu.popUpContextMenu( self.mainMenu, with: event, for: view, with: nil )
    }
    
    @IBAction private func open( _ sender: Any? )
    {
        guard let selected = self.arrayController.selectedObjects.first as? RepositoryItem else
        {
            return
        }
        
        selected.open()
        ApplicationDelegate.shared?.closePopover( sender )
    }
    
    @IBAction private func reload( _ sender: Any? )
    {
        if self.updating
        {
            return
        }
        
        self.queue.async
        {
            var paths: [ String ] = []
            
            DispatchQueue.main.sync
            {
                paths         = Preferences.shared.paths
                self.updating = true
            }
            
            var items: [ RepositoryItem ] = []
            
            paths.forEach
            {
                items.append( contentsOf: self.findRepositories( in: $0 ) )
            }
            
            DispatchQueue.main.sync
            {
                if let existing = self.arrayController.content as? [ RepositoryItem ]
                {
                    self.arrayController.remove( contentsOf: existing )
                }
                
                self.arrayController.add( contentsOf: items )
                
                if self.initialFetchDone == false
                {
                    self.initialFetchDone = true
                    
                    self.fetch()
                    self.updateFetchTimer()
                }
                
                self.updating = false
            }
        }
    }
    
    private func findRepositories( in path: String ) -> [ RepositoryItem ]
    {
        var isDir: ObjCBool = false
        
        guard FileManager.default.fileExists( atPath: path, isDirectory: &isDir ), isDir.boolValue else
        {
            return []
        }
        
        guard let enumerator = FileManager.default.enumerator( atPath: path ) else
        {
            return []
        }
        
        var items: [ RepositoryItem ] = []
        
        for i in enumerator
        {
            enumerator.skipDescendents()
            
            guard let name = i as? String else
            {
                continue
            }
            
            let url = URL( fileURLWithPath: path ).appendingPathComponent( name )
            let git = url.appendingPathComponent( ".git" )
            
            guard FileManager.default.fileExists( atPath: git.path ) else
            {
                continue
            }
            
            if let item = RepositoryItem( url: url )
            {
                items.append( item )
            }
        }
        
        return items
    }
    
    public func menuWillOpen( _ menu: NSMenu )
    {
        menu.items.forEach
        {
            if self.clickedItem == nil
            {
                $0.isEnabled = false
            }
            else if $0.action == #selector( revealInFinder( _: ) )
            {
                $0.isEnabled = true
            }
            else if $0.action == #selector( openInTerminal( _: ) )
            {
                $0.isEnabled = true
            }
            else if $0.action == #selector( openInXcode( _: ) )
            {
                $0.isEnabled = Application.applicationWithBundleID( "com.apple.dt.Xcode" ) != nil && ( self.clickedItem?.hasXcodeProject ?? false )
            }
            else if $0.action == #selector( openInVSCode( _: ) )
            {
                $0.isEnabled = Application.applicationWithBundleID( "com.microsoft.VSCode" ) != nil
            }
            else if $0.action == #selector( openInBBEdit( _: ) )
            {
                $0.isEnabled = Application.applicationWithBundleID( "com.barebones.bbedit" ) != nil
            }
            else
            {
                $0.isEnabled = false
            }
        }
    }
    
    private var clickedItem: RepositoryItem?
    {
        let clicked = self.tableView.clickedRow
        
        guard let arranged = self.arrayController.arrangedObjects as? [ RepositoryItem ],
              clicked >= 0,
              clicked < arranged.count
        else
        {
            return nil
        }
        
        return arranged[ clicked ]
    }
    
    @IBAction private func revealInFinder( _ sender: Any? )
    {
        guard let item = self.clickedItem else
        {
            NSSound.beep()
            
            return
        }
        
        item.reveal()
    }
    
    @IBAction private func openInTerminal( _ sender: Any? )
    {
        if self.clickedItem?.openInTerminal() ?? false == false
        {
            NSSound.beep()
        }
    }
    
    @IBAction private func openInXcode( _ sender: Any? )
    {
        if self.clickedItem?.openInXcode() ?? false == false
        {
            NSSound.beep()
        }
    }
    
    @IBAction private func openInBBEdit( _ sender: Any? )
    {
        if self.clickedItem?.openInBBEdit() ?? false == false
        {
            NSSound.beep()
        }
    }
    
    @IBAction private func openInVSCode( _ sender: Any? )
    {
        if self.clickedItem?.openInVSCode() ?? false == false
        {
            NSSound.beep()
        }
    }
}
