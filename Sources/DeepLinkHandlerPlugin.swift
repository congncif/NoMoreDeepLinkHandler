//
//  DeepLinkHandlerPlugin.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 09/05/2022.
//

import Foundation

public protocol DeepLinkHandlerPlugin {
    var completionTimeout: TimeInterval { get }

    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void)
}

public protocol DeepLinkHandlerPathMatchingPlugin: DeepLinkHandlerPlugin {
    var matchingPath: String { get }
    var barrier: String? { get }
}

public extension DeepLinkHandlerPathMatchingPlugin {
    var barrier: String? { nil }

    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption {
        let matchingComponents = matchingPath.components(separatedBy: "/").filter { !$0.isEmpty }
        let urlPathComponents = url.deepLinkExtensions.pathComponents

        guard matchingComponents.count == urlPathComponents.count else {
            return .no
        }

        var pathParameters: [String: String] = [:]

        for (index, component) in matchingComponents.enumerated() {
            let value = urlPathComponents[index]
            if component.hasPrefix("{"), component.hasSuffix("}") {
                let key = String(component.dropFirst().dropLast())
                pathParameters[key] = value
            } else {
                guard component == value else {
                    return .no
                }
            }
        }

        let parameters = (url.deepLinkExtensions.queryParameters ?? [:])
            .merging(pathParameters, uniquingKeysWith: { $1 })

        if let barrier {
            return .yesWithBarrier(name: barrier, dictionary: parameters)
        } else {
            return .yes(dictionary: parameters)
        }
    }
}

public protocol DeepLinkHandlerCodingPlugin: DeepLinkHandlerPlugin {
    associatedtype Parameters: Codable

    func shouldHandleCodingDeepLink(_ url: URL) -> DeepLinkHandlerCodingOption<Parameters>

    func handleCodingDeepLink(with parameters: Parameters, completion: @escaping () -> Void)
}

public extension DeepLinkHandlerCodingPlugin {
    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption {
        shouldHandleCodingDeepLink(url).rawOption
    }

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void) {
        let decoder = JSONDecoder()

        guard let data, let parameters = try? decoder.decode(Parameters.self, from: data) else {
            assertionFailure("⚠️ Coding data is invalid. Skip handling.")
            completion()
            return
        }

        handleCodingDeepLink(with: parameters, completion: completion)
    }
}

public extension DeepLinkHandlerPlugin {
    var completionTimeout: TimeInterval { 0.3 }
}
