//
//  ViewController.swift
//  xkcd-view
//
//  Created by terry schmidt on 11/30/15.
//  Copyright © 2015 terry schmidt. All rights reserved.

import UIKit
import SystemConfiguration
import AVFoundation

var maximumComicNumber = 0
var counter = maximumComicNumber
var URLtoRequestDataFrom = ""
var comicTitle = ""
var imageURL: String = ""
var dictOfCurrentComicInfo: [String: AnyObject] = ["":-1]
var shouldPlaySound = true
var sound : AVAudioPlayer?

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var comicNumTextBox: UITextField!
    @IBOutlet weak var comicNumLabel: UILabel!
    @IBOutlet weak var comicTitleLabel: UILabel!
    @IBOutlet weak var comicDateLabel: UILabel!
    @IBOutlet weak var comicImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialURL = "http://xkcd.com/info.0.json";
        if isConnected() == true {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if let json = self.urlStringToJSON(initialURL) as? [String:AnyObject] {
                    dictOfCurrentComicInfo = json
                    if let comicNum = json["num"] as? Int {
                        maximumComicNumber = comicNum
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayNum()
                    self.displayTitle()
                    self.displayImage()
                    self.displayDate()
                }
            }
        } else {
            notConnected()
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
                }
            
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayNum()
                    self.displayTitle()
                    self.displayImage()
                    self.displayDate()
                }
            }
        } else {
            notConnected()
        }
    }
    
    private func displayNum () {
        if let comicNum = dictOfCurrentComicInfo["num"] as? Int {
            comicNumLabel.text = "comic #: " + comicNum.description
        }
    }
    
    private func displayTitle () {
        if let title = dictOfCurrentComicInfo["title"] as? String {
            comicTitleLabel.text = title
        }
    }
    
    private func displayImage () {
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
    
    private func displayDate () {
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
    
    
    @IBAction func previousPressed(sender: AnyObject) {
        if isConnected() == true {
            if counter >= 2 && counter <= maximumComicNumber {
                counter--
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
    
    
    @IBAction func randomPressed(sender: AnyObject) {
        if isConnected() == true {
            let randomNum = randomInt(1, max: maximumComicNumber)
            counter = randomNum
            URLtoRequestDataFrom = "http://xkcd.com/" + counter.description + "/info.0.json"
            if shouldPlaySound == true {
                playSound()
            }
            displayAll()
        } else {
            notConnected()
        }
    }
    
    
    @IBAction func nextPressed(sender: AnyObject) {
        if isConnected() == true {
            if counter >= 1 && counter <= maximumComicNumber - 1 {
                counter++
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
    
    
    @IBAction func savePressed(sender: AnyObject) {
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
    
    @IBAction func audioToggled(sender: AnyObject) {
        shouldPlaySound = !shouldPlaySound
        let alert = UIAlertController(title: "Audio toggled", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { alertAction in }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func getSpecificComicPressed(sender: AnyObject) {
        let textBoxText: String = comicNumTextBox.text!
        let textBoxAsInt = Int(textBoxText)
        
        if isConnected() == true {
            if textBoxAsInt >= 1 && textBoxAsInt <= maximumComicNumber {
                counter = textBoxAsInt!
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
        sound = setupAudioPlayerWithFile("button-31", type:"wav")
        sound?.play()
    }
    
    private func setupAudioPlayerWithFile(file: String, type: String) -> AVAudioPlayer? {
        let path = NSBundle.mainBundle().pathForResource(file, ofType: type)
        let url = NSURL.fileURLWithPath(path!)
        var audioPlayer:AVAudioPlayer?
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
        } catch {
            print("Audio error")
        }
        
        return audioPlayer
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