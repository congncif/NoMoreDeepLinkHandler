//
//  DeepLinkHandlerConfiguration.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 27/05/2022.
//

import Foundation

public final class DeepLinkHandlerConfiguration {
    var plugins: [DeepLinkHandlerPlugin] = []
    var barriers: [String: DeepLinkHandlingBarrier] = [:]
    var mandatoryBarrier: MandatoryBarrier?

    var notFoundHandler: ((URL) -> Void)? = {
        #if DEBUG
            print("⚠️ The deep link \($0) is not found")
        #endif
    }

    var forbiddenHandler: ((URL) -> Void)? = {
        #if DEBUG
            print("⚠️ The deep link \($0) is forbidden")
        #endif
    }

    var whitelistSchemes: Set<String> = []
    var whitelistHosts: Set<String> = []

    var blacklistSchemes: Set<String> = []
    var blacklistHosts: Set<String> = []

    var excludedHosts: Set<String> = []
    var excludedSchemes: Set<String> = []

    public func set(whitelistSchemes: [String]) -> Self {
        self.whitelistSchemes = Set<String>(whitelistSchemes)
        return self
    }

    public func set(whitelistHosts: [String]) -> Self {
        self.whitelistHosts = Set<String>(whitelistHosts)
        return self
    }

    public func set(blacklistSchemes: [String]) -> Self {
        self.blacklistSchemes = Set<String>(blacklistSchemes)
        return self
    }

    public func set(blacklistHosts: [String]) -> Self {
        self.blacklistHosts = Set<String>(blacklistHosts)
        return self
    }

    public func set(excludedSchemes: [String]) -> Self {
        self.excludedSchemes = Set<String>(excludedSchemes)
        return self
    }

    public func set(excludedHosts: [String]) -> Self {
        self.excludedHosts = Set<String>(excludedHosts)
        return self
    }

    public func set(mandatoryBarrier: DeepLinkHandlingBarrier?, where condition: @escaping (URL) -> Bool = { _ in true }) -> Self {
        if let mandatoryBarrier {
            self.mandatoryBarrier = MandatoryBarrier(barrier: mandatoryBarrier, condition: condition)
        }
        return self
    }

    public func withNotFoundHandler(_ handler: ((URL) -> Void)?) -> Self {
        notFoundHandler = handler
        return self
    }

    public func withForbiddenHandler(_ handler: ((URL) -> Void)?) -> Self {
        forbiddenHandler = handler
        return self
    }

    public func install(plugin: DeepLinkHandlerPlugin) -> Self {
        plugins.append(plugin)
        return self
    }

    public func install(plugins: [DeepLinkHandlerPlugin]) -> Self {
        self.plugins.append(contentsOf: plugins)
        return self
    }

    public func install(barrier: DeepLinkHandlingBarrier) -> Self {
        barriers[barrier.name] = barrier
        return self
    }

    public func install(barriers: [DeepLinkHandlingBarrier]) -> Self {
        for barrier in barriers {
            self.barriers[barrier.name] = barrier
        }
        return self
    }

    public func initialize() {
        DeepLinkHandler.sharedHandler = instantiate()
    }

    public func instantiate() -> DeepLinkHandler {
        let handler = DeepLinkHandler(plugins: plugins,
                                      barriers: barriers,
                                      mandatoryBarrier: mandatoryBarrier,
                                      notFoundHandler: notFoundHandler,
                                      forbiddenHandler: forbiddenHandler)
        handler.excludedSchemes = excludedSchemes
        handler.excludedHosts = excludedHosts
        handler.whitelistSchemes = whitelistSchemes
        handler.whitelistHosts = whitelistHosts
        handler.blacklistSchemes = blacklistSchemes
        handler.blacklistHosts = blacklistHosts
        return handler
    }
}

public extension DeepLinkHandler {
    internal static var sharedHandler: DeepLinkHandler?

    static var shared: DeepLinkHandler {
        guard let handler = sharedHandler else {
            preconditionFailure("DeepLinkHandler must be initialized before use")
        }
        return handler
    }

    static func configure() -> DeepLinkHandlerConfiguration {
        DeepLinkHandlerConfiguration()
    }
}
