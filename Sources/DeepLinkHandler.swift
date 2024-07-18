//
//  DeepLinkHandler.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 28/04/2022.
//

import Foundation

public protocol DeepLinkHandling {
    @discardableResult
    func handle(deepLink url: URL) -> Bool
}

public final class DeepLinkHandler: DeepLinkHandling {
    @discardableResult
    public func handle(deepLink url: URL) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }

        let host = url.host ?? ""

        // MARK: Exclusive handler

        if excludedSchemes.contains(scheme) || excludedHosts.contains(host) {
            return false
        }

        // MARK: Blacklist handler

        if !blacklistSchemes.isEmpty, blacklistSchemes.contains(scheme) {
            return performForbiddenHandler(url: url)
        }

        if !blacklistHosts.isEmpty, blacklistHosts.contains(host) {
            return performForbiddenHandler(url: url)
        }

        // MARK: Whitelist handler

        if !whitelistSchemes.isEmpty, !whitelistSchemes.contains(scheme) {
            return performForbiddenHandler(url: url)
        }

        if !whitelistHosts.isEmpty, !whitelistHosts.contains(host) {
            return performForbiddenHandler(url: url)
        }

        // MARK: Enqueue handler

        guard !pendingDeepLinks.contains(url) else {
            #if DEBUG
                print("⚠️ Deep link is already in queue: \(url)")
            #endif
            return true
        }
        pendingDeepLinks.append(url)
        return true
    }

    init(plugins: [DeepLinkHandlerPlugin],
         barriers: [String: DeepLinkHandlingBarrier],
         mandatoryBarrier: MandatoryBarrier?,
         notFoundHandler: ((URL) -> Void)?,
         forbiddenHandler: ((URL) -> Void)?) {
        self.plugins = plugins
        self.barriers = barriers
        self.mandatoryBarrier = mandatoryBarrier
        self.notFoundHandler = notFoundHandler
        self.forbiddenHandler = forbiddenHandler
    }

    var plugins: [DeepLinkHandlerPlugin]
    var barriers: [String: DeepLinkHandlingBarrier]
    var mandatoryBarrier: MandatoryBarrier?

    var notFoundHandler: ((URL) -> Void)?
    var forbiddenHandler: ((URL) -> Void)?

    var whitelistSchemes: Set<String> = []
    var whitelistHosts: Set<String> = []

    var blacklistSchemes: Set<String> = []
    var blacklistHosts: Set<String> = []

    var excludedHosts: Set<String> = []
    var excludedSchemes: Set<String> = []

    private(set) var pendingDeepLinks: [URL] = [] {
        didSet { run() }
    }

    private(set) var processingDeepLink: URL?
    private var timer: Timer?

    func run() {
        guard processingDeepLink == nil else {
            #if DEBUG
                print("⚠️ A deep link is processing...")
            #endif
            return
        }
        guard let firstLink = pendingDeepLinks.first else {
            #if DEBUG
                print("✅ All deep links completed")
            #endif
            return
        }
        processingDeepLink = firstLink

        let candidates: [(plugin: DeepLinkHandlerPlugin, option: DeepLinkHandlerOption)] = plugins.compactMap { plugin in
            let option = plugin.shouldHandleDeepLink(firstLink)
            switch option {
            case .no:
                return nil
            case .yes, .yesWithBarrier:
                return (plugin, option)
            }
        }

        if let candidate = candidates.first {
            if candidates.count > 1 {
                print("⚠️ Multiple plugins registered handling the deep link: \(firstLink). Only the first plugin will be performed.")
            }

            let plugin = candidate.plugin
            let option = candidate.option

            switch option {
            case let .yes(data):
                performWithMandatoryBarrier(plugin: plugin, data: data, for: firstLink)
            case let .yesWithBarrier(name, data):
                guard let barrier = barriers[name] else {
                    #if DEBUG
                        print("⚠️ The barrier named `\(name)` not found")
                    #endif
                    performWithMandatoryBarrier(plugin: plugin, data: data, for: firstLink)
                    return
                }
                performWithCompoundBarrier(plugin: plugin, data: data, barrier: barrier, for: firstLink)
            case .no:
                break // Filtered by compactMap. Do nothing here.
            }
        } else {
            handleNotFound(deepLink: firstLink)
        }
    }

    private func perform(plugin: DeepLinkHandlerPlugin, data: Data?, barrier: DeepLinkHandlingBarrier, for deepLink: URL) {
        if barrier.status(for: deepLink) == .passed {
            self.plugin(plugin, handle: data)
        } else {
            performCheck(barrier, deepLink: deepLink, plugin: plugin, with: data)
        }
    }

    private func performWithMandatoryBarrier(plugin: DeepLinkHandlerPlugin, data: Data?, for deepLink: URL) {
        guard let barrier = mandatoryBarrier(for: deepLink) else {
            self.plugin(plugin, handle: data)
            return
        }
        perform(plugin: plugin, data: data, barrier: barrier, for: deepLink)
    }

    private func performWithCompoundBarrier(plugin: DeepLinkHandlerPlugin, data: Data?, barrier: DeepLinkHandlingBarrier, for deepLink: URL) {
        if let mandatoryBarrier = mandatoryBarrier(for: deepLink) {
            if mandatoryBarrier.name != barrier.name {
                let compoundBarrier = DeepLinkHandlingCompoundBarrier(firstBarrier: mandatoryBarrier, secondBarrier: barrier)
                perform(plugin: plugin, data: data, barrier: compoundBarrier, for: deepLink)
            } else {
                #if DEBUG
                    print("⚠️ The barrier named `\(barrier.name)` conflicts with `mandatoryBarrier`. The `mandatoryBarrier` will be performed!")
                #endif
                perform(plugin: plugin, data: data, barrier: mandatoryBarrier, for: deepLink)
            }
        } else {
            perform(plugin: plugin, data: data, barrier: barrier, for: deepLink)
        }
    }
}

private extension DeepLinkHandler {
    func performCheck(_ barrier: DeepLinkHandlingBarrier, deepLink: URL, plugin: DeepLinkHandlerPlugin, with data: Data?) {
        barrier.performCheck(deepLink: deepLink) { [weak self] isSuccess in
            if isSuccess {
                self?.plugin(plugin, handle: data)
            } else {
                #if DEBUG
                    print("‼️ Deep Link Validation failed")
                #endif
                self?.finishProcessing()
            }
        }
    }

    func mandatoryBarrier(for deepLink: URL) -> DeepLinkHandlingBarrier? {
        guard let barrierHolder = mandatoryBarrier, barrierHolder.condition(deepLink) else {
            return nil
        }
        return barrierHolder.barrier
    }

    func plugin(_ plugin: DeepLinkHandlerPlugin, handle data: Data?) {
        var isContextReady = false
        plugin.handleDeepLink(with: data) { [unowned self] in
            isContextReady = true
            finishProcessing()
        }
        if !isContextReady {
            timer = Timer.scheduledTimer(withTimeInterval: plugin.completionTimeout, repeats: false, block: { [weak self] _ in
                self?.finishProcessing()
            })
        }
    }

    func handleNotFound(deepLink: URL) {
        notFoundHandler?(deepLink)
        finishProcessing()
    }

    func finishProcessing() {
        let doneLink = processingDeepLink
        processingDeepLink = nil
        timer?.invalidate()
        pendingDeepLinks.removeAll { $0 == doneLink }
    }

    func performForbiddenHandler(url: URL) -> Bool {
        if let forbiddenHandler {
            forbiddenHandler(url)
        }
        return true
    }
}

struct MandatoryBarrier {
    let barrier: DeepLinkHandlingBarrier
    let condition: (URL) -> Bool
}
