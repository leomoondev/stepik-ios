//
//  NotificationRegistrator.swift
//  Stepic
//
//  Created by Alexander Karpov on 21.04.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import UIKit
import Google


//Class for registering the remote notifications service
class NotificationRegistrator: NSObject {
    static let sharedInstance = NotificationRegistrator()
    
    private override init() {
        super.init()
    }
    
//    private var defaults = NSUserDefaults.standardUserDefaults()
//    
//    var didAskForRemoteNotifications : Bool {
//        get {
//            return (defaults.valueForKey("didAskForRemoteNotifications") as? Bool) ?? false
//        }
//        
//        set(value) {
//            defaults.setValue(value, forKey: "didAskForRemoteNotifications")
//            defaults.synchronize()
//        }
//    }
    
    func registerForRemoteNotifications(application: UIApplication) {
        let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func getGCMRegistrationToken(deviceToken deviceToken: NSData) {
        let instanceIDConfig = GGLInstanceIDConfig.defaultConfig()
        instanceIDConfig.delegate = self
        // Start the GGLInstanceID shared instance with that config and request a registration
        // token to enable reception of notifications
        GGLInstanceID.sharedInstance().startWithConfig(instanceIDConfig)
        registrationOptions = [kGGLInstanceIDRegisterAPNSOption:deviceToken,
                               kGGLInstanceIDAPNSServerTypeSandboxOption:true]
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(GGLContext.sharedInstance().configuration.gcmSenderID,
                                                                 scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
    }
    
    var registrationOptions = [String: AnyObject]()
    
    let registrationKey = "onRegistrationCompleted"

    private func registrationHandler(registrationToken: String!, error: NSError!) {
        if (registrationToken != nil) {
            print("Registration Token: \(registrationToken)")
            let device = Device(registrationId: registrationToken, deviceDescription: "ios test device sample description")
            ApiDataDownloader.devices.create(device, success: {
                device in
                DeviceDefaults.sharedDefaults.deviceId = device.id
                print("created device: \(device.getJSON())")
            }, error : {
                error in 
                print("device creation error")
            })
            
//            let userInfo = ["registrationToken": registrationToken]
//            NSNotificationCenter.defaultCenter().postNotificationName(self.registrationKey, object: nil, userInfo: userInfo)
        } else {
            print("Registration to GCM failed with error: \(error.localizedDescription)")
            
//            let userInfo = ["error": error.localizedDescription]
//            NSNotificationCenter.defaultCenter().postNotificationName(self.registrationKey, object: nil, userInfo: userInfo)
        }
    }    
    
    
    // Should be executed first before any actions were performed, contains abort()
    //TODO: remove abort, add failure completion handler 
    func unregisterFromNotifications(completion completion: (Void->Void)) {
        print(StepicAPI.shared.token?.accessToken)
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
        if let deviceId = DeviceDefaults.sharedDefaults.deviceId {
            ApiDataDownloader.devices.delete(deviceId, success: 
                {
                    print("successfully deleted device with id \(deviceId) when unregistering from notifications")
                    completion()
                }, error:
                {
                    errorMessage in 
                    print(errorMessage)
                    print("initializing delete device task")
                    print("user id \(StepicAPI.shared.userId) , token \(StepicAPI.shared.token)")
                    if let userId =  StepicAPI.shared.userId,
                        token = StepicAPI.shared.token {
                        
                        let deleteTask = DeleteDeviceExecutableTask(userId: userId, deviceId: deviceId)
                        ExecutionQueues.sharedQueues.connectionAvailableExecutionQueue.push(deleteTask)
                        
                        let userPersistencyManager = PersistentUserTokenRecoveryManager(baseName: "Users")
                        userPersistencyManager.writeStepicToken(token, userId: userId)
                        
                        let taskPersistencyManager = PersistentTaskRecoveryManager(baseName: "Tasks")
                        taskPersistencyManager.writeTask(deleteTask, name: deleteTask.id)
                        
                        let queuePersistencyManager = PersistentQueueRecoveryManager(baseName: "Queues") 
                        queuePersistencyManager.writeQueue(ExecutionQueues.sharedQueues.connectionAvailableExecutionQueue, key: ExecutionQueues.sharedQueues.connectionAvailableExecutionQueueKey)                        
                        
                        DeviceDefaults.sharedDefaults.deviceId = nil
                        completion()
                    } else {
                        print("Could not get current user ID or token to delete device")
                        completion()
//                        abort()
                    }
                }
                
            )
        } else {
            print("no deviceId found")
            completion()
        }
    }
    
}

extension NotificationRegistrator : GGLInstanceIDDelegate {
    func onTokenRefresh() {
        print("The GCM registration token needs to be changed.")
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(GGLContext.sharedInstance().configuration.gcmSenderID,
                                                                 scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
    }
}