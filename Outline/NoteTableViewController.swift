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
import LongPressReorder
import NightNight

// Get current timestamp
var currentDate = Date()

// Initialize group tag
var headerTag : Int = 0

// Item focus
var indexPathFocus = IndexPath()
var nextIndexPath = NSIndexPath()
var enter = false

class NoteTableViewController: UITableViewController, UITextViewDelegate {
    
    // Row reorder
    var reorderTableView: LongPressReorderTableView!
    
    // Create new note object
    var note = Note(noteTitle: "", groupItems: [[""]], groups: [""], date: currentDate)
    
    var noteArray = [
        DisplayGroup(
            indentationLevel: 1,
            item: Item(value: ""),
            hasChildren: false,
            done: false)
    ]

    @IBOutlet weak var NoteTitle: UITextView!
    var placeholderLabel : UILabel!
    @IBOutlet weak var NoteDate: EdgeInsetLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Themes
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        
        // Get timestamp
        currentDate = Date()
        
        // Note Title - Tableview header view
        self.NoteTitle.tag = 1
        self.NoteTitle.delegate = self
        self.NoteTitle.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        placeholderLabel = UILabel()
        placeholderLabel.text = "Add a title"
        placeholderLabel.font = UIFont(name: "Gill Sans", size: 24)
        placeholderLabel.sizeToFit()
        self.NoteTitle.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (self.NoteTitle.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !self.NoteTitle.text.isEmpty
        
        // Add clock and border to date
        let dateView = UIImageView(frame : (CGRect(x: 6, y: 3, width: 12, height: 12)))
        let clock = UIImage(named: "clock")!.withRenderingMode(.alwaysOriginal)
        dateView.image = clock
        self.NoteDate.addSubview(dateView)
        self.NoteDate.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        // Add Share Button
        let shareButton = UIButton()
        shareButton.setImage(#imageLiteral(resourceName: "share").withRenderingMode(.alwaysOriginal), for: .normal)
        shareButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        shareButton.imageView?.contentMode = .scaleAspectFit
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        shareButton.addTarget(self, action: #selector(shareNote), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)

        // Used for cell resizing
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Fetch Note Data
        getNote()
        
        // Init row reorder
        reorderTableView = LongPressReorderTableView(tableView)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        
        // Reset group title focus
        headerTag = 0
        
        //Hide keyboard if tap anywhere
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        self.view.addGestureRecognizer(tap)
        
        
    }
    
    //Calls this function when the tap is recognized.
    @objc func hideKeyBoard(sender: UITapGestureRecognizer? = nil){
        view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let headerView = tableView.tableHeaderView {
            
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            headerView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
            
            //Comparison necessary to avoid infinite loop
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
        
        // Set focus to note title
        for subView in tableView.tableHeaderView?.subviews as [UIView]! {
            if let textView = subView as? UITextView {
                if (textView.text == "" && note!.groupItems[0] == [""] && note!.groups == [""]) {
                    textView.becomeFirstResponder()
                } else {
                    placeholderLabel.isHidden = !textView.text.isEmpty
                }
            }
        }
        
        // Set active item textview
        if (!indexPathFocus.isEmpty) {
            let rows = tableView.numberOfRows(inSection: indexPathFocus.section) - 1
            // If user hit enter
            if indexPathFocus.row < rows {
                nextIndexPath = NSIndexPath(row: indexPathFocus.row + 1, section: indexPathFocus.section)
                if let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as? ExpandingCell {
                    if enter == true {
                        textCell.textView.becomeFirstResponder()
                        enter = false
                    }
                    
                }
                
            } 
        }
        
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
//            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
            
        }
        
    }

    // Add group titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return note!.groups[section]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ExpandingCell
        
        // Add cell text indentation
        let indent = CGFloat(noteArray[indexPath.row].indentationLevel * 20)
        for constraint in cell.contentView.constraints {
            if constraint.identifier == "cellIndent" {
                constraint.constant = indent
            }
        }
        self.tableView.layoutIfNeeded()
        
        cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: 12,bottom: 5,right: 0)

        // Set value
        cell.textView?.text = noteArray[indexPath.row].item?.value

        
        // Check for checkmark
        if (self.noteArray[indexPath.row].done == true) {
            cell.accessoryType = .checkmark
            cell.textView.mixedTextColor = MixedColor(normal: UIColor(red:0.79, green:0.79, blue:0.79, alpha:1.0), night: UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.0))
            cell.textView.font = UIFont(name: "GillSans-LightItalic", size: 16)
        } else {
            cell.accessoryType = .none
            cell.textView.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
            cell.textView.font = UIFont(name: "GillSans-Light", size: 16)
        }
        
        // Tag each cell and go to next one automatically
        cell.textView.delegate = self
        cell.textView.tag = indexPath.row + 100
        
        // Add left and bottom border
        cell.textView.layer.addBorder(edge: UIRectEdge.left, color: UIColor(red:0.70, green:0.70, blue:0.70, alpha:1.0), thickness: 0.5)
        cell.textView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        for subview in cell.contentView.subviews {
            if subview.tag == 0 {
               subview.mixedBackgroundColor = MixedColor(normal: 0xefefef, night: 0x4b4b4b)
            }
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
                let indent = noteArray[indexPath.row].indentationLevel
                
                noteArray.append(
                    DisplayGroup(
                        indentationLevel: indent,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false)
                )
                
                // Save Data
                self.updateEntity(id: selectedID, attribute: "group", value: self.noteArray)
            
                // Reload the table to reflect the new item
                tableView.reloadData()
                
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
        
        return true
    }

    
    // Swipe right options: Indent
    override func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        
        let indentAction = UIContextualAction(style: .normal, title:  "Indent", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            // Select cell
            let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
            
                
            // Indent
            self.noteArray[indexPath.row].indentationLevel += 1
            
            // Create parent relationship
            if (indexPath.row-1 >= 0) {
                // Traverse backwards till you hit the first item with less indentation
                for i in (0...indexPath.row-1).reversed() {
                    if (self.noteArray[i].indentationLevel < self.noteArray[indexPath.row].indentationLevel) {
                        // Make the item you hit the parent
                        self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                        self.noteArray[i].hasChildren = true

                        break
                    }
                    
                }
            }
            
            // Move any children
            var count = 0
            if (indexPath.row < self.noteArray.count-1) {
                
                for i in (indexPath.row...self.noteArray.count-1) {
                    if self.noteArray[i].item?.parent === self.noteArray[indexPath.row].item {
                        // Found children
                        self.noteArray[i].indentationLevel += 1
                        count += 1
                        
                        // Check next level
                        print("i \(i)")
                        print(i+count)
                        print("count \(count)")
                        if (i+count <= self.noteArray.count-1) {
                            while (i+count <= self.noteArray.count-1) {
                                if (self.noteArray[i+1].item?.parent === self.noteArray[i].item) {
                                    self.noteArray[i+1].indentationLevel += 1
                                    count += 1
                                }
                            }
                        }
                        
                    }
                    
                }
            }
            
            
            tableView.reloadData()
            success(true)
        })
        
        
        
        return UISwipeActionsConfiguration(actions: [indentAction])
        
    }
    
    // Swipe left options: Outdent, Mark as Done, Delete
    override func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let outdentAction = UIContextualAction(style: .normal, title:  "Outdent", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            // Select cell
            let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
            
            // Only allow outdent if there is an indent
            if (self.noteArray[indexPath.row].indentationLevel > 0) {
                // Outdent
                self.noteArray[indexPath.row].indentationLevel -= 1
                
                
                // Adjust parent relationship
                if (indexPath.row-1 >= 0) {
                    // Traverse backwards till you hit the first item with less indentation
                    for i in (0...indexPath.row-1).reversed() {
                        if (self.noteArray[i].indentationLevel < self.noteArray[indexPath.row].indentationLevel) {
                            // Make the item you hit the parent
                            self.noteArray[indexPath.row].item?.parent = self.noteArray[i].item
                            self.noteArray[i].hasChildren = true
                            break
                        } else {
                            self.noteArray[indexPath.row].item?.parent = nil
                        }
                        
                    }
                }
                
                // Move any children
                if (indexPath.row+1 < self.noteArray.count-1) {
                    for i in (indexPath.row+1...self.noteArray.count-1) {
                        if self.noteArray[i].item?.parent?.value == self.noteArray[indexPath.row].item?.value {
                            self.noteArray[i].indentationLevel -= 1
                        }
                    }
                }
                
            }
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
//            tableView.reloadData()
            success(true)
        })
        
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
        
            // Delete children first
            for i in stride(from: self.noteArray.count - 1, through: indexPath.row, by: -1) {
                if self.noteArray[i].item?.parent?.value == self.noteArray[indexPath.row].item?.value {
                    self.noteArray.remove(at: i)
                    tableView.deleteRows(at: [IndexPath(row: i, section: indexPath.section)], with: .fade)
                }
            }

            // Delete item in that row
            self.noteArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Add empty item note is empty
            if (self.noteArray.count == 0) {
                self.noteArray.append(
                    DisplayGroup(
                        indentationLevel: 1,
                        item: Item(value: ""),
                        hasChildren: false,
                        done: false)
                )
                // Reload table to see the empty item
                tableView.reloadData()
            }
        
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
        
            success(true)
        })
        deleteAction.backgroundColor = .red
        
        // Mark item as done
        let doneAction = UIContextualAction(style: .normal, title:  "Done", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            // Toggle done value
            if (self.noteArray[indexPath.row].done == false) {
                self.noteArray[indexPath.row].done = true
            } else if (self.noteArray[indexPath.row].done == true ) {
                self.noteArray[indexPath.row].done = false
            }

            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)

            success(true)
            self.tableView.reloadData()
        })
        doneAction.backgroundColor = UIColor(red:0.38, green:0.38, blue:0.38, alpha:1.0)
        
        return UISwipeActionsConfiguration(actions: [doneAction, deleteAction, outdentAction])
    }
    
    // Enable row editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // Remove group
    @objc func deleteGroup(_ sender: UIButton!) {
        let alert = UIAlertController(title: "Remove Group", message: "Are you sure you want to delete this group and its items?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Remove", style: UIAlertActionStyle.destructive, handler: { action in
            
            // Remove textfield focus
            for subView in sender.superview?.subviews as [UIView]! {
                if let textField = subView as? UITextField {
                    textField.resignFirstResponder()
                }
            }
            
            // Remove group and its items
            self.note!.groups.remove(at: sender.tag - 100)
            self.note!.groupItems.remove(at: sender.tag - 100)
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
//            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            self.tableView.reloadData()

            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
        
    }
    
    // Move group down
    @objc func moveGroupDown(_ sender: UIButton!) {
        
        let tag = sender.tag - 100
        
        // Remove textfield focus
        for subView in sender.superview?.subviews as [UIView]! {
            if let textField = subView as? UITextField {
                textField.resignFirstResponder()
            }
        }

        if note!.groups.indices.contains(tag + 1) {
            // Move group title
            let group = note!.groups.remove(at: tag)
            note!.groups.insert(group, at: tag + 1)
            
            // Move group items
            let items = note!.groupItems.remove(at: tag)
            note!.groupItems.insert(items, at: tag + 1)
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
//            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            headerTag = sender.tag + 1
            
            // Reload the table
            tableView.reloadData()
            
        }
    }
    
    // Move group up
    @objc func moveGroupUp(_ sender: UIButton!) {
        
        let tag = sender.tag - 100
        
        // Remove textfield focus and set it
        for subView in sender.superview?.subviews as [UIView]! {
            if let textField = subView as? UITextField {
                textField.resignFirstResponder()
            }
        }
        
        if note!.groups.indices.contains(tag - 1) {
            // Move group title
            let group = note!.groups.remove(at: tag)
            note!.groups.insert(group, at: tag - 1)
            
            // Move group items
            let items = note!.groupItems.remove(at: tag)
            note!.groupItems.insert(items, at: tag - 1)
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groups", value: self.note!.groups)
//            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            headerTag = sender.tag - 1
            
            // Reload the table
            tableView.reloadData()
            
        }
    }
    
    // Add group button
    @objc func AddGroup(_ sender: UIButton!) {
        addNewGroup()
    }
    
    // Add group alert
    func addNewGroup() {
        
        self.note!.groups.append("")
        self.note!.groupItems.append([""])
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.note!.groups)
        self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
        
        // Set textfield focus
        headerTag = self.note!.groups.count + 99
        
        self.tableView.reloadData()
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
        self.NoteDate.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
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
                        self.NoteTitle.mixedTextColor = MixedColor(normal: UIColor(red:0.10, green:0.52, blue:0.63, alpha:1.0), night: UIColor(red:0.45, green:0.89, blue:0.97, alpha:1.0))
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
                    }
                } else if selectedID == nil {
                    // Set current datetime
                    updateDate(dateVar: currentDate)
                    
                    if template.isEmpty == false {
                        self.NoteTitle.text = template[0] as! String
                        note?.groups = template[1] as! [String]
                        note?.groupItems = template[2] as! [[String]]
                    }
                    
                }
                
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // Create template
    func createTemplate() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity =  NSEntityDescription.entity(forEntityName: "Templates", in:managedContext)
        let templateEntity = NSManagedObject(entity: entity!,insertInto: managedContext)

        templateEntity.setValue(self.NoteTitle.text, forKey: "title")

        let groupData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groups)
        templateEntity.setValue(groupData, forKey: "groups")

        let groupItemData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groupItems)
        templateEntity.setValue(groupItemData, forKey: "groupItems")

        do {
            try managedContext.save()
            let alert = UIAlertController(title: "Template created!", message: "Tap the Add button on the homescreen to select it.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)

        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
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
    
    // Update note title & group titles
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        // Group Titles
        if textField.tag > 1 {
            self.note!.groups[textField.tag - 100] = textField.text!
            
            // Save Data
//            self.updateEntity(id: selectedID, attribute: "groups", value: self.noteArray)
            
        }
        
    }
    
    // Group titles in focus
    @objc func textFieldInFocus(_ textField: UITextField) {
        
        // Group delete button
        let deleteButton = UIButton()
        deleteButton.setImage(#imageLiteral(resourceName: "delete").withRenderingMode(.alwaysOriginal), for: .normal)
        deleteButton.frame = CGRect(x: -1, y: -1, width: 38, height: 38)
        deleteButton.imageView?.contentMode = .scaleAspectFit
        deleteButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        deleteButton.tag = textField.tag
        deleteButton.addTarget(self, action: #selector(deleteGroup), for: .touchUpInside)
        
        // Group down button
        let downGroup = UIButton()
        downGroup.setImage(#imageLiteral(resourceName: "downArrow").withRenderingMode(.alwaysOriginal), for: .normal)
        downGroup.frame = CGRect(x: view.frame.maxX - 96, y: -6, width: 36, height: 36)
        downGroup.imageView?.contentMode = .scaleAspectFit
        downGroup.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        downGroup.tag = textField.tag
        downGroup.addTarget(self, action: #selector(moveGroupDown), for: .touchUpInside)
        
        // Group up button
        let upGroup = UIButton()
        upGroup.setImage(#imageLiteral(resourceName: "upArrow").withRenderingMode(.alwaysOriginal), for: .normal)
        upGroup.frame = CGRect(x: view.frame.maxX - 48, y: -6, width: 36, height: 36)
        upGroup.imageView?.contentMode = .scaleAspectFit
        upGroup.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        upGroup.tag = textField.tag
        upGroup.addTarget(self, action: #selector(moveGroupUp), for: .touchUpInside)
        
        // Show buttons
        textField.superview?.addSubview(deleteButton)
        textField.superview?.addSubview(downGroup)
        textField.superview?.addSubview(upGroup)
        
        // Hide delete button
        for subView in textField.superview?.subviews as [UIView]! {
            if let dot = subView as? UIImageView {
                dot.isHidden = true
            }
        }

    }
    
    // Group titles lost focus
    @objc func textFieldLostFocus(_ textField: UITextField) {
        
        // Hide delete button
        for subView in textField.superview?.subviews as [UIView]! {
            if let btn = subView as? UIButton {
                btn.isHidden = true
            }
            if let dot = subView as? UIImageView {
                dot.isHidden = false
            }
        }
        
    }
    
    // Share note function
    @objc func shareNote(_ sender: UIButton!) {
        
        // text to share
        var text = self.NoteTitle.text
        text?.append("\n")
        
        for (index, group) in self.note!.groups.enumerated() {
            text?.append("\n *\(group)*")
            for items in self.note!.groupItems[index] {
                text?.append("\n - \(items)")
            }
            text?.append("\n")
        }
        
        text?.append("\n [Shared from the Outline App]")
        
        // set up activity view controller
        let createTemplate = TemplateActivity(title: "Create Template", image: UIImage(named: "plus")) { sharedItems in
            self.createTemplate()
        }
        
        
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: [createTemplate])
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
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
        
        self.addSublayer(border)
    }
    
}

// Reordering cells
extension NoteTableViewController {
    
    override func positionChanged(currentIndex sourceIndexPath: IndexPath, newIndex destinationIndexPath: IndexPath) {
        
        let movedObject = noteArray[sourceIndexPath.row]
        noteArray.remove(at: sourceIndexPath.row)
        noteArray.insert(movedObject, at: destinationIndexPath.row)
        
        // Move children
        for i in (0...noteArray.count-1) {
            if (noteArray[i].item?.parent === noteArray[destinationIndexPath.row].item) {
                let movedChild = noteArray[i]
                noteArray.remove(at: i)
                noteArray.insert(movedChild, at: destinationIndexPath.row)
            }
        }
        tableView.reloadData()
        
        // Save Data
//        self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
    
    }
    
    override func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        // Dismiss keyboard
        hideKeyBoard()
        
        return true
    }
    
}

// Textfield return behaviour
extension NoteTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        // Group titles
        if textField.tag > 1 {
            
            // Set first item in group as focus
            let nextIndexPath = NSIndexPath(row: 0, section: textField.tag - 100)
            
            //If the group has items
            if let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as? ExpandingCell {
                textCell.textView.becomeFirstResponder()
            } else {
                
                // Add empty item
                note!.groupItems[textField.tag - 100].append("")
                
                // Save Data
                self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
                tableView.reloadData()
            }
            
            
        } else if textField.tag == 1 {
            textField.resignFirstResponder()
        }
        
        return false
    } 
}

class TemplateActivity: UIActivity {
    
    var _activityTitle: String
    var _activityImage: UIImage?
    var activityItems = [Any]()
    var action: ([Any]) -> Void
    
    init(title: String, image: UIImage?, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        _activityImage = image
        action = performAction
        super.init()
    }
    
    override var activityTitle: String? {
        return _activityTitle
    }
    
    override var activityImage: UIImage? {
        return _activityImage
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.ashzade.outline.addtemplate")
    }
    
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
}

