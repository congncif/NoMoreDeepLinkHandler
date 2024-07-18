//
//  DeepLinkHandlerOption.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 09/05/2022.
//

import Foundation

public enum DeepLinkHandlerOption {
    case yes(data: Data?)
    case yesWithBarrier(name: String, data: Data?)
    case no

    public static func yes(dictionary: [String: Any]?) -> Self {
        if let json = dictionary {
            let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return .yes(data: data)
        }
        return .yes(data: nil)
    }

    public static func yesWithBarrier(name: String, dictionary: [String: Any]?) -> Self {
        if let json = dictionary {
            let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return .yesWithBarrier(name: name, data: data)
        }
        return .yesWithBarrier(name: name, data: nil)
    }

    public static func yesWithBarrier(_ barrierType: (some DeepLinkHandlingBarrier).Type, dictionary: [String: Any]?) -> Self {
        .yesWithBarrier(name: String(describing: barrierType), dictionary: dictionary)
    }

    public static func yesWithBarrier(_ barrierType: (some DeepLinkHandlingBarrier).Type, data: Data?) -> Self {
        .yesWithBarrier(name: String(describing: barrierType), data: data)
    }
}

public enum DeepLinkHandlerCodingOption<Parameters> where Parameters: Codable {
    case yes(parameters: Parameters)
    case yesWithBarrier(name: String, parameters: Parameters)
    case no

    public static func yesWithBarrier(_ barrierType: (some DeepLinkHandlingBarrier).Type, parameters: Parameters) -> Self {
        .yesWithBarrier(name: String(describing: barrierType), parameters: parameters)
    }

    public var rawOption: DeepLinkHandlerOption {
        switch self {
        case .no:
            return .no
        case let .yes(parameters: parameters):
            let encoder = JSONEncoder()
            let data = try? encoder.encode(parameters)
            return .yes(data: data)
        case let .yesWithBarrier(name: name, parameters: parameters):
            let encoder = JSONEncoder()
            let data = try? encoder.encode(parameters)
            return .yesWithBarrier(name: name, data: data)
        }
    }
}
