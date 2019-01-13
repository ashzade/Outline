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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            // text to share
            var text = shareTitle
            var note = shareNoteArray
            text.append("\n")
            print(shareNoteArray)
            
            
//                    for (index, group) in self.note!.groups.enumerated() {
//                        text?.append("\n *\(group)*")
//                        for items in self.note!.groupItems[index] {
//                            text?.append("\n - \(items)")
//                        }
//                        text?.append("\n")
//                    }
            
            text.append("\n[Shared from the Outline App]")
            print(text)
            
                    // set up activity view controller
//                    let createTemplate = TemplateActivity(title: "Create Template", image: UIImage(named: "plus")) { sharedItems in
//                        self.createTemplate()
//                    }
            
            
//                    let textToShare = [ text ]
//                    let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: [createTemplate])
//                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
                    // present the view controller
//                self.present(activityViewController, animated: true, completion: nil)
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
