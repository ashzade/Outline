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

        tableView.contentInset =  UIEdgeInsetsMake(0, 20, 0, -20)
        
        // Add Edit Button
        let editButton = UIButton()
        editButton.setImage(#imageLiteral(resourceName: "pencil").withRenderingMode(.alwaysOriginal), for: .normal)
        editButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        editButton.imageView?.contentMode = .scaleAspectFit
        editButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 5.0)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: editButton)
        
        // Set Title
        self.navigationItem.title = "Outline"
        
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
        
        reorderTableView = LongPressReorderTableView(tableView)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getNotes()
        tableView.reloadData()
        
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Note", for: indexPath)

        // Set title and updated date
        cell.textLabel?.text = notes[indexPath.row][0] as? String
        cell.detailTextLabel?.text = notes[indexPath.row][1] as? String
    
        // Look & Feel
        let frame = CGRect(x: -20, y: 18, width: 12, height: 12)
        let headerImageView = UIImageView(frame: frame)
        headerImageView.contentMode = .scaleAspectFit
        var image: UIImage = UIImage(named: "dot")!.withRenderingMode(.alwaysOriginal)
        image = resizeImage(image: image, newWidth: 12)!
        headerImageView.image = image
        
        cell.detailTextLabel?.layer.addBorder(edge: UIRectEdge.left, color: UIColor(red:0.87, green:0.90, blue:0.91, alpha:1.0), thickness: 0.5)
        
        cell.contentView.addSubview(headerImageView)

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
    }
    
    // Add Note Function
    @objc func addNote(_ sender: UIBarButtonItem!) {
        selectedID = nil
        performSegue(withIdentifier: "editNote", sender: self)
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
                    formatter.dateFormat = "MMMM dd, yyyy - h:mm a"
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
