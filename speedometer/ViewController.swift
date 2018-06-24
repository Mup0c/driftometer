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
    
    let clock = 0.14
    
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
    
    //var maxDist = 0.0
    
    var maxSpeed = 0.0
    var speedSum = 0.0
    var speedCount = 0
    var maxAngle = 0.0
    var angleSum = 0.0
    var angleCount = 0
    
    
    /* var curHead = -1.0
    var pastHead = -1.0
    var curCourse = -1.0
    var pastCourse = -1.0
    var notLatestHead = -1.0 */
    
    //MARK: Label
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var maxAngleLabel: UILabel!
    @IBOutlet weak var AvgAngleLabel: UILabel!
    @IBOutlet weak var AvgSpeedLabel: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var measure: UIButton!
    
    
    @IBAction func recordButtonClick(_ sender: UIButton) {
        if !isRecording {
            reset_meters()
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
            reset_meters()
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
                    
                    route.append(locationAndHeading(location: latestKFLocation!, heading: latestHead!))
                    //maxDist = max(maxDist, latestKFLocation!.distance(from: latestGPSLocation!))
                    //print(maxDist)
                    print(latestKFLocation!.distance(from: latestGPSLocation!))
                    print(latestKFLocation!.coordinate.latitude,",", latestKFLocation!.coordinate.longitude,", "+String(latestHead!.trueHeading)+" KF,", "Blue")
                    print(latestGPSLocation!.coordinate.latitude,",", latestGPSLocation!.coordinate.longitude,", "+String(latestHead!.trueHeading)+" GPS,", "Red")
                    
                    print(route.last!)
                }
            }
        }
    }
    
    @objc func measuring()
    {
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
                    
                    print("measure")
                    var min_dist = 10.0
                    var curLocNHead: locationAndHeading?
                    for locAndHead in route {
                        let dist = latestKFLocation!.distance(from: locAndHead.location)
                        if dist < min_dist {
                            min_dist = dist
                            curLocNHead = locAndHead
                        }
                    }
                    if (min_dist == 10.0) {
                        angleLabel.text = "Deviation ≥ 10m"
                    } else {
                        var angle = abs(curLocNHead!.heading.trueHeading - latestHead!.trueHeading)
                        angle = angle > 180.0 ? angle - 180: angle
                        print("-----Angle: ", angle)
                        if angle < 2.5 {
                            angle = 0.0
                        } else {
                            angleSum += angle
                            angleCount += 1
                        }
                        let text = String(format: "%.1f", angleSum / Double(angleCount)) + "°"
                        AvgAngleLabel.text = text
                        angleLabel.text = String(format: "%.1f", angle > 180.0 ? angle - 180: angle) + "° DORIFTO"
                    }
                    //print(String(latestHead!.trueHeading))
                    //maxDist = max(maxDist, latestKFLocation!.distance(from: latestGPSLocation!))
                    //print(maxDist)
                    print(latestKFLocation!.distance(from: curLocNHead!.location))
                    print(latestKFLocation!.coordinate.latitude,",", latestKFLocation!.coordinate.longitude, ",KF,", "Blue")
                    print(latestGPSLocation!.coordinate.latitude,",", latestGPSLocation!.coordinate.longitude, ",GPS,", "Red")
                    
                    print("curLocNHead: ", curLocNHead!)
                }
            }
        }
    }
    
    func reset_meters()
    {
        maxSpeed = 0.0
        speedSum = 0.0
        speedCount = 0
        maxAngle = 0.0
        angleSum = 0.0
        angleCount = 0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        latestHead = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        latestGPSLocation = locations.first!
        speedSum += max(locations.first!.speed, 0)
        speedCount += 1
        maxSpeed = max(locations.first!.speed * 3.6, maxSpeed)
        var data = String(format: "%.2f", max(locations.first!.speed * 3.6, 0)) + " km/h"
        speedLabel.text = data
        data = String(format: "%.2f", (speedSum / Double(speedCount)) * 3.6) + " km/h"
        AvgSpeedLabel.text = data
        maxSpeedLabel.text = "Max speed: " + String(format: "%.2f", maxSpeed) + " km/h"
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

