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
    
//    var timeInterval: TimeInterval {
//        switch self {
//        case .seconds(let val): return TimeInterval(val)
//        case .minutes(let val): return TimeInterval(val * 60)
//        case .hours(let val): return TimeInterval(val * 60 * 60)
//        case .days(let val): return TimeInterval(val * 60 * 60 * 24)
//        }
//    }
}

class TimePeriod: NSObject, Codable {
    let value: Int
    let unit: TimeUnit
    
    var timeInterval: TimeInterval {
        switch unit {
        case .seconds: return TimeInterval(value)
        case .minutes: return TimeInterval(value * 60)
        case .hours: return TimeInterval(value * 60 * 60)
        case .days: return TimeInterval(value * 60 * 60 * 24)
        }
    }
    
    override var description: String { "\(value) \(unit)" }
    
    init(value: Int, unit: TimeUnit) {
        self.value = value
        self.unit = unit
        super.init()
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
