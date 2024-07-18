//
//  URLExtensions.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 19/05/2022.
//

import Foundation

public extension URL {
    var deepLinkExtensions: URLExtensions {
        URLExtensions(url: self)
    }
}

public struct URLExtensions {
    let url: URL

    public var queryParameters: [String: Any]? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            queryItems.reduce(into: [:]) { partialResult, item in
                partialResult[item.name] = item.value
            }
        } else {
            nil
        }
    }

    public var queryData: Data? {
        guard let dictionary = queryParameters else { return nil }
        return try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }

    public var pathComponents: [String] {
        url.pathComponents.filter { $0 != "/" }
    }
}
