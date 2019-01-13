//
//  SideMenuTableViewController.swift
//  Outline
//
//  Created by Ash Zade on 2019-01-13.
//  Copyright © 2019 Ash Zade. All rights reserved.
//

import Foundation
import SideMenu

class SideMenuTableViewController: UITableViewController{
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    // Create template
    //    func createTemplate() {
    //        let appDelegate = UIApplication.shared.delegate as! AppDelegate
    //        let managedContext = appDelegate.persistentContainer.viewContext
    //
    //        let entity =  NSEntityDescription.entity(forEntityName: "Templates", in:managedContext)
    //        let templateEntity = NSManagedObject(entity: entity!,insertInto: managedContext)
    //
    //        templateEntity.setValue(self.NoteTitle.text, forKey: "title")
    //
    //        let groupData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groups)
    //        templateEntity.setValue(groupData, forKey: "groups")
    //
    //        let groupItemData = NSKeyedArchiver.archivedData(withRootObject: self.note!.groupItems)
    //        templateEntity.setValue(groupItemData, forKey: "groupItems")
    //
    //        do {
    //            try managedContext.save()
    //            let alert = UIAlertController(title: "Template created!", message: "Tap the Add button on the homescreen to select it.", preferredStyle: UIAlertControllerStyle.alert)
    //            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
    //            }))
    //            self.present(alert, animated: true, completion: nil)
    //
    //        } catch let error as NSError  {
    //            print("Could not save \(error), \(error.userInfo)")
    //        }
    //    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            // text to share
            var text = "* \(shareTitle) * \n"
            text.append("\n")
            
            
            for (i, group) in shareNoteArray.enumerated() {
                if let item = group.item?.value {
                    text.append(String(repeating: "- ", count: group.indentationLevel))
                    if (group.hasChildren) {
                        text.append("• \(item)")
                    } else {
                        text.append(item)
                    }
                }
                
                text.append("\n")
            }
    
            text.append("\n[Shared from the Outline App]")
            
                    // set up activity view controller
//                    let createTemplate = TemplateActivity(title: "Create Template", image: UIImage(named: "plus")) { sharedItems in
//                        self.createTemplate()
//                    }
            
            
                    let textToShare = [ text ]
                    let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
                    // present the view controller
                self.present(activityViewController, animated: true, completion: nil)
        case 3:
            let appID = "1342189178"
            let urlStr = "itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=\(appID)"
            
            if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        case 4:
            guard let url = URL(string: "https://outlinenotes.com/#contact") else { return }
            UIApplication.shared.open(url)
            
        default:
            print("default")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
