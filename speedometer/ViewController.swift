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

struct locationAndHeading {
    var location: CLLocation
    var heading: CLHeading
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let clock = 0.2
    
    let manager = CLLocationManager()
    var recordClock = Timer()
    var measureClock = Timer()
    var isRecording = false
    var isMeasuring = false
    var hcKalmanFilter: HCKalmanAlgorithm?
    var resetKalmanFilter: Bool = false

    var route: [locationAndHeading] = []
    var latestGPSLocation: CLLocation?
    var latestKFLocation: CLLocation?
    var latestHead: CLHeading?
    
    var maxDist = 0.0
    
    var maxSpeed = 0.0
    
    
    /* var curHead = -1.0
    var pastHead = -1.0
    var curCourse = -1.0
    var pastCourse = -1.0
    var notLatestHead = -1.0 */
    
    //MARK: Label
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var CourseMid: UILabel!
    @IBOutlet weak var HeadCur: UILabel!
    @IBOutlet weak var CourseCur: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var measure: UIButton!
    
    
    @IBAction func recordButtonClick(_ sender: UIButton) {
        if !isRecording {
            maxSpeed = 0.0
            resetKalmanFilter = true
            record.setTitle("Stop Recording", for: .normal)
            isRecording = true
            print("Started recording")
            recordClock = Timer.scheduledTimer(timeInterval: clock, target: self, selector: #selector(recording), userInfo: nil, repeats: true)
            measure.isEnabled = false
        } else {
            record.setTitle("Start Recording", for: .normal)
            isRecording = false
            print("Stopped recording")
            recordClock.invalidate()
            measure.isEnabled = true
        }
    }

    @IBAction func measureButtonClick(_ sender: UIButton) {
        if !isMeasuring {
            maxSpeed = 0.0
            resetKalmanFilter = true
            measure.setTitle("Stop Measuring", for: .normal)
            isMeasuring = true
            print("Started measuring")
            measureClock = Timer.scheduledTimer(timeInterval: clock, target: self, selector: #selector(measuring), userInfo: nil, repeats: true)
            record.isEnabled = false
        } else {
            measure.setTitle("Start Measuring", for: .normal)
            isMeasuring = false
            print("Stopped measuring")
            measureClock.invalidate()
            record.isEnabled = true
        }
    }
    
    @objc func recording()
    {
       // print(hcKalmanFilter!.returnPredicted().coordinate.latitude,",", hcKalmanFilter!.returnPredicted().coordinate.longitude, ",PRD,", "Cyan")
        if hcKalmanFilter == nil {
            self.hcKalmanFilter = HCKalmanAlgorithm(initialLocation: latestGPSLocation!)
            hcKalmanFilter!.rValue = 1
        } else {
            if let hcKalmanFilter = self.hcKalmanFilter {
                if resetKalmanFilter == true {
                    hcKalmanFilter.resetKalman(newStartLocation: latestGPSLocation!)
                    resetKalmanFilter = false
                    print("Resetted KF")
                }
                else {
                    let GPSforKF = CLLocation(coordinate: latestGPSLocation!.coordinate, altitude: latestGPSLocation!.altitude, horizontalAccuracy: latestGPSLocation!.horizontalAccuracy, verticalAccuracy: latestGPSLocation!.verticalAccuracy, timestamp: NSDate() as Date)
                    latestKFLocation = hcKalmanFilter.processState(currentLocation: GPSforKF)
                    
                    print("record")
                    
                    //route.append(locationAndHeading(location: latestKFLocation!, heading: latestHead!))
                    //print(String(latestHead!.trueHeading))
                    //maxDist = max(maxDist, latestKFLocation!.distance(from: latestGPSLocation!))
                    //print(maxDist)
                    print(latestKFLocation!.distance(from: latestGPSLocation!))
                    print(latestKFLocation!.coordinate.latitude,",", latestKFLocation!.coordinate.longitude, ",KF,", "Blue")
                    print(latestGPSLocation!.coordinate.latitude,",", latestGPSLocation!.coordinate.longitude, ",GPS,", "Red")
                    
                    //print(route.last!)
                }
            }
        }
    }
    
    @objc func measuring()
    {
        print("measure")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        latestHead = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        //var date = String(format: "%.2f",locations[0].timestamp.description)
        //let range = date.startIndex..<date.index(date.startIndex, offsetBy: 14)
        //date.removeSubrange(range)


        latestGPSLocation = locations.first!
        maxSpeed = max(locations.first!.speed * 3.6, maxSpeed)
        let data = String(format: "%.2f", max(locations.first!.speed * 3.6, 0)) + " km/h"
        speedLabel.text = data
        maxSpeedLabel.text = "Max speed: " + String(format: "%.2f", maxSpeed) + " km/h"
        
        
       
        

        
        
      /*  pastHead = curHead
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
        CourseCur.text = String(format: "%.2f", curCourse) + " cCrs" */
    }
 
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }


}

