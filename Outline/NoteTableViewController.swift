//
//  ViewController.swift
//  Outline
//
//  Created by Ash Zade on 2017-12-26.
//  Copyright © 2017 Ash Zade. All rights reserved.
//

import UIKit
import CoreData
import LongPressReorder

// Get current timestamp
let currentDate = Date()
var editing = false
var headerTag : Int = 0

class NoteTableViewController: UITableViewController, UITextViewDelegate{
    // Row reorder
    var reorderTableView: LongPressReorderTableView!
    
    // Create new note object
    var note = Note(noteTitle: "", groupItems: [[""]], groups: [""], date: currentDate)
    
    // Note title
    let noteTitleButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set note title
        self.noteTitleButton.setTitle("Add a title", for: .normal)
        self.noteTitleButton.titleLabel?.font = UIFont(name: "Gill Sans", size: 24)
        self.noteTitleButton.titleLabel?.minimumScaleFactor = 0.5
        self.noteTitleButton.titleLabel?.numberOfLines = 1
        self.noteTitleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.noteTitleButton.titleLabel?.textAlignment = NSTextAlignment.center
        self.noteTitleButton.setTitleColor(UIColor(red: 0.0392, green: 0.3961, blue: 0.4549, alpha: 1.0), for: .normal)
        self.noteTitleButton.addTarget(self, action: #selector(editTitle), for: .touchUpInside)
        self.navigationItem.titleView = noteTitleButton
        
        // Add Edit Button
        let editButton = UIButton()
        editButton.setImage(#imageLiteral(resourceName: "pencil").withRenderingMode(.alwaysOriginal), for: .normal)
        editButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        editButton.imageView?.contentMode = .scaleAspectFit
        editButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        editButton.addTarget(self, action: #selector(shareNote), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: editButton)

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
        
    }
    
    // Hide add new note button
    override func viewDidAppear(_ animated: Bool) {
    
        // Remove Add button
        addButtonView?.removeFromSuperview()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Used for cell resizing
    func textViewDidChange(_ textView: UITextView) {
        // Get the cell index info for this textView
        let cell: UITableViewCell = textView.superview!.superview as! UITableViewCell
        let table: UITableView = cell.superview as! UITableView
        let textViewIndexPath = table.indexPath(for: cell)
        let textViewSection = textViewIndexPath?.section
        let textViewRow = textViewIndexPath?.row
        
        // Save cell's textView to items array
        note!.groupItems[textViewSection!][textViewRow!] = textView.text
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // Add group titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return note!.groups[section]
    }
    
    
    // Group header view
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        
        // Group title style
        let frame = CGRect(x: 14, y: 10, width: 12, height: 12)
        let headerImageView = UIImageView(frame: frame)
        headerImageView.contentMode = .scaleAspectFit
        var image: UIImage = UIImage(named: "dot")!.withRenderingMode(.alwaysOriginal)
        image = resizeImage(image: image, newWidth: 12)!
        headerImageView.image = image
    
        // Group title text
        let label =  UITextField(frame: CGRect(x: 36, y: 0, width: tableView.frame.width - 115, height: 36))
        label.text = note!.groups[section]
        label.placeholder = "Add a group title"
        label.font = UIFont(name: "GillSans-Light", size: 20)
        label.autocorrectionType = UITextAutocorrectionType.yes
        label.keyboardType = UIKeyboardType.default
        label.returnKeyType = UIReturnKeyType.done
        label.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor(red:0.10, green:0.52, blue:0.63, alpha:1.0)
        label.tag = 100+section
        label.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        label.addTarget(self, action: #selector(textFieldInFocus(_:)), for: .editingDidBegin)
        label.addTarget(self, action: #selector(textFieldLostFocus(_:)), for: .editingDidEnd)
        label.delegate = self

        // Add them to the header
        header.addSubview(label)
        header.addSubview(headerImageView)
        
        // Set group title focus after moving
        if headerTag != 0 {
            label.viewWithTag(headerTag)?.becomeFirstResponder()
        }
        
        return header
    }
    
    // Create groups
    override func numberOfSections(in tableView: UITableView) -> Int {
        if note!.groups.isEmpty || (note!.groups.count == 1 && note!.groups[0] == "") {
//            addNewGroup()
        }
        return note!.groups.count
    }
    
    // Create rows per group
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return note!.groupItems[section].count
    }
    
    // Declare the cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ExpandingCell
        
        // Add cell text indentation
        cell.textView?.textContainerInset = UIEdgeInsets(top: 5,left: 12,bottom: 5,right: 10)
        cell.textView.font = UIFont(name: "GillSans-Light", size: 16)
        cell.textView.textColor = UIColor(red:0.27, green:0.29, blue:0.30, alpha:1.0)

        // Set value
        cell.textView?.text = note!.groupItems[indexPath.section][indexPath.row]
        
        // Tag each cell and go to next one automatically
        cell.textView.delegate = self
        cell.textView.tag = indexPath.row
        
        // Add left border
        cell.textView.layer.addBorder(edge: UIRectEdge.left, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        return cell
    }

    // Enter creates a new cell
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n" || text == "\r") {
            if let cell = textView.superview?.superview as? UITableViewCell {
                // Take focus of header
                headerTag = 0
                
                // Which cell are we in?
                let indexPath = tableView.indexPath(for: cell)!
                
                // Check if there is already an empty cell at the end
                let rows = tableView.numberOfRows(inSection: indexPath.section) - 1
                let lastIndexPath = NSIndexPath(row:rows, section: indexPath.section)
                let lastCell = tableView.cellForRow(at: lastIndexPath as IndexPath) as! ExpandingCell
                if lastCell.textView.text != "" {
                    // On enter add empty item at the end of the array
                    note!.groupItems[indexPath.section].insert("", at: note!.groupItems[indexPath.section].count)
                    
                    // Save Data
                    self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
                    
                    // Reload the table to reflect the new item
                    tableView.reloadData()
                }
                
                // Set textview focus on new textview
                if indexPath.row < rows {
                    let nextIndexPath = NSIndexPath(row: indexPath.row + 1, section: indexPath.section)
                    let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as! ExpandingCell
                    textCell.textView.becomeFirstResponder()
                }
                
            }
            
            return false
        }
        return true
    }
    
    // Don't indent background on editing

    
    // Swipe row options
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath
            self.note!.groupItems[indexPath.section].remove(at: indexPath.row)
            
            // Save Data
            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        return [delete]
    }
    
    // Enable row editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Add group button
    @IBAction func AddGroup(_ sender: UIButton) {
        addNewGroup()
    }
    
    // Remove group
    @objc func deleteGroup(_ sender: UIButton!) {
        
        // Remove textfield focus
        for subView in sender.superview?.subviews as! [UIView] {
            if let textField = subView as? UITextField {
                textField.resignFirstResponder()
            }
        }
        
        // Remove group and its items
        note!.groups.remove(at: sender.tag - 100)
        note!.groupItems.remove(at: sender.tag - 100)
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.note!.groups)
        self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
        
        tableView.reloadData()
    }
    
    // Move group down
    @objc func moveGroupDown(_ sender: UIButton!) {
        
        let tag = sender.tag - 100
        
        // Remove textfield focus
        for subView in sender.superview?.subviews as! [UIView] {
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
            self.updateEntity(id: selectedID, attribute: "groups", value: self.note!.groups)
            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            headerTag = sender.tag + 1
            
            // Reload the table
            tableView.reloadData()
            
        }
    }
    
    // Move group up
    @objc func moveGroupUp(_ sender: UIButton!) {
        
        let tag = sender.tag - 100
        
        // Remove textfield focus and set it
        for subView in sender.superview?.subviews as! [UIView] {
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
            self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
            
            headerTag = sender.tag - 1
            
            // Reload the table
            tableView.reloadData()
            
        }
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
    
    // Edit Title
    @objc func editTitle(_ sender: UIButton!) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Edit title", message: "", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Add a title"
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.text = self.note!.noteTitle
            print(self.note!.noteTitle)
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if (textField?.text?.isEmpty)! {
                self.noteTitleButton.titleLabel?.text = self.note!.noteTitle
            } else {
                // Set note object and title
                self.note!.noteTitle = (textField?.text)!
                self.noteTitleButton.titleLabel?.text = self.note!.noteTitle
                
                // Save to core data
                self.updateEntity(id: selectedID, attribute: "title", value: self.note!.noteTitle)
                
                self.tableView.reloadData()
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            
            self.noteTitleButton.titleLabel?.text = self.note!.noteTitle

        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // Get Note
    func getNote() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Retrieve data
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            for data in results as! [NSManagedObject] {
                if selectedID != nil && data.objectID == selectedID as! NSManagedObjectID {
                    // Fetch Title
                    if data.value(forKey: "title") != nil {
                        self.noteTitleButton.setTitle(data.value(forKey: "title") as? String, for: .normal)
                    }
                    // Fetch Groups
                    if data.value(forKey: "groups") != nil {
                        let groupData = data.value(forKey: "groups") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [String]
                        note?.groups = arrayObject
                        
                    }
                    // Fetch Group Items
                    if data.value(forKey: "groupItems") != nil {
                        let groupItemData = data.value(forKey: "groupItems") as! NSData
                        let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: groupItemData as Data)
                        let arrayObject = unarchiveObject as AnyObject! as! [[String]]
                        note?.groupItems = arrayObject
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
                let groupData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groups)
                noteEntity.setValue(groupData, forKey: "groups")
            case "groupItems":
                let groupItemData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groupItems)
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
                            let groupData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groups)
                            data.setValue(groupData, forKey: "groups")
                        case "groupItems":
                            let groupItemData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groupItems)
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
    
    // Update group titles
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.note!.groups[textField.tag - 100] = textField.text!
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groups", value: self.note!.groups)
    }
    
    // Group titles in focus
    @objc func textFieldInFocus(_ textField: UITextField) {
        
        // Group delete button
        let deleteButton = UIButton()
        deleteButton.setImage(#imageLiteral(resourceName: "delete").withRenderingMode(.alwaysOriginal), for: .normal)
        deleteButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
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
        for subView in textField.superview?.subviews as! [UIView] {
            if let dot = subView as? UIImageView {
                dot.isHidden = true
            }
        }

    }
    
    // Group titles lost focus
    @objc func textFieldLostFocus(_ textField: UITextField) {
        
        // Hide delete button
        for subView in textField.superview?.subviews as! [UIView] {
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
        var text = self.noteTitleButton.titleLabel?.text?.uppercased()
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
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
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
            
        let movedObject = note!.groupItems[sourceIndexPath.section][sourceIndexPath.row]
        note!.groupItems[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        note!.groupItems[destinationIndexPath.section].insert(movedObject, at: destinationIndexPath.row)
        
        // Save Data
        self.updateEntity(id: selectedID, attribute: "groupItems", value: self.note!.groupItems)
    
    }
}

// Group title return behaviour
extension NoteTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Set first item in group as focus
        let nextIndexPath = NSIndexPath(row: 0, section: textField.tag - 100)
        let textCell = tableView.cellForRow(at: nextIndexPath as IndexPath) as! ExpandingCell
        textCell.textView.becomeFirstResponder()
        
        return false
    } 
}
