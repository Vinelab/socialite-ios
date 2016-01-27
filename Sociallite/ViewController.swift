//
//  ViewController.swift
//  Sociallite
//
//  Created by Ibrahim Kteish on 1/26/16.
//  Copyright © 2016 Ibrahim Kteish. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Dispose of any resources that can be recreated.
    
        
//        let twitterSharer = SLTTwitterShareProvider(withDelegate: self)
        
//        twitterSharer.share(self.view, text: "Test tweet")
    
        let facebook = SLTFacebookShareProvider(withDelegate: self)
        facebook.shareMessengerText("test", url: NSURL(string: "http://www.google.com"), description: nil, imageURL: nil)
    }


}

extension ViewController : SLTShareProviderDelegate {
    
    func provider(provider: SLTShareProvider, didCompleteWithResults results: SLTShareResult) {
        
        
        print("p: \(provider)  r: \(results)")
    }
    
    
    func provider(provider: SLTShareProvider, didFailWithError error: NSError) {
     
        print("p: \(provider)  e: \(error)")
    }
    
    
    func providerDidCancel(sharer: SLTShareProvider) {
        
        print("providerDidCancel")
    }
}

