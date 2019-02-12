//
//  SideMenuTableViewController.swift
//  Outline
//
//  Created by Ash Zade on 2019-01-13.
//  Copyright © 2019 Ash Zade. All rights reserved.
//

import Foundation
import SideMenu
import CoreData
import NightNight

class SideMenuTableViewController: UITableViewController{
    
    @IBOutlet weak var share: UILabel!
    @IBOutlet weak var template: UILabel!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var feedback: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Style title and height
        let label = UILabel()
        label.text = "Options"
        label.textAlignment = .left
        label.textColor = UIColor(red:0.00, green:0.76, blue:0.71, alpha:1.0)
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        
        // Remove Navigation Bar border
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Theming options
        share.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
        template.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
        rate.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
        feedback.mixedTextColor = MixedColor(normal: 0x585858, night: 0xffffff)
        self.navigationController?.navigationBar.mixedBarTintColor = MixedColor(normal: 0xffffff, night: 0x263238)
        self.tableView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        
    }
    
    // Create template
        func createTemplate() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
    
            let entity =  NSEntityDescription.entity(forEntityName: "Templates", in:managedContext)
            let templateEntity = NSManagedObject(entity: entity!,insertInto: managedContext)
    
            templateEntity.setValue(shareTitle, forKey: "title")
    
            let groupData = NSKeyedArchiver.archivedData(withRootObject: shareNoteArray)
            templateEntity.setValue(groupData, forKey: "groups")
    
    
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
            
            // Add to share controller
            let textToShare = [ text ]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        case 1:
            createTemplate()
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
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
    }
    
}
