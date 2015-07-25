//
//  WelcomeViewController.swift
//  SwApp
//
//  Created by Cristian Duguet on 7/19/15.
//  Copyright (c) 2015 CrowdTransfer. All rights reserved.
//

import UIKit
import Alamofire
import Parse
import ParseFacebookUtilsV4


class WelcomeViewController: UIViewController {

    
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var fbLoginButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // navigation bar style
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        bar.shadowImage = UIImage()
        bar.backgroundColor = UIColor(red: 0.0, green: 0.3, blue: 0.5, alpha: 0.0)
        bar.tintColor = UIColor.whiteColor()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func fbLogin(sender: AnyObject) {
        ProgressHUD.show("Signing in...", interaction: false)
        PFFacebookUtils.logInInBackgroundWithReadPermissions(PF_USER_PERMISSIONS) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                if user.isNew {
                    self.requestFacebook(user)
                    println("User signed up and logged in through Facebook!")
                } else {
                    self.requestFacebook(user)
                    //self.userLoggedIn(user)
                    println("User logged in through Facebook!")
                }
            } else {
                ProgressHUD.showError("Facebook sign in error")
                println("Uh oh. The user cancelled the Facebook login.")
            }
        }
    }
    
    func requestFacebook(user: PFUser) {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                println("Error: \(error)")
                ProgressHUD.showError("Failed to fetch Facebook user data")
                PFUser.logOut()
            }
            else
            {
                var userData = result as! NSDictionary
                self.processFacebook(user, userData: userData)
                
                /*println("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                println("User Name is: \(userName)")
                let userEmail : NSString = result.valueForKey("email") as! NSString
                println("User Email is: \(userEmail)")*/
            }
        })
    }
    
    
    func processFacebook(user: PFUser, userData: NSDictionary) {
        let facebookUserId = userData.objectForKey("id") as? String
        //var link = userData.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String
        var link = "http://graph.facebook.com/\(facebookUserId!)/picture"
        let url = NSURL(string: link)
        var request = NSURLRequest(URL: url!)
        let params = ["height": "200", "width": "200", "type": "square"]
        Alamofire.request(.GET, link, parameters: params).response() {
            (request, response, data, error) in
            
            if error == nil {
                var image = UIImage(data: data! as! NSData)!
                
                if image.size.width > 280 {
                    image = Images.resizeImage(image, width: 280, height: 280)!
                }
                var filePicture = PFFile(name: "picture.jpg", data: UIImageJPEGRepresentation(image, 0.6))
                
                filePicture.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                    if error != nil {
                        ProgressHUD.showError("Error saving photo")
                    }
                })
                
                if image.size.width > 60 {
                    image = Images.resizeImage(image, width: 60, height: 60)!
                }
                var fileThumbnail = PFFile(name: "thumbnail.jpg", data: UIImageJPEGRepresentation(image, 0.6))
                fileThumbnail.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                    if error != nil {
                        ProgressHUD.showError("Error saving thumbnail")
                    }
                })
                
                if (filePicture as PFFile? != nil ) { user[PF_USER_PICTURE] = filePicture }
                else { println("No profile picture fetched") }
                if (fileThumbnail as PFFile? != nil) { user[PF_USER_THUMBNAIL] = fileThumbnail }
                else { println("No thumbnail fetched") }
                
                // ------------------------- Get rest of user data -------------------------------------
                user[PF_USER_EMAIL] = userData.objectForKey("email") as! String
                user[PF_USER_FIRSTNAME] = userData.objectForKey("first_name") as! String
                user[PF_USER_LASTNAME] = userData.objectForKey("last_name") as! String
                user[PF_USER_FULLNAME] = userData.objectForKey("name") as! String
                user[PF_USER_FACEBOOKID] = userData.objectForKey("id") as! String

                /*
                if userData["email"] != nil { user[PF_USER_EMAILCOPY] = userData["email"]}
                else { println("No email fetched") }
                
                if userData["first_name"] != nil { user[PF_USER_FIRSTNAME] = userData["first_name"] }
                else { println("No first name fetched") }
                
                if userData["last_name"] != nil { user[PF_USER_LASTNAME] = userData["last_name"] }
                else { println("No last name fetched") }
                
                if userData["name"] != nil { user[PF_USER_FULLNAME] = userData["name"]
                    user[PF_USER_FULLNAME_LOWER] = (userData["name"] as! String).lowercaseString }
                else { println("No username fetched") }
                
                user[PF_USER_FACEBOOKID] = userData["id"]
                */
                
                
                // ----------------------- Check if there is some field Facebook does not retrieve ----------------
                println(user[PF_USER_EMAIL])
                
                if user[PF_USER_FIRSTNAME] == nil || user[PF_USER_LASTNAME] == nil || user[PF_USER_EMAIL] == nil {
                    //perform seque with identifier
                    self.performSegueWithIdentifier("confirmationSegue", sender: self)
                    ProgressHUD.dismiss()
                    // TODO
                    
                    // NSNumberFormatter (numberStyle)
                    // Define Custom Cell Style in RatesTableViewController
                }
                else {
                    user[PF_USER_FIRSTNAME] = user[PF_USER_FIRSTNAME]!
                    user.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError?) -> Void in
                        if error == nil {
                            user[PF_USER_ACTIVATED] = true
                            self.userLoggedIn(user)
                        } else {
                            PFUser.logOut()
                            if let info = error!.userInfo {
                                ProgressHUD.showError("Login error")
                                println(info["error"] as! String)
                            }
                        }
                    })
                }
            } else {
                PFUser.logOut()
                if let info = error!.userInfo {
                    ProgressHUD.showError("Failed to fetch Facebook photo")
                    println(info["error"] as! String)
                }
            }
        }
    }
    
    
    func userLoggedIn(user: PFUser) {
        PushNotication.parsePushUserAssign()
        ProgressHUD.showSuccess("Welcome back!")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // ******************************** Segue customization ************************************
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "confirmationSegue"{
            let vc = segue.destinationViewController as! ConfirmationViewController
            vc.user = PFUser.currentUser()!
        }
    }
    
}
