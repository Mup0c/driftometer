//
//  ViewController.swift
//  speedometer
//
//  Created by Admin on 23.04.2018.
//  Copyright © 2018 fefu. All rights reserved.
//

import UIKit
import CoreLocation
import HCKalmanFilter

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let manager = CLLocationManager()
    //var timer = Timer()
    var hcKalmanFilter: HCKalmanAlgorithm?
    var resetKalmanFilter: Bool = false

    var latestHead = -1.0
    var curHead = -1.0
    var pastHead = -1.0
    var curCourse = -1.0
    var pastCourse = -1.0
    var notLatestHead = -1.0
    
    //MARK: Label
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var HeadMid: UILabel!
    @IBOutlet weak var CourseMid: UILabel!
    @IBOutlet weak var HeadCur: UILabel!
    @IBOutlet weak var CourseCur: UILabel!
    @IBOutlet weak var HeadPast: UILabel!
    @IBOutlet weak var CoursePast: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        latestHead = newHeading.trueHeading
        print(String(format: "%.2f",latestHead) + " upd")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        //var date = String(format: "%.2f",locations[0].timestamp.description)
        //let range = date.startIndex..<date.index(date.startIndex, offsetBy: 14)
        //date.removeSubrange(range)
        let myLocation: CLLocation = locations.first!
        
        if hcKalmanFilter == nil {
            self.hcKalmanFilter = HCKalmanAlgorithm(initialLocation: myLocation)
        }
        else {
            if let hcKalmanFilter = self.hcKalmanFilter {
                if resetKalmanFilter == true {
                    hcKalmanFilter.resetKalman(newStartLocation: myLocation)
                    resetKalmanFilter = false
                }
                else {
                    let kalmanLocation = hcKalmanFilter.processState(currentLocation: myLocation)
                    print(kalmanLocation.coordinate)
                }
            }
        }
        
        let data = String(format: "%.2f", max(locations[0].speed * 3.6, 0)) + " km/h"
        speedLabel.text = data
        pastHead = curHead
        pastCourse = curCourse
        curHead = notLatestHead
        notLatestHead = latestHead
        curCourse = locations[0].course
        if (pastCourse < 0) || (pastCourse < 0) || (curHead < 0) || (curCourse < 0){
            HeadMid.text = "  Invalid"
            CourseMid.text = "Data  "
        }
        else
        {
            var corrector = (abs(pastCourse - curCourse) > 180) ? 180.0: 0.0
            let courseMid = ((pastCourse + curCourse) / 2 + corrector).truncatingRemainder(dividingBy: 360)
            corrector = (abs(pastHead - curHead) > 180) ? 180.0: 0.0
            let headMid = ((pastHead + curHead) / 2 + corrector).truncatingRemainder(dividingBy: 360)
            HeadMid.text = String(format: "%.2f",headMid) + " mHd"
            CourseMid.text = String(format: "%.2f",courseMid) + "mCrs"
            let angle = abs(headMid - courseMid)
            angleLabel.text = String(format: "%.1f", angle > 180.0 ? angle - 360: angle) + " DORIFTO"
        }
        HeadCur.text = String(format: "%.2f", curHead) + " cHd"
        CourseCur.text = String(format: "%.2f", curCourse) + " cCrs"
        HeadPast.text = String(format: "%.2f", pastHead) + " pHd"
        CoursePast.text = String(format: "%.2f",pastCourse) + " pCrs"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(counter), userInfo: nil, repeats: true)
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    /*@objc func counter()
    {
        manager.startUpdatingLocation()
        manager.stopUpdatingLocation()
    }*/


}

