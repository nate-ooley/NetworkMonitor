import Foundation

enum DeviceType: String, CaseIterable, Identifiable {
    case mac = "Mac"
    case iphone = "iPhone"
    case ipad = "iPad"
    case watch = "Apple Watch"
    case unknown = "Unknown"
    
    var id: String { self.rawValue }
}

//
//  DeviceType.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

