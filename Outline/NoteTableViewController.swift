//
//  ViewController.swift
//  Outline
//
//  Created by Ash Zade on 2017-12-26.
//  Copyright © 2017 Ash Zade. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import CloudCore
import LongPressReorder
import NightNight
import SideMenu

// Get current timestamp
var currentDate = Date()
var shareTitle : String = ""
var shareNoteArray = [DisplayGroup]()

// Initialize group tag
var headerTag : Int = 0

// Item focus
var indexPathFocus = IndexPath()
var nextIndexPath = NSIndexPath()
var enter = false

// For moving and deleting groups
var nextGroup : Int = 0
var childrenItems = [DisplayGroup]()
var parentInd : Int = 0
var old : Bool = false

class NoteTableViewController: UITableViewController, UITextViewDelegate {
    
    // Row reorder
    var reorderTableView: LongPressReorderTableView!
    
    // Create new note data object
    var note = Note(noteTitle: "", groupItems: [[""]], groups: [""], date: currentDate)
    
    // Initialize note
    var noteArray = [
        DisplayGroup(
            indentationLevel: 1,
            item: Item(value: ""),
            hasChildren: false,
            done: false,
            isExpanded: true)
    ]
    
    // To stop jittering when adding/moving rows
    var cellHeights: [IndexPath : CGFloat] = [:]
    
    // For sharing menu
    var dataToSend: AnyObject?

    @IBOutlet weak var NoteTitle: UITextView!
    var placeholderLabel : UILabel!
    @IBOutlet weak var NoteDate: EdgeInsetLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For opening outline files
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            if (delegate.openNote.count > 0) {
                self.noteArray = delegate.openNote
                self.NoteTitle.text = delegate.openNoteTitle
                
                // Save Data
                self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                
                // Save to core data
                self.updateEntity(id: selectedID, attribute: "title", value: self.NoteTitle.text)
                
                delegate.openNote.removeAll()
            }
            
        }
        
        // Themes
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0)
        
        // Get timestamp
        currentDate = Date()
        
        // Note Title - Tableview header view
        self.NoteTitle.tag = 1
        self.NoteTitle.delegate = self
        self.NoteTitle.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        self.NoteTitle.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
        placeholderLabel = UILabel(frame: CGRect(x: 5, y: 0, width: self.NoteTitle.frame.width, height: self.NoteTitle.frame.height))
        placeholderLabel.text = "Add a title"
        self.NoteTitle.addSubview(placeholderLabel)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.font = placeholderLabel.font.withSize(22)
        placeholderLabel.isHidden = !self.NoteTitle.text.isEmpty
        
        // Add border to date
        self.NoteDate.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        // Add Side Menu Button
        let menuButton = UIButton()
        menuButton.setImage(UIImage(named: "menu"), for: .normal)
        menuButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        menuButton.addTarget(self, action: #selector(sideMenu), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: menuButton)
        
        // Used for cell resizing
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Fetch Note Data
        old = false
        getNote()
        
        // Init row reorder
        reorderTableView = LongPressReorderTableView(tableView, scrollBehaviour: .early)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        
        // Reset group title focus
        headerTag = 0
        
        // Hide keyboard if tap anywhere
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        self.view.addGestureRecognizer(tap)
        
        // Set up sidemenu
        let menuRightNavigationController = storyboard!.instantiateViewController(withIdentifier: "RightMenuNavigationController") as! UISideMenuNavigationController
        SideMenuManager.default.menuRightNavigationController = menuRightNavigationController
        SideMenuManager.default.menuFadeStatusBar = false
        SideMenuManager.default.menuPresentMode = .menuSlideIn
        SideMenuManager.default.menuAnimationFadeStrength = 0.5

    }
    
    
    //Calls this function when the tap is recognized.
    @objc func hideKeyBoard(sender: UITapGestureRecognizer? = nil){
        view.endEditing(true)
    }
    
    // Collapse group
    @objc func collapseGroup(sender: UITapGestureRecognizer? = nil){
        let tappedImage = sender?.view as! UIImageView
        
        var cell = tappedImage.superview?.superview?.superview as! UITableViewCell
        
        let indexPath = self.tableView.indexPath(for: cell)
        let parentRow = indexPath!.row
        
        // Find next parent if there is another group
        if (parentRow+1 < noteArray.count-1) {
            for i in (parentRow+1...noteArray.count-1) {
                if (noteArray[i].indentationLevel == noteArray[parentRow].indentationLevel) {
                    nextGroup = i
                    break
                }
            }
        } else {
            // No more groups
            nextGroup = noteArray.count
        }
        
        // Toggle expanded for children
        if (parentRow+1 <= nextGroup-1) {
            for i in (parentRow+1...nextGroup-1) {
                noteArray[i].isExpanded.toggle()
                
            }
        }
            
        
        
        for i in (0...noteArray.count-1) {
            print("loop: \(noteArray[i].isExpanded)")
        }
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
        
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let headerView = tableView.tableHeaderView {
            
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            if (headerFrame.height < ((headerView.viewWithTag(1)?.frame.height)!) + 30) {
                tableView.tableHeaderView?.frame.size = CGSize(width: headerFrame.width, height: (headerView.viewWithTag(1)?.frame.height)! + 35)
                tableView.reloadData()
            }
            headerView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
            
        }
        
        // Set focus to note title
        for subView in tableView.tableHeaderView?.subviews as [UIView]! {
            if let textView = subView as? UITextView {
                if (textView.text == "" && self.noteArray.count == 0) {
                    textView.becomeFirstResponder()
                } else {
                    placeholderLabel.isHidden = !textView.text.isEmpty
                }
            }
        }
        
        // Set active item textview
        if (!indexPathFocus.isEmpty) {
            let rows = self.noteArray.count - 1
            // If user hit enter
            if indexPathFocus.row < rows {
                nextIndexPath = NSIndexPath(row: indexPathFocus.row + 1, section: indexPathFocus.section)
                if let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as? ExpandingCell {
                    if enter == true {
                        self.tableView.scrollToRow(at: nextIndexPath as IndexPath, at: UITableViewScrollPosition.middle, animated: true)
                        textCell.textView.becomeFirstResponder()
                        enter = false
                    }

                }

            }
        }
        
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        print(noteArray[indexPath.row].isExpanded)
//        if (noteArray[indexPath.row].isExpanded == false) {
//            return 10.0
//        } else {
//            return UITableViewAutomaticDimension
//        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 40.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Update data from title and cells
    func textViewDidChange(_ textView: UITextView) {
        
        // If title
        if textView.tag == 1 {
            placeholderLabel.isHidden = !textView.text.isEmpty
            
            // Set title view height
            if (textView.frame.height > self.tableView.viewWithTag(9999)?.frame.height ?? 80) {
                tableView.beginUpdates()
                self.tableView.viewWithTag(9999)?.frame = CGRect(x: 0, y: 0, width: (self.tableView.viewWithTag(9999)?.frame.width)!, height: textView.frame.height + 40)
                tableView.endUpdates()
            } else {
                tableView.beginUpdates()
                self.tableView.viewWithTag(9999)?.frame = CGRect(x: 0, y: 0, width: (self.tableView.viewWithTag(9999)?.frame.width)!, height: textView.frame.height + 40)
                tableView.endUpdates()
            }
            
            // Set note object and title
            self.note!.noteTitle = textView.text!
            
            // Save to core data
            self.updateEntity(id: selectedID, attribute: "title", value: self.note!.noteTitle)
            
            
        } else {
            // Get the cell index info for this textView
            let cell: UITableViewCell = textView.superview!.superview as! UITableViewCell
            let table: UITableView = cell.superview as! UITableView
            let textViewIndexPath = table.indexPath(for: cell)
            let textViewSection = textViewIndexPath?.section
            let textViewRow = textViewIndexPath?.row
            indexPathFocus = textViewIndexPath!
            
            // Save cell ctext
            noteArray[textViewRow!].item?.value = textView.text
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
            
        }
        
    }
    
    // Create groups
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    // Create rows per group
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return noteArray.count
        
    }
    
    
    // Declare the cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! ExpandingCell
        
        // Set value
        
        cell.textView?.text = noteArray[indexPath.row].item?.value
        
        // Add cell text indentation
        let indent = CGFloat(noteArray[indexPath.row].indentationLevel * 10)
        
        // Set up dot
        let frame = CGRect(x: 0, y: 8, width: 10, height: 10)
        let dot = UIImageView(frame: frame)
        dot.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        dot.contentMode = .scaleAspectFit
        var image: UIImage = UIImage(named: "dot")!.withRenderingMode(.alwaysOriginal)
        image = resizeImage(image: image, newWidth: 12)!
        dot.image = image
        dot.tag = 123
        dot.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(collapseGroup))
        dot.addGestureRecognizer(tap)
        
        // Group properties
        if (noteArray[indexPath.row].indentationLevel == 1) {
            
            // Padding
            for constraint in cell.contentView.constraints {
                if constraint.identifier == "cellIndent" {
                    constraint.constant = 8
                }
            }
            
            
            if (cell.textView?.viewWithTag(123) == nil) {
                // Cell padding for parent
                cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: 10,bottom: 5,right: 0)
                
                // Add dot
                cell.textView?.addSubview(dot)
                
                // Remove border
                cell.textView?.removeLeftBorder()
                
            }
        } else {
            // Children properties
            
            // Reset border
            cell.textView?.removeLeftBorder()
            
            // Padding
            for constraint in cell.contentView.constraints {
                if constraint.identifier == "cellIndent" {
                    constraint.constant = 13
                }
            }
            
            // Cell padding for children
            cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: indent,bottom: 5,right: 0)
            
            // Remove dot if it's there
            if (cell.textView?.viewWithTag(123) != nil) {
                cell.textView.viewWithTag(123)?.removeFromSuperview()
            }
            
            // Add border
            cell.textView?.addLeftBorder()
            
        }
        
        // Check for checkmark
        if (self.noteArray[indexPath.row].done == true) {
            cell.textView?.mixedTextColor = MixedColor(normal: UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0), night: UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.0))
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.ultraLight)
        } else if (noteArray[indexPath.row].indentationLevel == 1){
            cell.textView?.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        } else {
            cell.textView?.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
            cell.textView?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)
        }
        
        return cell
        
        
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        for subview in cell.contentView.subviews {
            if subview.tag == 1234 {
               subview.mixedBackgroundColor = MixedColor(normal: 0xefefef, night: 0x4b4b4b)
            }
        }
        
        
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.noteArray.remove(at: indexPath.row)
            // Delete the row from the TableView
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .fade)
        }
    }

    // Enter and backspace action
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if let cell = textView.superview?.superview as? UITableViewCell {
            // Take focus of header
            headerTag = 0
            
            // Which cell are we in?
            let indexPath = tableView.indexPath(for: cell)!
            // Enter creates new item
            if(text == "\n" || text == "\r") {
                
                
                indexPathFocus = indexPath
                enter = true
                var indent = noteArray[indexPath.row].indentationLevel
                
                // Create child item if part of a group
                if (noteArray.indices.contains(indexPath.row+1) && noteArray[indexPath.row+1].indentationLevel > 1) {
                    indent = 2
                }
                
                noteArray.insert(
                    DisplayGroup(
                        indentationLevel: indent,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false,
                        isExpanded: true),
                    at: indexPath.row + 1
                )
                
                
                // Save Data
                self.updateEntity(id: selectedID, attribute: "group", value: self.noteArray)
            
                // Reload the table to reflect the new item
                let contentOffset = tableView.contentOffset
                tableView.reloadData()
                tableView.setContentOffset(contentOffset, animated: false)
                
                return false
            }

            // Backspace empty item deletes item
            if text == "" && range.length == 0 && textView.text == "" {
                // delete item at indexPath
                self.noteArray.remove(at: indexPath.row)
                
                // Save Data
                self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            }
        }
        
        
        // Title lose focus and don't allow return
        if(text == "\n" || text == "\r") {
            if (textView.tag == 1) {
                textView.resignFirstResponder()
            }
        }
        
        return true
    }

    
    // Swipe right options: Indent
    override func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        
        let indentAction = UIContextualAction(style: .normal, title:  "Indent", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            // Select cell
            let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
            
            // Create parent relationship and move children first
            if (indexPath.row-1 >= 0 && indexPath.row+1 <= self.noteArray.count-1) {
                
                // Only do this if the next item is a child
                if (self.noteArray[indexPath.row].indentationLevel < self.noteArray[indexPath.row+1].indentationLevel) {

                    for j in (indexPath.row+1...self.noteArray.count-1) {
                        // If there is another group
                        if (self.noteArray[j].indentationLevel <= self.noteArray[indexPath.row].indentationLevel) {
                            nextGroup = j
                            break
                        } else {
                            // No more groups
                            nextGroup = self.noteArray.count
                        }
                    }
                    
                    // Indent children
                    if (indexPath.row+1 < nextGroup-1) {
                        for k in (indexPath.row+1...nextGroup-1) {
                            self.noteArray[k].indentationLevel += 1
                        }
                    } else {
                        self.noteArray[indexPath.row+1].indentationLevel += 1
                    }
                    
                    
                    // Traverse backwards till you hit the first item with less indentation
                    for i in (0...indexPath.row-1).reversed() {
                        
                        if (self.noteArray[i].indentationLevel < self.noteArray[indexPath.row].indentationLevel) {
                            // Make the item you hit the parent
                            self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                            self.noteArray[i].hasChildren = true
                            
                            // Save Data
                            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                            
                            break
                            
                        }
                        
                    }
                }
                
                
                
            }
            
            // Indent
            self.noteArray[indexPath.row].indentationLevel += 1
    
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
            
            success(true)
        })
        
        indentAction.image = UIImage(named: "indent")
        
        return UISwipeActionsConfiguration(actions: [indentAction])
        
    }
    
    // Swipe left options: Outdent, Mark as Done, Delete
    override func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        // Select cell
        let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
        
        // Outdent
        let outdentAction = UIContextualAction(style: .normal, title:  "Outdent >", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            // Only allow outdent if there is an indent
            if (self.noteArray[indexPath.row].indentationLevel > 1) {
                
                // Remove hasChildren from parent
                for (ind, element) in self.noteArray.enumerated() {
                    if (self.noteArray[indexPath.row].item?.parent === self.noteArray[ind].item) {
                        self.noteArray[ind].hasChildren = false
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [IndexPath(item: ind, section: indexPath.section)], with: UITableViewRowAnimation.fade)
                        self.tableView.endUpdates()
                    }
                }
                
                // Adjust parents
                let myIndent = self.noteArray[indexPath.row].indentationLevel
                
                // If indentation is at the start, set parent to nil
                if (self.noteArray[indexPath.row].indentationLevel == 1) {
                    self.noteArray[indexPath.row].item?.parent = nil
                } else if (indexPath.row-1 > 0) {
                    // Traverse backwards till you hit the first item above with less indentation
                    for i in (0...indexPath.row-1).reversed() {
                        if (self.noteArray[i].indentationLevel < myIndent) {
                            self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                            
                            break
                        }
                    }
                }
                
                // Only do this if it has kids
                if (indexPath.row+1 <= self.noteArray.count-1 && self.noteArray[indexPath.row].indentationLevel < self.noteArray[indexPath.row+1].indentationLevel) {
                    
                    // Find next group
                    for j in (indexPath.row+1...self.noteArray.count-1) {
                        // If there is another group
                        if (self.noteArray[j].indentationLevel <= myIndent) {
                            nextGroup = j
                            break
                        } else {
                            // No more groups
                            nextGroup = self.noteArray.count
                        }
                    }
                    
                    // Outdent children
                    if (indexPath.row+1 < nextGroup-1) {
                        for k in (indexPath.row+1...nextGroup-1) {
                            if (self.noteArray[k].indentationLevel > 0) {
                                self.noteArray[k].indentationLevel -= 1
                            }
                            
                        }
                    } else {
                        if (self.noteArray[indexPath.row+1].indentationLevel > 0) {
                            self.noteArray[indexPath.row+1].indentationLevel -= 1
                        }
                       
                    }
                    
                }
                
                // Outdent
                self.noteArray[indexPath.row].indentationLevel -= 1
            }
            
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
            
            success(true)
        })
        
        outdentAction.image = UIImage(named: "outdent")
        
        // Delete
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
        
            
            // If group
            if (self.noteArray[indexPath.row].hasChildren) {
                // Alert for confirmation
                let alert = UIAlertController(title: "Delete group", message: "Are you sure you want to delete this item and it's children?", preferredStyle: UIAlertControllerStyle.alert)

                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    
                    // Find next group
                    if (indexPath.row+1 < self.noteArray.count-1) {
                        for i in (indexPath.row+1...self.noteArray.count-1) {
                            // If there is another group
                            if (self.noteArray[i].indentationLevel == self.noteArray[indexPath.row].indentationLevel) {
                                nextGroup = i
                                break
                            } else {
                                // No more groups
                                nextGroup = self.noteArray.count
                            }
                        }
                    }
                    
                    // Delete children first
                    if (indexPath.row+1 <= nextGroup-1) {
                        for i in (indexPath.row+1...nextGroup-1).reversed() {
                            self.noteArray.remove(at: i)
                            tableView.deleteRows(at: [IndexPath(row: i, section: indexPath.section)], with: .fade)

                        }
                    }

                    // Delete item in that row
                    self.noteArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                }))

                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                }))


                self.present(alert, animated: true, completion: nil)
                
            } else {
                
                // Delete item
                self.noteArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            
            // Add empty item note is empty
            if (self.noteArray.count == 0) {
                self.noteArray.append(
                    DisplayGroup(
                        indentationLevel: 1,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false,
                        isExpanded: true)
                )
                // Reload table to see the empty item
                let contentOffset = tableView.contentOffset
                tableView.reloadData()
                tableView.setContentOffset(contentOffset, animated: false)
            }

            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
        
            success(true)
        })
        deleteAction.backgroundColor = .red
        deleteAction.image = UIImage(named: "delete")
        
        // Mark item as done
        let doneAction = UIContextualAction(style: .normal, title:  "Done", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            // Add checkmark
            if cell.textView.text.contains("✓") {
                self.noteArray[indexPath.row].item?.value = (self.noteArray[indexPath.row].item?.value)!.replacingOccurrences(of: "✓ ", with: "", options: NSString.CompareOptions.literal, range:nil)
                self.noteArray[indexPath.row].item?.value = (self.noteArray[indexPath.row].item?.value)!.replacingOccurrences(of: "✓", with: "", options: NSString.CompareOptions.literal, range:nil)
                self.noteArray[indexPath.row].done = false
                
            } else {
                self.noteArray[indexPath.row].done = true
                self.noteArray[indexPath.row].item?.value =  "✓ \((self.noteArray[indexPath.row].item?.value)! ?? "")"
            }
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)

            success(true)
            
            let contentOffset = tableView.contentOffset
            tableView.reloadData()
            tableView.setContentOffset(contentOffset, animated: false)
        })
        doneAction.backgroundColor = UIColor(red:0.00, green:0.76, blue:0.71, alpha:1.0)
        doneAction.image = UIImage(named: "check")
        
        return UISwipeActionsConfiguration(actions: [outdentAction, doneAction, deleteAction ])
    }
    
    // Enable row editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func updateDate(dateVar: Date) {
        // Setup Date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: dateVar)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM dd, yyyy - h:mm a"
        let myStringafd = formatter.string(from: yourDate!)
        self.NoteDate.text = myStringafd
        self.NoteDate.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.light)
        self.NoteDate.mixedTextColor = MixedColor(normal: 0x4b4b4b, night: 0xeaeaea)
    }
    
    
    // Get Note
    func getNote() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Retrieve data
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        request.returnsObjectsAsFaults = false
        
        // Setup Date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if selectedID != nil && data.objectID == selectedID as! NSManagedObjectID {
                    // Fetch Title
                    if data.value(forKey: "title") != nil {
                        self.NoteTitle.text = data.value(forKey: "title") as? String
                        self.NoteTitle.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
                    }
                    
                    // Fetch Date
                    if data.value(forKey: "updateDate") != nil {
                        updateDate(dateVar: data.value(forKey: "updateDate") as! Date)
                    }
                    
                    // Fetch Groups
                    if data.value(forKey: "groups") != nil {
                        let groupData = data.value(forKey: "groups") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [DisplayGroup]
                        noteArray = arrayObject
                        
                    }
                    
                    // Fetch Group Items
                    if data.value(forKey: "groupItems") != nil {
                        let groupItemData = data.value(forKey: "groupItems") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupItemData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [[String]]
                        note?.groupItems = arrayObject
                        if (arrayObject.count) > 0 {
                            let groupData = data.value(forKey: "groups") as! NSData
                            let unarchiveObjectOld = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                            let arrayObjectOld = unarchiveObjectOld as AnyObject! as! [Any]
                            if arrayObjectOld[0] is DisplayGroup {
                                
                            } else {
                                note?.groups = arrayObjectOld as! [String]
                                old = true
    
                                // Create new array
                                var oldNote = [DisplayGroup]()
                                
                                // Loop through and create array
                                for (i, group) in (note?.groups.enumerated())! {
                                    // Start with groups
                                    oldNote.append(
                                        DisplayGroup(
                                            indentationLevel: 1,
                                            item: Item(value: group),
                                            hasChildren: false,
                                            done: false,
                                            isExpanded: true)
                                    )
                                    // Add children
                                    for groupItem in (note?.groupItems[i])! {
    
                                        oldNote.append(
                                            DisplayGroup(
                                                indentationLevel: 2,
                                                item: Item(value: groupItem),
                                                hasChildren: false,
                                                done: false,
                                                isExpanded: true)
                                        )
    
                                    }
                                }
                                // Set the note array
                                noteArray = oldNote
                            }

                        }
                    }
                } else if selectedID == nil {
                    // Set current datetime
                    updateDate(dateVar: currentDate)
                    
                    if template.isEmpty == false {
                        self.NoteTitle.text = (template[0] as! String)
                        self.noteArray = template[1] as! [DisplayGroup]
                        
                        // Save Data
                        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
                        
                        // Save to core data
                        self.updateEntity(id: selectedID, attribute: "title", value: self.NoteTitle.text)
                    }
                    
                }
                
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // Update Note
    func updateEntity(id: Any?, attribute: String, value: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext

        
        // If new note
        if id == nil {
            let entity =  NSEntityDescription.entity(forEntityName: "Notes", in:managedContext)
            let noteEntity = NSManagedObject(entity: entity!,insertInto: managedContext)
            switch attribute {
            case "title":
                noteEntity.setValue(value, forKey: "title")
            case "groups":
                let groupData = NSKeyedArchiver.archivedData(withRootObject: value)
                noteEntity.setValue(groupData, forKey: "groups")
            case "groupItems":
                let groupItemData = NSKeyedArchiver.archivedData(withRootObject: value)
                noteEntity.setValue(groupItemData, forKey: "groupItems")
            default:
                return
            }
            noteEntity.setValue(currentDate, forKey: "updateDate")
            do {
                try managedContext.save()
                
                // If this is a new entity, set it as the ID so it updates from now on
                if selectedID == nil {
                    selectedID = noteEntity.objectID
                }
                
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
        } else {
            // Retrieve data
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
            request.returnsObjectsAsFaults = false
            
            
            do {
                let results = try managedContext.fetch(request)
                for data in results as! [NSManagedObject] {
                    if selectedID != nil && data.objectID == selectedID as! NSManagedObjectID {
                        
                        // Loop through attribute types
                        switch attribute {
                        case "updateDate":
                            data.setValue(value, forKey: "updateDate")
                        case "title":
                            data.setValue(value, forKey: "title")
                        case "groups":
                            let groupData = NSKeyedArchiver.archivedData(withRootObject: value)
                            data.setValue(groupData, forKey: "groups")
                        case "groupItems":
                            let groupItemData = NSKeyedArchiver.archivedData(withRootObject: value)
                            data.setValue(groupItemData, forKey: "groupItems")
                        default:
                            return
                        }
                        data.setValue(currentDate, forKey: "updateDate")
                    } 
                    
                }
                
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        // Save
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        updateDate(dateVar: currentDate)
    }
    
    
    // Resize Images
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    // Share note function
    @objc func sideMenu(_ sender: UIButton!) {
        shareTitle = NoteTitle.text
        shareNoteArray = noteArray
        hideKeyBoard()
        performSegue(withIdentifier: "sideMenu", sender: self)
    }
        
}



// Border creator
extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect(x: 0, y: self.frame.height - thickness, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: self.frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect(x: self.frame.width - thickness, y: 0, width: thickness, height: self.frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        border.name = "border"
        
        self.addSublayer(border)
    }
    
}

// Add and remove border
extension UITextView {
    func addLeftBorder (){
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: 1.0, height: self.frame.height)
        border.backgroundColor = UIColor(red:0.79, green:0.79, blue:0.79, alpha:0.5).cgColor
        border.name = "border"
        
        self.layer.addSublayer(border)
    }
    
    func removeLeftBorder() {

        for subview in self.layer.sublayers! {
            if subview.name == "border" {
                subview.removeFromSuperlayer()
                break
            }
        }
        
    }
}

// Reordering cells
extension NoteTableViewController {
    
    override func positionChanged(currentIndex sourceIndexPath: IndexPath, newIndex destinationIndexPath: IndexPath) {
        
        let movedObject = noteArray[sourceIndexPath.row]
        parentInd = destinationIndexPath.row
        
        // Move item
        noteArray.remove(at: sourceIndexPath.row)
        noteArray.insert(movedObject, at: destinationIndexPath.row)
        
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
    
    }
    
    override func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        // Dismiss keyboard
        hideKeyBoard()
        
        // Clear children array
        childrenItems.removeAll()
        
        
        // If item has children
        if (indexPath.row+1 < noteArray.count-1) {
        
                if (noteArray[indexPath.row].indentationLevel < noteArray[indexPath.row+1].indentationLevel) {
                // Find next group
            
                for i in (indexPath.row+1...noteArray.count-1) {
                    // If there is another group
                    if (noteArray[indexPath.row].indentationLevel >= noteArray[i].indentationLevel ) {
                        nextGroup = i
                        break
                    } else {
                        // No more groups
                        nextGroup = noteArray.count
                    }
                }
                
                
                // Create array of children indexes
                if (indexPath.row+1 <= nextGroup-1) {
                    for i in (indexPath.row+1...nextGroup-1) {
                        childrenItems.append(noteArray[i])
                    }
                }
            }
            
        }
        
        return true
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        // Gesture is finished and cell is back inside the table at finalIndex position
        
        // Only move hcildren if they exist and group has moved
        if (initialIndex != finalIndex && childrenItems.count > 0) {
            
            // Insert children back into array
            for (i, child) in childrenItems.enumerated() {
                let ind = (i + 1) + (finalIndex.row)
                noteArray.insert(child, at: ind)
                
            }
            
            // If moving top to bottom
            if (initialIndex < finalIndex) {
                // Find and remove originals from the top down
                for (i, child) in childrenItems.enumerated() {
                    
                    if let ind = noteArray.index(where: {$0 == child}) {
                        noteArray.remove(at: ind)
                    }
                    
                }
            } else {
                // Find and remove originals from the bottom up
                for (i, child) in childrenItems.enumerated() {
                    
                    if let ind = noteArray.reversed().index(where: {$0 == child}) {
                        noteArray.remove(at: ind.base-1)
                    }
                    
                }
            }
            
            
        }
        
        let contentOffset = tableView.contentOffset
        tableView.reloadData()
        tableView.setContentOffset(contentOffset, animated: false)
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
    }
    

}
