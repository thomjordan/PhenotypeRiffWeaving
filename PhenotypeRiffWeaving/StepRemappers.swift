//
//  StepRemappers.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 1/20/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import Utilities

public struct StepRemapper : ArrayWrapper {
    public typealias T = [Int]
    public let data : [T]
    init(_ data: [T]) { self.data = data }
}

public enum StepRemappers {
    
    //public static let A = StepRemapper([ [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5], [5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0 ] ])
    
    public static let A = StepRemapper([ [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5], [5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0 ],
                                         [0, 1, 2, 3, 4, 5, 5, 4, 3, 2, 1, 0], [5, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5 ] ])
    
    public static let B = StepRemapper([ [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5], [5, 4, 3, 2, 1, 0, 5, 4, 3, 2, 1, 0 ] ])
    
    public static let C = StepRemapper([ [0, 1, 2, 3, 4, 5, 5, 4, 3, 2, 1, 0], [5, 4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5 ] ])
    
    public static let D = StepRemapper([ [0, 0, 0, 1, 1, 2, 3, 4, 4, 5, 5, 5], [5, 5, 5, 4, 4, 3, 2, 2, 2, 1, 1, 0 ] ])
}

