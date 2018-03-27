//
//  InfoUIViewController.swift
//  Outline
//
//  Created by Ash Zade on 2018-03-17.
//  Copyright © 2018 Ash Zade. All rights reserved.
//

import UIKit
import WebKit

class InfoUIViewControler: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let url = URL(string: "https://www.outlinenotes.com/")
        let request = URLRequest(url: url!)
        webView.navigationDelegate = self
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //Page is loaded do what you want
        self.title = "About Outline"
        
    }
}
