//
//  IAPUtilities.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/26/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Foundation

private let defaultKey = "asd0fn20398rn23asdsfdgy9asdfj3pqeo39mnd"

func iapEncrypt(text: String) -> [UInt8] {
    let uuid = getSystemUUID() ?? defaultKey

    var encrypted = [UInt8]()
    let serialBuf = [UInt8](uuid.utf8)
    let dataBuf = [UInt8](text.utf8)

    for n in dataBuf.enumerated() {
        encrypted.append(n.element ^ serialBuf[n.offset % serialBuf.count])
    }

    return encrypted
}

func iapDecrypt(encrypted: [UInt8]) -> String? {
    let uuid = getSystemUUID() ?? defaultKey

    let serialBuf = [UInt8](uuid.utf8)
    var decrypted = [UInt8]()

    for n in encrypted.enumerated() {
        decrypted.append(n.element ^ serialBuf[n.offset % serialBuf.count])
    }

    return String(bytes: decrypted, encoding: .utf8)
}

private func getSystemUUID() -> String? {
    let dev = IOServiceMatching("IOPlatformExpertDevice")
    let platform: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
    let serialNumberObject = IORegistryEntryCreateCFProperty(platform, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
    IOObjectRelease(platform)

    let ser: CFTypeRef = serialNumberObject?.takeUnretainedValue() as CFTypeRef

    guard let result = ser as? String  else {
        log.error("Failed to get system UUID")
        return nil
    }

    return result
}
