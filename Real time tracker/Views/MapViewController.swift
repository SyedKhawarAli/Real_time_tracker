//
//  MapViewController.swift
//  Real time tracker
//
//  Created by BrainX Technologies on 5/9/21.
//

import Foundation
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    
    var trackedUser: [String:AnyObject]!
    
    var locationPin = MKPointAnnotation()
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTrackingUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTrackingUser()
    }
    
    // MARK: - Helpers
    
    func updateTrackedUserLocation(withLatitude latitude: Double, andLongitude longitude: Double) {
        locationPin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        mapView.addAnnotation(locationPin)
        
        let coordinateRegion = MKCoordinateRegion(center: locationPin.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK: - Socket functions
    
    func startTrackingUser() {
        if let trackedUserId = trackedUser["id"] as? String {
            LocationSocketManager.sharedInstance.userStartedTracking(trackedUserSocketId: trackedUserId, coordinatesUpdateHandler: { trackedUsersCoordinatesUpdate in
                
                if let latitudeString = trackedUsersCoordinatesUpdate?["latitude"] as? String, let longitudeString = trackedUsersCoordinatesUpdate?["longitude"] as? String, let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
                    self.updateTrackedUserLocation(withLatitude: latitude, andLongitude: longitude)
                }
                
            }, trackedUserStoppedTrackingHandler: { trackedUserNickname in
                
                if let nickname = trackedUserNickname {
                    let alert = UIAlertController(title: "Ops!", message: "\(nickname) has stopped sharing location", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: "Ok", style: .default) { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                    alert.addAction(okButton)
                    
                    self.present(alert, animated: true, completion: nil)
                }
                
            })
        }
    }
    
    func stopTrackingUser() {
        if let trackedUserId = trackedUser["id"] as? String {
            LocationSocketManager.sharedInstance.userStoppedTracking(trackedUserSocketId: trackedUserId)
        }
    }
    
}
