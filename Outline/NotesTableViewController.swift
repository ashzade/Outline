//
//  NotesTableViewController.swift
//  Outline
//
//  Created by Ash Zade on 2017-12-31.
//  Copyright © 2017 Ash Zade. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import LongPressReorder
import Floaty
import NightNight

// Empty array of notes
var notes =  [[Any]]()
var selectedID : Any?
var template = [Any]()
var templates = [[Any]]()

// Empty addButtonView container
var addButtonView : UIView?

class NotesTableViewController: UITableViewController {

    var reorderTableView: LongPressReorderTableView!
    
    let floaty = Floaty()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Themes
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.navigationController?.navigationBar.addGestureRecognizer(tap)
        
        // Add Info Button
        let infoButton = UIButton()
        infoButton.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)
        infoButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        var titleView : UIImageView
        // set the dimensions you want here
        titleView = UIImageView(frame:CGRect(x:0, y:0, width:20, height:20))
        // Set how do you want to maintain the aspect
        titleView.contentMode = .scaleAspectFit
        titleView.image = UIImage(named: "title")
        self.navigationItem.titleView = titleView
        
        // Configure
        floaty.buttonImage = UIImage(named: "add")
        floaty.tag = 200
        
        // Remove Navigation Bar border
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Hide Back Button Text
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Add Back Button Image
        let backButton = UIImage(named: "back")
        self.navigationController?.navigationBar.backIndicatorImage = backButton
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButton
        
        // Reorder cells
        reorderTableView = LongPressReorderTableView(tableView)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        
        // Used for cell resizing
        self.tableView.estimatedRowHeight = 88.0
        self.tableView.rowHeight = UITableViewAutomaticDimension

    }
    
    override func viewDidAppear(_ animated: Bool) {
        getNotes()
        getTemplates()
        tableView.reloadData()
        
        // Add button logic
        if templates.isEmpty {
            
            // If Add button already exists just show it
            if ((addButtonView) != nil) {
                self.parent?.view.viewWithTag(100)?.isHidden = false
                
            } else {
            
                // Create addButton view wrapper
                addButtonView = UIView(frame: CGRect(x: view.frame.maxX - 100, y: view.frame.maxY - 100, width: 100, height: 100))
                
                // Add Add Button
                let addButton = UIButton(type: .system)
                addButton.setImage(#imageLiteral(resourceName: "add").withRenderingMode(.alwaysOriginal), for: .normal)
                addButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                addButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
                addButton.tag = 100
                
                addButtonView?.addSubview(addButton)
                self.parent?.view.addSubview(addButtonView!)
            }
            
        } else {
            self.parent?.view.viewWithTag(200)?.isHidden = false
            
            // Reset items
            floaty.items.removeAll()
            
            // Create items
            floaty.addItem("Blank", icon: UIImage(named: "plus")!, handler: { item in
                selectedID = nil
                template = []
                // HIDE ADD BUTTON SUBVIEW HERE
                self.parent?.view.viewWithTag(100)?.isHidden = true
                self.performSegue(withIdentifier: "editNote", sender: self)
            })
            
            for templateItem in templates {
                
                let floatyTitle = templateItem[0] as! String
                
                floaty.addItem(floatyTitle, icon: UIImage(named: "plus")!, handler: { item in
                    selectedID = nil
                    template = [floatyTitle, templateItem[1], templateItem[2]]
                    // HIDE ADD BUTTON SUBVIEW HERE
                    self.parent?.view.viewWithTag(200)?.isHidden = true
                    self.performSegue(withIdentifier: "editNote", sender: self)
                })
                
            }
            
            for item in floaty.items {
                let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.floatyLongPress))
                item.addGestureRecognizer(recognizer)
            }
        

            // Add to view
            self.parent?.view.addSubview(floaty)
        }
        
    }
    
    // Toggle dark mode
    @objc func doubleTapped() {
        NightNight.toggleNightTheme()
    }
    
    // Floaty long press
    @objc func floatyLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
            let floatyItem = sender.view as! FloatyItem
            
            for (index,item) in self.floaty.items.enumerated() {
                if item == floatyItem && index != 0 {
                    func removeTemplateItem(alert: UIAlertAction!) {
                        self.floaty.removeItem(item: item)
                        removeTemplateData(templateTitle: item.title!)

                    }
                    
                    let alert = UIAlertController(title: "Remove Template", message: "Do you want to delete this template?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: removeTemplateItem))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if notes.count == 0 {
            self.tableView.setEmptyMessage("Create a new Note by clicking \n the '+' button below.")
        } else {
            self.tableView.restore()
        }
        
        return notes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Note", for: indexPath) as! NoteCell

        // Set title and updated date
        cell.noteTitle?.text = notes[indexPath.row][0] as? String
        cell.noteDate?.text = notes[indexPath.row][1] as? String
        
        // Add clock icon
        let dateView = UIImageView(frame : (CGRect(x: 0, y: 7, width: 12, height: 12)));
        let clock = UIImage(named: "clock")!.withRenderingMode(.alwaysOriginal);
        dateView.image = clock;
        cell.noteDate?.addSubview(dateView)
        
        // Themes
        cell.noteTitle?.mixedTextColor = MixedColor(normal: 0x5e5e5e, night: 0xffffff)
        cell.noteDate?.mixedTextColor = MixedColor(normal: 0x4b4b4b, night: 0xeaeaea)
        cell.noteDate?.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
    }
    
    // Swipe row options
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            // Delete from coredata
            self.deleteNote(id: notes[indexPath.row][2] as! NSManagedObjectID)
            
            // Delete from table array
            notes.remove(at: indexPath.row)
            
            tableView.reloadData()
        }
        
        return [delete]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Pass OjbectID to selectedID for next view
        selectedID = notes[indexPath.row][2]
        
        // HIDE ADD BUTTON SUBVIEW HERE
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
    }
    
    
    // Add Note Function
    @objc func addNote(_ sender: UIButton!) {
        selectedID = nil
        // HIDE ADD BUTTON SUBVIEW HERE
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
        
        performSegue(withIdentifier: "editNote", sender: self)
    }
    
    // Show Info Function
    @objc func showInfo (_ sender: UIButton!) {

        // HIDE ADD BUTTON SUBVIEW HERE
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        view.superview?.superview?.superview?.viewWithTag(200)?.isHidden = true
        
        performSegue(withIdentifier: "showInfo", sender: self)
    }
    
    // Fetch templates
    func getTemplates() {
        templates.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Templates")
        let sort = NSSortDescriptor(key: "title", ascending: true)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        
        // Get results
        do {
            let results = try context.fetch(request)
            // Validate reuslts
            for data in results as! [NSManagedObject] {
                // Fetch Template Names
                if data.value(forKey: "title") != nil {
                    let templateTitle = data.value(forKey: "title") as! String
                    if templateTitle != "" {
                        
                        // Fetch Groups
                        let groupData = data.value(forKey: "groups") as! NSData
                        let unarchiveGroup = NSKeyedUnarchiver.unarchiveObject(with: groupData as Data)
                        let arrayGroup = unarchiveGroup as AnyObject! as! [String]
                        var groups = arrayGroup
                        
                        // Fetch Group Items
                        let groupItemData = data.value(forKey: "groupItems") as! NSData
                        let unarchiveGroupItem = NSKeyedUnarchiver.unarchiveObject(with: groupItemData as Data)
                        let arrayGroupItem = unarchiveGroupItem as AnyObject! as! [[String]]
                        var groupItems = arrayGroupItem
                        
                        templates.append([templateTitle, groups, groupItems ])
                    }
                }
                    
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func removeTemplateData(templateTitle: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Templates")
        let sort = NSSortDescriptor(key: "title", ascending: true)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        
        // Get results
        do {
            let results = try context.fetch(request)
            // Validate reuslts
            for data in results as! [NSManagedObject] {
                if data.value(forKey: "title") != nil {
                    if (templateTitle == data.value(forKey: "title") as! String) {
                        context.delete(data)
                        do {
                            try context.save() // <- remember to put this :)
                        } catch {
                            // Do something... fatalerror
                        }
                    }
                }
                
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // Fetch all notes
    func getNotes() {
        notes.removeAll()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        let sort = NSSortDescriptor(key: "updateDate", ascending: false)
        let sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sortDescriptors
        // Setup Date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Get results
        do {
            let results = try context.fetch(request)
            // Validate reuslts
            for data in results as! [NSManagedObject] {
                if data.value(forKey: "title") != nil && data.value(forKey: "updateDate") != nil {
                    
                    // Convert Date format
                    let myString = formatter.string(from: data.value(forKey: "updateDate") as! Date)
                    let yourDate = formatter.date(from: myString)
                    formatter.dateFormat = "MMM dd, yyyy - h:mm a"
                    let myStringafd = formatter.string(from: yourDate!)
                    
                    // Add title and date to notesarray
                    notes.append([data.value(forKey: "title") as! String, myStringafd, data.objectID])
                } else if data.value(forKey: "title") != nil {
                    notes.append([data.value(forKey: "title") as! String, "no date", data.objectID])
                } else {
                    notes.append(["no title", "no date", data.objectID])
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // Delete note
    func deleteNote(id: NSManagedObjectID) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notes")
        request.returnsObjectsAsFaults = false
        
        // Get results
        do {
            let results = try context.fetch(request)
            // Validate reuslts
            for data in results as! [NSManagedObject] {
                if (data.objectID == id) {
                    context.delete(data)
                    do {
                        try context.save() // <- remember to put this :)
                    } catch {
                        // Do something... fatalerror
                    }
                }
                
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
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
    
    // Table editing
    @objc func showEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
}

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = UIColor.lightGray
        messageLabel.numberOfLines = 2;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "Gill Sans", size: 20)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
        self.separatorStyle = .none;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}
