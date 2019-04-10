//
//  ToneSets.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 1/20/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import Utilities 

public struct ToneSet : ArrayWrapper {
    public typealias T = [Int]
    public let data : [T]
    init(_ data: [T]) { self.data = data }
}

public enum ToneSets {
    public static let minorA = ToneSet([ [ 0, 3, 5, 7, 0, 3 ], [ 0, 3, 7, 8, 3, 0 ], [ 0, 3, 5, 7, 3, 0 ]])
}

