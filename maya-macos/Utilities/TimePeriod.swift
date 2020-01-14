//
//  TimePeriod.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

enum TimeUnit: String, CaseIterable, Codable {
    case seconds, minutes, hours, days
}

struct TimePeriod: Codable, CustomStringConvertible {
    // Note: Changing these properties will invalidate User Defaults setting
    let value: Int
    let unit: TimeUnit
    // end Note
    
    var timeInterval: TimeInterval {
        switch unit {
        case .seconds: return TimeInterval(value)
        case .minutes: return TimeInterval(value * 60)
        case .hours: return TimeInterval(value * 60 * 60)
        case .days: return TimeInterval(value * 60 * 60 * 24)
        }
    }
    
    var description: String { "\(value) \(unit)" }
    
    init(value: Int, unit: TimeUnit) {
        self.value = value
        self.unit = unit
    }
    
    static func seconds(_ val: Int) -> TimePeriod {
        return TimePeriod(value: val, unit: .seconds)
    }
    
    static func minutes(_ val: Int) -> TimePeriod {
        return TimePeriod(value: val, unit: .minutes)
    }
    
    static func hours(_ val: Int) -> TimePeriod {
        return TimePeriod(value: val, unit: .hours)
    }
    
    static func days(_ val: Int) -> TimePeriod {
        return TimePeriod(value: val, unit: .days)
    }
}
