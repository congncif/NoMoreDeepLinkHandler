//
//  DeepLinkHandlingBarrier.swift
//  NoMoreDeepLinkHandler
//
//  Created by NGUYEN CHI CONG on 27/05/2022.
//

import Foundation

public enum DeepLinkBarrierStatus {
    case passed
    case needToCheck
}

public protocol DeepLinkHandlingBarrier {
    var name: String { get }

    func status(for deepLink: URL) -> DeepLinkBarrierStatus
    func performCheck(deepLink: URL, completion: @escaping (_ isSuccess: Bool) -> Void)
}

public extension DeepLinkHandlingBarrier {
    var name: String { String(describing: type(of: self)) }
}

struct DeepLinkHandlingCompoundBarrier: DeepLinkHandlingBarrier {
    let firstBarrier: DeepLinkHandlingBarrier
    let secondBarrier: DeepLinkHandlingBarrier

    func status(for deepLink: URL) -> DeepLinkBarrierStatus {
        if firstBarrier.status(for: deepLink) == .passed, secondBarrier.status(for: deepLink) == .passed {
            return .passed
        }
        return .needToCheck
    }

    func performCheck(deepLink: URL, completion: @escaping (Bool) -> Void) {
        switch firstBarrier.status(for: deepLink) {
        case .needToCheck:
            firstBarrier.performCheck(deepLink: deepLink) { isSuccess in
                if isSuccess {
                    switch secondBarrier.status(for: deepLink) {
                    case .passed:
                        completion(true)
                    case .needToCheck:
                        secondBarrier.performCheck(deepLink: deepLink, completion: completion)
                    }
                } else {
                    completion(isSuccess)
                }
            }
        case .passed:
            switch secondBarrier.status(for: deepLink) {
            case .passed:
                completion(true)
            case .needToCheck:
                secondBarrier.performCheck(deepLink: deepLink, completion: completion)
            }
        }
    }
}
