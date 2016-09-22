//
//  ControllerHelper.swift
//  Stepic
//
//  Created by Alexander Karpov on 10.12.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import Foundation

struct ControllerHelper {
    static func getTopViewController() -> UIViewController? {
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while((topVC!.presentedViewController) != nil){
            topVC = topVC!.presentedViewController
        }
        return topVC
    }
    
    static func instantiateViewController(identifier id: String, storyboardName: String = "Main") -> UIViewController {
        let storyboard = UIStoryboard.init(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier(id) 
    }
    
    static func getAuthController() -> UIViewController {
        let storyboard = UIStoryboard.init(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("AuthNavigation")
        
        return vc
    }
}