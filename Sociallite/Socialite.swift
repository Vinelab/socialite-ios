//
//  SLTSocial.swift
//  testSocialLogins
//
//  Created by Ibrahim Kteish on 10/28/15.
//  Copyright © 2015 Ibrahim Kteish. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import FBSDKShareKit
import TwitterKit
import MessageUI


//FB login App Events and Notifications
struct SLTAppEventsAndNotifications {
    
    //Events
    static let SLTAppEventNameFBLoginButtonDidTap = "SLTAppEventNameFBLoginButtonDidTap"
    static let SLTAppEventNameFBLoginDidSuccess = "SLTAppEventNameFBLoginDidSuccess"
    static let SLTAppEventNameFBLoginDidCancel = "SLTAppEventNameFBLoginDidCancel"
    static let SLTAppEventNameFBLoginDidLogout = "SLTAppEventNameFBLoginDidLogout"
    static let SLTAppEventNameFBLoginDidFail = "SLTAppEventNameFBLoginDidFail"

    //Notifications
    static let SLTAppNotificationNameUserStateHasChangedNotification = "SLTAppNotificationNameUserStateHasChangedNotification"

}

//Social Internals Utilities
private struct SLTInternals : SLTFacebookPermission {
    
    
    ///Facebook permissions
    static var facebookReadPermissions : [String]  = {
        
        
            return ["public_profile"]
        
    }()
    
    //Providers name
    static let facebookProviderName = "facebook"
    static let facebookMessengerProviderName = "facebookMessenger"
    static let twitterProviderName = "twitter"
    static let whatsappProviderName = "whatsapp"
    static let emailProviderName = "email"
    
    static let providerNameKey = "providerName"
    static let UserStateKey = "State"
    
    ///Attempts to find the first UIViewController in the view's responder chain. Returns nil if not found.
    static func  viewControllerforView(view:UIView) -> UIViewController? {
        
        var responder :UIResponder?  = view.nextResponder()
        
        repeat {
            
            if let unWrappedResponder = responder {
                
                if unWrappedResponder is UIViewController {
                    return unWrappedResponder as? UIViewController
                }
                
                responder = unWrappedResponder.nextResponder()
            }
     
        } while (responder != nil )
        
        return nil
    }
    
}//End


//SLTProvider's Delegate
protocol SLTLoginDelegate {
    
    ///Indicates a successful login
    /// - Parameters:
    ///    - credentials: an object contains the id and token for the requested social medium.
    func userDidLogin(credentials:SLTLoginCredentials)
    ///Logs the user out.
    func userDidLogout()
    ///Indicates that the user cancelled the Login.
    func userDidCancelLogin()
    ///Indicates that the login failed
    /// - Parameters:
    ///    - error: The error object returned by the SDK
    func userLoginFailed(error:NSError)
}

protocol SLTFacebookPermission {
    
    static var facebookReadPermissions : [String] { get }
}

protocol SLTProviderName {
    
    var providerName : String { get }
}

struct SLTFacebookProvider {
    
    //Properties
    let facebookManager = FBSDKLoginManager()
    var delegate : SLTLoginDelegate?

    //Computed Properties
     var isUserLoggedIn : Bool  {
     
        get {
            return FBSDKAccessToken.currentAccessToken() != nil
        }
    }

    //Facebook
    
    ///Logs the user in or authorizes additional permissions, the permissions exist in SLTSocialInternals Struct
    /// - Parameters:
    ///    - button: a reference for the button/View that will trigger this method in order to get its ViewController
    ///    - helper: an object that implements `SLTFacebookPermission` protocol
    func login(button:UIView, helper:SLTFacebookPermission =  SLTInternals()) {

        if self.isUserLoggedIn {
            
            let currentToken = FBSDKAccessToken.currentAccessToken()
            userDidLogin(currentToken)
            return
        }
        
        self.logTapEventWithEventName(SLTAppEventsAndNotifications.SLTAppEventNameFBLoginButtonDidTap, parameters: nil)
        
        let handler : FBSDKLoginManagerRequestTokenHandler = { (result, error) -> Void in
            
            if error != nil {
                self.logTapEventWithEventName(SLTAppEventsAndNotifications.SLTAppEventNameFBLoginDidFail, parameters: nil)
                self.delegate?.userLoginFailed(error)
            } else if result.isCancelled {
                self.delegate?.userDidCancelLogin()
                self.logTapEventWithEventName(SLTAppEventsAndNotifications.SLTAppEventNameFBLoginDidCancel, parameters: nil)

            } else {
                
                self.userDidLogin(result.token)
            }
        }
        
        
        facebookManager.logInWithReadPermissions(helper.dynamicType.facebookReadPermissions, fromViewController: SLTInternals.viewControllerforView(button), handler: handler)
    }
    
    ///Logs the user out
    func logout() {
        
        facebookManager.logOut()
        self.delegate?.userDidLogout()
        logTapEventWithEventName(SLTAppEventsAndNotifications.SLTAppEventNameFBLoginDidLogout, parameters: nil)
        postNotification()
    }
    
    ///Login/Logout Notification
    func postNotification() {
        
        NSNotificationCenter.defaultCenter().postNotificationName(SLTAppEventsAndNotifications.SLTAppNotificationNameUserStateHasChangedNotification, object: [SLTInternals.providerNameKey : self.providerName,SLTInternals.UserStateKey: self.isUserLoggedIn] )
        
    }
    
    /// Helper method it will be called after a successful login
    /// - Parameters:
    ///    - token: the `FBSDKAccessToken` token from `FBSDKLoginManagerLoginResult`
    func userDidLogin(token: FBSDKAccessToken) {
        
        self.delegate?.userDidLogin(SLTFacebookLoginCredentials(userID: token.userID, userToken: token.tokenString))
        self.logTapEventWithEventName(SLTAppEventsAndNotifications.SLTAppEventNameFBLoginDidSuccess, parameters: nil)
        postNotification()
    }
    
    /// Log an event with an eventName, a numeric value to be aggregated with other events of this name,
    ///and a set of key/value pairs in the parameters dictionary.  Providing session lets the developer
    ///target a particular <FBSession>.  If nil is provided, then `[FBSession activeSession]` will be used.
    /// - Parameters:
    ///    - eventName: the name of the event
    ///    - parameters: Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
    ///be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
    ///parameters and name construction are given in the `FBSDKAppEvents` documentation.  Commonly used parameter names
    ///are provided in `FBSDKAppEventParameterName*` constants.

    func logTapEventWithEventName(eventName:String, parameters:[NSObject:AnyObject]? ) {
    
        FBSDKAppEvents.logEvent(eventName,valueToSum: nil,parameters: parameters,accessToken: FBSDKAccessToken.currentAccessToken())
    }
}

extension SLTFacebookProvider : SLTProviderName {
    
    var providerName : String {
        
        get {
            return SLTInternals.facebookProviderName
        }
    }
}

/// a struct that holds user login credentials
class SLTLoginCredentials {
    
    var id : String
    
    init(userID:String) {
        self.id = userID
    }
}

class SLTFacebookLoginCredentials : SLTLoginCredentials {
    
    var token : String
    init(userID:String,userToken:String) {
        
        self.token = userToken    
        super.init(userID: userID)
    }
}

class SLTTwitterLoginProfile : SLTLoginCredentials {
    var token : String
    var secret : String
    init(userID:String,userToken:String,secret : String) {

        self.token = userToken
        self.secret = secret
        super.init(userID: userID)
    }
}

//////////////SHARE//////////////////

//Helpers
let SLTShareErrorDomain = "SLTShareErrors"

///Share Error code
enum SLTShareErrorCode: Int {
    case Unknown = 1
    case AppDoesntExist = 2
    case EmailNotAvailable = 3
}

extension NSError {
    convenience init(code: SLTShareErrorCode, userInfo: [NSObject: AnyObject]? = nil) {
        self.init(domain: SLTShareErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

// This makes it easy to compare an `NSError.code` to an `SLTShareErrorCode`.
func ==(lhs: Int, rhs: SLTShareErrorCode) -> Bool {
    return lhs == rhs.rawValue
}

func ==(lhs: SLTShareErrorCode, rhs: Int) -> Bool {
    return lhs.rawValue == rhs
}

extension String {
    ///Encodes a String with custom allowed set (URLQuery)
    func URLEncodedString() -> String? {
        let customAllowedSet =  NSCharacterSet.URLQueryAllowedCharacterSet()
        let escapedString = self.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)
        return escapedString
    }
}

///Share provider Interface.
protocol SLTShareProvider {
    
    var name : String  { get }
    ///Init the provider with its delegate Object
    init(withDelegate delegate : SLTShareProviderDelegate?)
}

///Struct containing data returned after a successful share operation.
struct SLTShareResult {
    
    var postId : String
    
    init(postID:String?) {
        
        self.postId = postID ?? ""
    }
}

///Protocol definition for callbacks to be invoked when a share operation is triggered.
protocol SLTShareProviderDelegate: class {
    
    ///Sent to the delegate when the share completes without error or cancellation.
    /// - Parameters:
    ///    - sharer: The SLTShareProvider that completed.
    ///    - results: An SLTShareResult Struct containing the PostID if existed
    func provider(provider: SLTShareProvider, didCompleteWithResults results: SLTShareResult)
    ///Sent to the delegate when the sharer encounters an error.
    /// - Parameters:
    ///     - sharer: The SLTShareProvider that completed.
    ///     - Error : The error object
    func provider(provider: SLTShareProvider, didFailWithError error: NSError)
    ///Sent to the delegate when the sharer is cancelled.
    /// - Parameters:
    ///     - sharer: The SLTShareProvider that completed.
    func providerDidCancel(sharer: SLTShareProvider)
}

///A class Implements `FBSDKSharingDelegate's` delegate
/// Since we cannot use Struct to be the `FBSDKSharingDelegate` delegate. That's mean the facebookShareProvider will have this class as a property and it will forward its delegate to this class. 
///
///**Note:** we cannot use this class without setting its 'facebookShareProvider' property
class FBSDKSharingDelegateImpl:NSObject, FBSDKSharingDelegate {

    weak var delegate : SLTShareProviderDelegate?
    var facebookShareProvider : SLTFacebookShareProvider
    
    override init() {
        
        self.facebookShareProvider = SLTFacebookShareProvider()
        super.init()
        fatalError("you cannot init FBSDKSharingDelegateImpl without Facebook share provider use init:delegate instead")
    }
    
    init(facebookShareProvider:SLTFacebookShareProvider) {
      
        self.facebookShareProvider = facebookShareProvider
        super.init()
    }
    
    func sharer(sharer: FBSDKSharing, didCompleteWithResults results: [NSObject : AnyObject]) {
            
        delegate?.provider(facebookShareProvider, didCompleteWithResults: SLTShareResult(postID: results["postid"] as? String))
    }
    
    func sharer(sharer: FBSDKSharing, didFailWithError error: NSError) {
        
        delegate?.provider(facebookShareProvider, didFailWithError: error)
    }
    
    func sharerDidCancel(sharer: FBSDKSharing) {
        
        delegate?.providerDidCancel(facebookShareProvider)
    }

}
/// Struct providing Facebook share operations.
struct SLTFacebookShareProvider : SLTShareProvider {

    var sharingDelegateImpl : FBSDKSharingDelegateImpl!

    var name : String {
        return "SLTFacebookShareProvider"
    }
    
    weak var delegate : SLTShareProviderDelegate? {
        
        didSet {
            //Forward delegation
            self.sharingDelegateImpl.delegate = delegate
        }
    }


    init() {
        self.sharingDelegateImpl = FBSDKSharingDelegateImpl(facebookShareProvider: self)
    }
    
    init(withDelegate delegate: SLTShareProviderDelegate?) {
        
        self.init()
        self.sharingDelegateImpl.delegate = delegate
    }
    
    ///Requests to share a content on the user's feed. 
    /// - Parameters:
    ///     - button:a reference for the button/View that will trigger this method in order to get its ViewController
    ///     - title: The title to display for this link.
    ///     - contentURL: URL for the content being shared.
    ///     - description:The description of the link. If not specified, this field is automatically populated by information scraped from the contentURL, typically the title of the page.  This value may be discarded for specially handled links (ex: iTunes URLs).
    ///     - imageURL: The URL of a picture to attach to this content.
    func share(button:UIView,title:String,contentURL: NSURL?,description:String?,imageURL:NSURL?) {
        
        let content : FBSDKShareLinkContent  = FBSDKShareLinkContent()
        content.contentTitle = title
        
        if let url = contentURL {
            content.contentURL = url
        }
        
        if let des = description {
            content.contentDescription = des
        }
        
        if let imgURL = imageURL {
            content.imageURL = imgURL
        }
        
        FBSDKShareDialog.showFromViewController(SLTInternals.viewControllerforView(button), withContent: content, delegate: sharingDelegateImpl)
    }

    ///Requests to share a content using Facebook Messenger.
    /// - Parameters:
    ///     - title: The title to display for this link.
    ///     - contentURL: URL for the content being shared.
    ///     - description: The description of the link. If not specified, this field is automatically populated by information scraped from the contentURL, typically the title of the page.  This value may be discarded for specially handled links (ex: iTunes URLs).
    ///     - imageURL: The URL of a picture to attach to this content.
    func shareMessengerText(title:String,url: NSURL?,description:String?,imageURL:NSURL?) {
        
        let content : FBSDKShareLinkContent  = FBSDKShareLinkContent()
        content.contentTitle = title
        
        if let url = url {
            content.contentURL = url
        }
        
        if let des = description {
            content.contentDescription = des
        }
        
        if let imgURL = imageURL {
            content.imageURL = imgURL
        }

        
        FBSDKMessageDialog.showWithContent(content, delegate: sharingDelegateImpl)
    }
    
}

extension SLTTwitterShareProvider {
    
    var name : String {
        
        return SLTInternals.twitterProviderName
    }
}


struct SLTTwitterShareProvider  : SLTShareProvider {
    
    weak var delegate : SLTShareProviderDelegate?
    
    init(withDelegate delegate: SLTShareProviderDelegate?) {
        
        self.delegate = delegate
    }
    
    func share(button:UIView , text : String , url: NSURL? = nil, image:UIImage? = nil) {
        
        let composer = TWTRComposer()
        
        composer.setText(text)
        composer.setURL(url)
        
        if let image = image {
            composer.setImage(image)
        }
        
        if let controller = SLTInternals.viewControllerforView(button) {
        
            // Called from a UIViewController
        composer.showFromViewController(controller) { result in
            if (result == .Cancelled) {
                print("Tweet composition cancelled")
            
                self.delegate?.providerDidCancel(self)
            }
            else {
                self.delegate?.provider(self, didCompleteWithResults: SLTShareResult(postID: ""))
            }
        }
    }
    }
}

struct SLTWhatsappShareProvider  : SLTShareProvider {

    weak var delegate : SLTShareProviderDelegate?
    
    init(withDelegate delegate: SLTShareProviderDelegate?) {
        
        self.delegate = delegate
    }

    func share(text text:String) {
        
        if let url = NSURL(string: "whatsapp://send?text=" + text) {
            
            let application = UIApplication.sharedApplication()
            
            if application.canOpenURL(url) {
                
                application.openURL(url)
                
                delegate?.provider(self, didCompleteWithResults: SLTShareResult(postID: ""))
                
            } else {
                
                delegate?.provider(self, didFailWithError: NSError(code: SLTShareErrorCode.AppDoesntExist, userInfo: ["description" : "whatsapp doen't exist or the url is invalid"]))
            }
        }
        
    }
    
}

extension SLTWhatsappShareProvider {
    
    var name : String {
        
        return SLTInternals.whatsappProviderName
    }
}


struct SLTEmailShareProvider  : SLTShareProvider {

    weak var delegate : SLTShareProviderDelegate? {
        
        didSet {
            //Forwoard delegation
            emailShareProviderDelegateImpl.delegate = delegate
        }
    }
    
    var emailShareProviderDelegateImpl : SLTEmailShareProviderDelegateImpl!
    
    init(withDelegate delegate: SLTShareProviderDelegate?) {
        
        self.delegate = delegate
        emailShareProviderDelegateImpl = SLTEmailShareProviderDelegateImpl(emailShareProvider: self)
        emailShareProviderDelegateImpl.delegate = delegate
    }

    func share(button : UIView, title:String, url:NSURL) {
        let mailComposeViewController = configuredMailComposeViewController(title:title , url:url)
        
        if MFMailComposeViewController.canSendMail() {
        
            if let controller = SLTInternals.viewControllerforView(button) {
                
                controller.presentViewController(mailComposeViewController, animated: true, completion: nil)
            }
            
        } else {
            
            delegate?.provider(self, didFailWithError: NSError(code: SLTShareErrorCode.EmailNotAvailable, userInfo: ["description":"email service not available"]))
        }
    }
    
    func configuredMailComposeViewController(title title:String , url : NSURL) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self.emailShareProviderDelegateImpl
        
        mailComposerVC.setSubject("قرأت هذا في نجم")
        
        var body = title
        body += "\n"
        body += "\(url)"
        body += "\n"
        body += "يمكنك تحميل نجم من خلال الرابط التالي"
        
        mailComposerVC.setMessageBody( body, isHTML: false)
        
        return mailComposerVC
    }
}


class SLTEmailShareProviderDelegateImpl:NSObject, MFMailComposeViewControllerDelegate {
    
    weak var delegate : SLTShareProviderDelegate?
    var emailShareProvider : SLTEmailShareProvider

    override init() {
        
        self.emailShareProvider = SLTEmailShareProvider(withDelegate: nil)
        super.init()
        fatalError("you cannot init FBSDKSharingDelegateImpl without Mail share provider use init:delegate instead")
    }
    
    init(emailShareProvider:SLTEmailShareProvider) {
        
        self.emailShareProvider = emailShareProvider
        super.init()
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResultCancelled.rawValue:
      
            delegate?.providerDidCancel(emailShareProvider)
        
        case MFMailComposeResultSaved.rawValue:
        
            delegate?.provider(emailShareProvider, didCompleteWithResults: SLTShareResult(postID: ""))
        
        case MFMailComposeResultSent.rawValue:
        
            delegate?.provider(emailShareProvider, didCompleteWithResults: SLTShareResult(postID: ""))
        
        case MFMailComposeResultFailed.rawValue:
            if let e = error {
                delegate?.provider(emailShareProvider, didFailWithError: e)
            }
            
        default:
            if let e = error {
                delegate?.provider(emailShareProvider, didFailWithError: e)
            }
        }
    }
}

extension SLTEmailShareProvider {
    
    var name : String {
        
        return SLTInternals.emailProviderName
    }
}
