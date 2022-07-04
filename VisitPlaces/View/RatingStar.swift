//
//  RatingStar.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 24.06.22.
//

import SwiftUI

struct RatingStar: View {
    private static let MAX_RATING: Float = 5
    private static let COLOR = Color.orange
    
    let rating: Float
    private let fullCount: Int
    private let emptyCount: Int
    private let halfFullCount: Int
    
    init(rating: Float) {
        self.rating = rating
        fullCount = Int(rating)
        emptyCount = Int(Self.MAX_RATING - rating)
        halfFullCount = (Float(fullCount + emptyCount) < Self.MAX_RATING) ? 1 : 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<fullCount, id: \.self) { _ in
                self.fullStar
            }
            ForEach(0..<halfFullCount, id: \.self) { _ in
                self.halfFullStar
            }
            ForEach(0..<emptyCount, id: \.self) { _ in
                self.emptyStar
            }
        }
    }
    
    private var fullStar: some View {
        Image(systemName: "star.fill").foregroundColor(Self.COLOR)
    }
    
    private var halfFullStar: some View {
        Image(systemName: "star.lefthalf.fill").foregroundColor(Self.COLOR)
    }
    
    private var emptyStar: some View {
        Image(systemName: "star").foregroundColor(Self.COLOR)
    }
}
