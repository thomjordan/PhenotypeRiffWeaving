//
//  NoteEventList.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 2/1/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import Overture
import Prelude
import Utilities


public typealias Notenum  = Int
public typealias Delta    = Int
public typealias Onset    = Int
public typealias Velocity = Int
public typealias Duration = Int


public final class NoteEventList {
    
    public var notenums  : [Notenum]
    public var deltas    : [Delta]
    public var velocity  : [Velocity]
    public var onsets    : [Onset]    = []
    public var durations : [Duration] = []
    public var span      :  Onset     = 0
    public var name      :  Int       = 0
    
    
    public init(notenums:[Notenum], deltas:[Delta], velocity:[Velocity]=[127,111], name:Int=0) {
        self.notenums = notenums
        self.deltas   = deltas
        self.velocity = velocity
        self.name     = name
    }
    
    public func setVelocity(_ newValues: [Velocity]) -> NoteEventList {
        return self |> (prop(\.velocity)) { _ in newValues }
    }
    public func setName(_ newValue: Int) -> NoteEventList {
        return self |> (prop(\.name)) { _ in newValue }
    }
    
    public func toEventList() -> [Int] {
        finalize()
        let events = Array(zip(onsets, notenums, velocity, durations)).flatMap { [$0.0, $0.1, $0.2, $0.3] }
        return [name, span] + events
    }
    
    /// assumes that notenums & deltas lengths match and already contain the number of events intended for the resulting phrase
    func finalize() {
        self.velocity     = velocity.loopToSize(deltas)
        let (ons, length) = deltas.asOnsetsFrom(0)
        self.onsets       = ons
        self.span         = length
        self.durations    = deltas
    }
}

extension NoteEventList {
    var floatDurations: [Float64] { return self.deltas.map { Float64($0) / 100.0 } }
    
    public func getDescription() -> String {
        let formattedDurs = deltas.map { String(format: "%.3f", $0) }
        let formattedStr  = String("\(formattedDurs)").replacingOccurrences(of: "\"", with: "")
        return String("""
            NoteEventList:
            n: \(notenums)
            d: \(formattedStr)
            """)
    }
}


//func map_<A, B>(_ f: @escaping (A) -> B) -> ([A]) -> [B] {
//    return { xs in
//        var result = [B]()
//        xs.forEach { x in result.append(f(x)) }
//        return result
//    }
//}
//extension NoteEventList {
//    func def<Value>(_ keyPath:WritableKeyPath<NoteEventList, Value>) -> (@escaping (Value) -> Value) -> NoteEventList {
//        return { (op: @escaping (Value) -> Value) in
//            return { self |> (prop(keyPath))(op) }()
//        }
//    }
//    func def<Value>(_ keyPath:WritableKeyPath<NoteEventList, Value>) -> (@escaping () -> Value) -> NoteEventList {
//        return { (op: @escaping () -> Value) in
//            return { self |> (prop(keyPath)) { _ in op() } }()
//        }
//    }
//}
//let evlist = NoteEventList(notenums: [1,2,3,4], deltas: [618,382,618,382])
//let eL2a = evlist.def(\.velocity)( map_ { $0 - 20 } )
//let eL2b = { _ in [127, 118, 108] } |> evlist.def(\.velocity)
//print(eL2a)
//print(eL2b)
//
//let eL3a = evlist.def(\.velocity) <| { [127, 118, 108] }
//let eL3b = { [127, 118, 108] } |> evlist.def(\.velocity)
//print(eL3a)
//print(eL3b)
