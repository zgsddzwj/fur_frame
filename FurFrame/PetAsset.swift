//
//  PetAsset.swift
//  FurFrame
//
//  Created by Adward on 2026/3/14.
//

import Foundation
import SwiftData

@Model
final class PetAsset {
    @Attribute(.unique) var localIdentifier: String
    var isFavorite: Bool
    var isHero: Bool
    var creationDate: Date
    var petType: String // "cat" or "dog"
    
    init(localIdentifier: String, isFavorite: Bool = false, isHero: Bool = false, creationDate: Date = Date(), petType: String) {
        self.localIdentifier = localIdentifier
        self.isFavorite = isFavorite
        self.isHero = isHero
        self.creationDate = creationDate
        self.petType = petType
    }
}
