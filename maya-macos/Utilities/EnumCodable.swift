//
//  EnumCodable.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

//import Foundation

protocol PListCodable: Codable, RawRepresentable where RawValue: Codable {
}

enum EnumCodingKeys: CodingKey {
    case value
}

extension PListCodable {
    init(from: Decoder) throws {
        let container = try from.container(keyedBy: EnumCodingKeys.self)
        let rawValue = try container.decode(RawValue.self, forKey: .value)
        guard let val = Self(rawValue: rawValue) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: [EnumCodingKeys.value], debugDescription: "Invalid enum value: \(rawValue)"))
        }
        self = val
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EnumCodingKeys.self)
        try container.encode(self.rawValue, forKey: .value)
    }
}
