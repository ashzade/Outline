//
//  NotesTableViewController.swift
//  Outline
//
//  Created by Ash Zade on 2017-12-31.
//  Copyright © 2017 Ash Zade. All rights reserved.
//

import UIKit
import CoreData
import LongPressReorder

// Empty array of notes
var notes =  [[Any]]()
var selectedID : Any?

// Empty addButtonView container
var addButtonView : UIView?

class NotesTableViewController: UITableViewController {

    var reorderTableView: LongPressReorderTableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Add INfo Button
        let infoButton = UIButton()
        infoButton.setImage(#imageLiteral(resourceName: "info").withRenderingMode(.alwaysOriginal), for: .normal)
        infoButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        // Set Outline Logo Image
        let imageView = UIImageView()
        var title = UIImage(named: "title")
        title = resizeImage(image: title!, newWidth: 90)
        imageView.image = title
        self.navigationItem.titleView = imageView
        
        // Remove Navigation Bar border
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Hide Back Button Text
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Add Back Button Image
        var backButton = UIImage(named: "back")
        backButton = resizeImage(image: backButton!, newWidth: 20)
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
        tableView.reloadData()
        
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
        
        // Add border
        cell.noteDate?.layer.addBorder(edge: UIRectEdge.bottom, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        return cell
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
    }
    
    // Add Note Function
    @objc func addNote(_ sender: UIButton!) {
        selectedID = nil
        // HIDE ADD BUTTON SUBVIEW HERE
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        
        performSegue(withIdentifier: "editNote", sender: self)
    }
    
    // Show Info Function
    @objc func showInfo (_ sender: UIButton!) {

        // HIDE ADD BUTTON SUBVIEW HERE
        view.superview?.superview?.superview?.viewWithTag(100)?.isHidden = true
        
        performSegue(withIdentifier: "showInfo", sender: self)
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
