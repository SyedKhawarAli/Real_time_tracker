//
//  LocationSocketManager.swift
//  Real time tracker
//
//  Created by BrainX Technologies on 5/9/21.
//

import Foundation
import SocketIO

class LocationSocketManager: NSObject {

    static let sharedInstance = LocationSocketManager()

    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    var connectionStatus: SocketIOStatus {
        return socket.status
    }
    
    // MARK: - Constructor
    
    override init() {
        super.init()
        self.manager = SocketManager(socketURL: URL(string: "https://tranquil-dawn-44938.herokuapp.com/")!, config: [.log(true)])
        self.socket = manager.defaultSocket
    }

    // MARK: - Socket connection
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func listenToConnectionChanges(onConnectHandler: @escaping ()->Void, onDisconnectHandler: @escaping ()->Void) {
        socket.on(clientEvent: .connect) {  ( dataArray, ack) -> Void in
            onConnectHandler()
        }
        
        socket.on(clientEvent: .disconnect) {  ( dataArray, ack) -> Void in
            onDisconnectHandler()
        }
    }
    
    // MARK: - Location sharing messages
    
    func userStartedLocationSharing(withNickname nickname: String) {
        socket.emit("connectTrackedUser", nickname)
    }
    
    func userStoppedLocationSharing() {
        socket.emit("disconnectTrackedUser")
    }
    
    func sendCoordinates(withLatitude latitude: String, andLongitude longitude: String) {
        socket.emit("trackedUserCoordinates", latitude, longitude)
    }

    // MARK: - Location tracking messages
    
    func userStartedTracking(trackedUserSocketId: String, coordinatesUpdateHandler: @escaping (_ trackedUserCoordinatesUpdate: [String: AnyObject]?) -> Void, trackedUserStoppedTrackingHandler: @escaping (_ nicknameData: String?) -> Void) {
        socket.emit("connectTrackedUserTracker", trackedUserSocketId)
        
        //Listen to tracked user coordinates update
        socket.on("trackedUserCoordinatesUpdate") { ( dataArray, ack) -> Void in
            coordinatesUpdateHandler(dataArray[0] as? [String: AnyObject])
        }
        
        //Listen to whenever tracked user stops sharing location
        socket.on("trackedUserHasStoppedUpdate") { ( dataArray, ack) -> Void in
            trackedUserStoppedTrackingHandler(dataArray[0] as? String)
        }
    }
    
    //Let server know that a user stopped tracking a sharing location user
    func userStoppedTracking(trackedUserSocketId: String) {
        socket.emit("disconnectTrackedUserTracker", trackedUserSocketId)
    }
    
    // MARK: - Tracked users list monitoring
    
    //Send to server a message requesting the updated tracked users list
    func checkForUpdatedTrackedUsersList() {
        socket.emit("requestUpdatedTrackedUsersList")
    }
    
    //Listen to updated in the tracked users list
    func listenToTrackedUsersListUpdate(completionHandler: @escaping (_ trackedUsersListUpdate: [[String: AnyObject]]?) -> Void) {
        socket.on("trackedUsersListUpdate") { ( dataArray, ack) -> Void in
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
    }
}
