//
//  ViewController.swift
//  xkcd-view
//
//  Created by terry schmidt on 11/30/15.
//  Copyright © 2015 terry schmidt. All rights reserved.

import UIKit
import SystemConfiguration
import AVFoundation

private var maximumComicNumber = 0
private var counter = maximumComicNumber
private var URLtoRequestDataFrom = ""
private var comicTitle = ""
private var imageURL = ""
private var dictOfCurrentComicInfo: [String: AnyObject] = ["":-1]
private var shouldPlaySound = true
private var soundEffect: AVAudioPlayer!

// Terry Schmidt

final class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var comicNumTextBox: UITextField!
    @IBOutlet private weak var comicNumLabel: UILabel!
    @IBOutlet private weak var comicTitleLabel: UILabel!
    @IBOutlet private weak var comicDateLabel: UILabel!
    @IBOutlet private weak var comicImage: UIImageView!
    @IBOutlet private weak var leftArrow: UIButton!
    @IBOutlet private weak var randomButton: UIButton!
    @IBOutlet private weak var rightArrow: UIButton!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var getComicNumButton: UIButton!
    @IBOutlet private weak var audioButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.comicNumTextBox.delegate = self
        let initialURL = "http://xkcd.com/info.0.json";
        if isConnected() == true {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if let json = self.urlStringToJSON(initialURL) as? [String:AnyObject] {
                    dictOfCurrentComicInfo = json
                    dispatch_async(dispatch_get_main_queue()) {
                        if let num = dictOfCurrentComicInfo["num"] as? Int {
                            maximumComicNumber = num
                        }
                        self.displayNum()
                        self.displayTitle()
                        self.displayImage()
                        self.displayDate()
                    }
                }
            }
        } else {
           comicImage.image = UIImage(named: "noconnection.png")
           leftArrow.userInteractionEnabled = false
           randomButton.userInteractionEnabled = false
           rightArrow.userInteractionEnabled = false
           saveButton.userInteractionEnabled = false
           getComicNumButton.userInteractionEnabled = false
           audioButton.userInteractionEnabled = false
           comicNumTextBox.userInteractionEnabled = false
        }
    }
    
    private func urlStringToJSON(url: String) -> AnyObject? {
        if let address = NSURL(string: url) {
            if let data = try? NSData(contentsOfURL: address, options: []) {
                do {
                    return try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                } catch let myJSONError {
                    print(myJSONError)
                }
            }
        }
        return nil
    }
    
    private func displayAll() {
        if isConnected() == true {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if let json = self.urlStringToJSON(URLtoRequestDataFrom) as? [String:AnyObject] {
                    dictOfCurrentComicInfo = json
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayNum()
                        self.displayTitle()
                        self.displayImage()
                        self.displayDate()
                    }
                }
            }
        } else {
            notConnected()
        }
    }
    
    private func displayNum() {
        if let comicNum = dictOfCurrentComicInfo["num"] as? Int {
            comicNumLabel.text = "comic #: " + comicNum.description
        }
    }
    
    private func displayTitle() {
        if let title = dictOfCurrentComicInfo["title"] as? String {
            comicTitleLabel.text = title
        }
    }
    
    private func displayImage() {
        if let img = dictOfCurrentComicInfo["img"] as? String {
            imageURL = img
            var comicImg: UIImage?
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if let url = NSURL(string: imageURL) {
                    if let data = NSData(contentsOfURL: url) {
                        comicImg = UIImage(data: data)!
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIView.transitionWithView(self.comicImage, duration: 1, options: .TransitionCrossDissolve, animations: { self.comicImage.image = comicImg }, completion: nil)}
            }
        }
    }
    
    private func displayDate() {
        var day = ""; var month = ""; var year = "";
        if let dayNum = dictOfCurrentComicInfo["day"] as? String {
            if let monthNum = dictOfCurrentComicInfo["month"] as? String {
                if let yearNum = dictOfCurrentComicInfo["year"] as? String {
                    day = dayNum
                    month = monthNum
                    year = yearNum
                }
            }
        }
        
        comicDateLabel.text = month + "/" + day + "/" + year
    }
    
    @IBAction private func previousPressed(sender: AnyObject) {
        if isConnected() == true {
            if counter >= 2 && counter <= maximumComicNumber {
                counter -= 1
                if counter == 404 {
                    do404SpecificWork()
                    return;
                }
                URLtoRequestDataFrom = "http://xkcd.com/" + counter.description + "/info.0.json"
                if shouldPlaySound == true {
                    playSound()
                }
                displayAll()
            } else {
                impossibleRequest()
            }
        } else {
            notConnected()
        }
    }
    
    @IBAction private func randomPressed(sender: AnyObject) {
        if isConnected() == true {
            let randomNum = randomInt(1, max: maximumComicNumber)
            counter = randomNum
            if counter == 404 {
                do404SpecificWork()
                return;
            }
            URLtoRequestDataFrom = "http://xkcd.com/" + counter.description + "/info.0.json"
            if shouldPlaySound == true {
                playSound()
            }
            displayAll()
        } else {
            notConnected()
        }
    }
    
    @IBAction private func nextPressed(sender: AnyObject) {
        if isConnected() == true {
            if counter >= 1 && counter <= maximumComicNumber - 1 {
                counter += 1
                if counter == 404 {
                    do404SpecificWork()
                    return;
                }
                URLtoRequestDataFrom = "http://xkcd.com/" + counter.description + "/info.0.json"
                if shouldPlaySound == true {
                    playSound()
                }
                displayAll()
            } else {
                impossibleRequest()
            }
        } else {
            notConnected()
        }
    }

    // xkcd doesn't provide a comic #404.  I think it is a joke. (404 not found) :)
    private func do404SpecificWork() {
        comicNumLabel.text = "comic #: 404"
        comicDateLabel.text = "00/00/0000"
        comicTitleLabel.text = "404 Not Found :)"
        comicImage.image = nil
    }
    
    @IBAction private func savePressed(sender: AnyObject) {
        var comicImg: UIImage?
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let url = NSURL(string: imageURL) {
                if let data = NSData(contentsOfURL: url) {
                    comicImg = UIImage(data: data)
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                if let com = comicImg {
                    UIImageWriteToSavedPhotosAlbum(com, nil, nil, nil)
                }
            }
        }
    }
    
    @IBAction private func audioToggled(sender: AnyObject) {
        shouldPlaySound = !shouldPlaySound
        let alert = UIAlertController(title: "Audio toggled", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { alertAction in }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction private func getSpecificComicPressed(sender: AnyObject) {
        let textBoxText: String = comicNumTextBox.text!
        let textBoxAsInt = Int(textBoxText)
        
        if isConnected() == true {
            if textBoxAsInt >= 1 && textBoxAsInt <= maximumComicNumber {
                counter = textBoxAsInt!
                if counter == 404 {
                    do404SpecificWork()
                    return;
                }
                URLtoRequestDataFrom = "http://xkcd.com/" + counter.description + "/info.0.json"
                if shouldPlaySound == true {
                    playSound()
                }
                displayAll()
            } else {
                impossibleRequest()
            }
        } else {
            notConnected()
        }
    }
    
    private func isConnected() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0))
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .Reachable
        let needsConnection = flags == .ConnectionRequired
        
        return isReachable && !needsConnection
    }
    
    private func impossibleRequest() {
        let alert = UIAlertController(title: "Invalid comic number", message: "Request is not in bounds: 1 - \(maximumComicNumber)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { alertAction in }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func notConnected() {
        let alert = UIAlertController(title: "Network unavailable", message: "You do not currently have a connection.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { alertAction in }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    private func playSound() {
        let path = NSBundle.mainBundle().pathForResource("button-31.wav", ofType:nil)!
        let url = NSURL(fileURLWithPath: path)
        
        do {
            let sound = try AVAudioPlayer(contentsOfURL: url)
            soundEffect = sound
            sound.play()
        } catch {
            print("Audio error!")
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle { // function to set the status bar light
        return UIStatusBarStyle.LightContent
    }
    
    func textFieldShouldReturn(textBox: UITextField) -> Bool { // function called when user hits return on keyboard
        textBox.resignFirstResponder() // get rid of the keyboard
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) { // function called when user touches screen outside of keyboard
        self.view.endEditing(true) // resigns the keyboard after touching outside of keyboard
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}