//
//  Task+extension.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 21.06.22.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
    
}
