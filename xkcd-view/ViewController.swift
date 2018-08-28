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
private var dictOfCurrentComicInfo: [String: Any] = ["":-1]
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
            DispatchQueue.global(qos: .default).async {
                if let json = self.urlStringToJSON(url: initialURL) as? [String: Any] {
                    dictOfCurrentComicInfo = json
                    DispatchQueue.main.async {
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
            leftArrow.isUserInteractionEnabled = false
            randomButton.isUserInteractionEnabled = false
            rightArrow.isUserInteractionEnabled = false
            saveButton.isUserInteractionEnabled = false
            getComicNumButton.isUserInteractionEnabled = false
            audioButton.isUserInteractionEnabled = false
            comicNumTextBox.isUserInteractionEnabled = false
        }
    }
    
    private func urlStringToJSON(url: String) -> Any? {
        if let address = URL(string: url) {
            if let data = try? Data(contentsOf: address, options: []) {
                do {
                    return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                } catch let myJSONError {
                    print(myJSONError)
                }
            }
        }
        return nil
    }
    
    private func displayAll() {
        if isConnected() == true {
            DispatchQueue.global(qos: .default).async {
                if let json = self.urlStringToJSON(url: URLtoRequestDataFrom) as? [String:Any] {
                    dictOfCurrentComicInfo = json
                    DispatchQueue.main.async {
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
            
            DispatchQueue.global(qos: .default).async {
                if let url = URL(string: imageURL) {
                    if let data = try? Data(contentsOf: url) {
                        comicImg = UIImage(data: data)!
                    }
                }
                
                DispatchQueue.main.async {
                    UIView.transition(with: self.comicImage, duration: 1, options: .transitionCrossDissolve, animations: { self.comicImage.image = comicImg }, completion: nil)
                }
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
    
    @IBAction private func previousPressed(_ sender: AnyObject) {
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
    
    @IBAction private func randomPressed(_ sender: AnyObject) {
        if isConnected() == true {
            let randomNum = randomInt(min: 1, max: maximumComicNumber)
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
    
    @IBAction private func nextPressed(_ sender: AnyObject) {
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
    
    @IBAction private func savePressed(_ sender: AnyObject) {
        var comicImg: UIImage?
        DispatchQueue.global(qos: .default).async {
            if let url = URL(string: imageURL) {
                if let data = try? Data(contentsOf: url) {
                    comicImg = UIImage(data: data)
                }
            }

            DispatchQueue.main.async {
                if let com = comicImg {
                    UIImageWriteToSavedPhotosAlbum(com, nil, nil, nil)
                }
            }
        }
    }
    
    @IBAction private func audioToggled(_ sender: AnyObject) {
        shouldPlaySound = !shouldPlaySound
        let alert = UIAlertController(title: "Audio toggled", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func getSpecificComicPressed(_ sender: AnyObject) {
        let textBoxText: String = comicNumTextBox.text!
        let textBoxAsInt = Int(textBoxText)
        
        if isConnected() == true {
            if (textBoxAsInt ?? -1) >= 1 && (textBoxAsInt ?? -1) <= maximumComicNumber {
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
    
    // Copied from: https://stackoverflow.com/a/39782859/1422794
    private func isConnected() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
    }
    
    private func impossibleRequest() {
        let alert = UIAlertController(title: "Invalid comic number", message: "Request is not in bounds: 1 - \(maximumComicNumber)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func notConnected() {
        let alert = UIAlertController(title: "Network unavailable", message: "You do not currently have a connection.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { alertAction in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    private func playSound() {
        let path = Bundle.main.path(forResource: "button-31.wav", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            soundEffect = sound
            sound.play()
        } catch {
            print("Audio error!")
        }
    }
    
    // property to set the status bar light
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func textFieldShouldReturn(textBox: UITextField) -> Bool { // function called when user hits return on keyboard
        textBox.resignFirstResponder() // get rid of the keyboard
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // function called when user touches screen outside of keyboard
        self.view.endEditing(true) // resigns the keyboard after touching outside of keyboard
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
