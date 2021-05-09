//
//  ViewController.swift
//  Real time tracker
//
//  Created by khawar on 5/9/21.
//

import UIKit
import CoreLocation
import SocketIO

class ViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet weak var shareLocationLabel: UILabel!
    @IBOutlet weak var shareLocationSwitch: UISwitch!
    @IBOutlet weak var nicknameTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    
    var nickname = "" {
        didSet {
            shareLocationSwitch.isEnabled = !nickname.isEmpty
        }
    }
    
    var trackedUsers: [[String:AnyObject]] = []

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialValues()
        setupLocationManager()
        listenToEvents()
        tableView.delegate = self
        tableView.dataSource = self
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let trackedUser = sender as? [String:AnyObject], let mapVC = segue.destination as? MapViewController {
            mapVC.trackedUser = trackedUser
        }
    }
    
    // MARK: - Private methods
    
    private func setupInitialValues() {
        shareLocationSwitch.isOn = false
        shareLocationSwitch.isEnabled = false
        nicknameTextField.addTarget(self, action: #selector(textFieldDidChangeText(sender:)), for: .editingChanged)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = false
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    private func listenToEvents() {
        listenToConnectionChanges()
        listenToTrackedUsersListUpdate()
    }

    private func setupAppToInitialState() {
        navigationController?.popToRootViewController(animated: true)
        shareLocationSwitch.isOn = false
        shareLocationLabel.text = "Share location"
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Action methods

    @objc
    func textFieldDidChangeText(sender: UITextField) {
        if let nicknameString = sender.text {
            nickname = nicknameString
        }
    }
    
    @IBAction
    func shareLocationSwitchAction(_ sender: UISwitch) {
        shareLocationLabel.text = sender.isOn ? "Stop sharing location" : "Share location"
        
        if sender.isOn {
            userStartedLocationSharing()
        }
        else {
            userStoppedLocationSharing()
        }
        nicknameTextField.resignFirstResponder()
    }
}

// MARK: - Socket functions

extension ViewController {

    //Send message to server that user is sharing location
    func userStartedLocationSharing() {
        LocationSocketManager.sharedInstance.userStartedLocationSharing(withNickname: nickname)
        self.locationManager.startUpdatingLocation()
    }
    
    //Send message to server that user stopped sharing location
    func userStoppedLocationSharing() {
        LocationSocketManager.sharedInstance.userStoppedLocationSharing()
        self.locationManager.stopUpdatingLocation()
    }
    
    func listenToConnectionChanges() {
        LocationSocketManager.sharedInstance.listenToConnectionChanges(onConnectHandler: {
            
            //if user was successfully connected to server we ask for a updated tracked user list
            LocationSocketManager.sharedInstance.checkForUpdatedTrackedUsersList()
            
        }, onDisconnectHandler: {
            
            //if user was disconnected from server we update the app interface
            self.setupAppToInitialState()
        })
    }
    
    //Listen to updates in tracked user list, whenever it is updated or when we request
    func listenToTrackedUsersListUpdate() {
        LocationSocketManager.sharedInstance.listenToTrackedUsersListUpdate() { trackedUsersListUpdate in
            if let listUpdate = trackedUsersListUpdate {
                self.trackedUsers = listUpdate
                self.tableView.reloadData()
            }
        }
    }
    
    //Send to server the current coordinates when sharing location
    func sendCoordinates(withLocation location: CLLocation) {
        LocationSocketManager.sharedInstance.sendCoordinates(withLatitude: String(location.coordinate.latitude), andLongitude: String(location.coordinate.longitude))
    }
    
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        sendCoordinates(withLocation: location)
    }
    
}

// MARK: - UITableViewDelegate and UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            if let trackerUserNickname = trackedUsers[indexPath.row]["nickname"] as? String {
                cell.textLabel?.text = trackerUserNickname
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trackedUser = trackedUsers[indexPath.row]
        
        performSegue(withIdentifier: "SegueToMapVC", sender: trackedUser)
    }
    
}


