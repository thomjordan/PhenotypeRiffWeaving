//
//  RiffMapper.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 2/1/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import EvolutionModule
import Combinatorics
import Utilities

public struct Riffer : EvolutionEnvironment {
    
    public typealias Mapping = RiffMapping
    public typealias Phenome = (NoteEventList, NoteEventList)
    
    public func genPhenome(mapping: Mapping) -> Phenome? {
        let riff1 = mapping.renderRiff1()
        let riff2 = mapping.renderRiff2()
        guard let r1 = riff1, let r2 = riff2 else { return nil }
        return (r1, r2)
    }
    
    public func calcFitness(for phenome: Phenome, withWeights weights: [Float64]) -> (simple: Fitness.Value, cutoff: Fitness.Value) {
        let fitfunc = RiffFitness.API.getFitness(weights)
        var result : (simple: Fitness.Value, cutoff: Fitness.Value) = (1.0, 0.0)
        result = fitfunc(phenome.0, phenome.1)
        return result
    }
    
    public func showDescription(for phenome: Phenome?) {
        if let riffs : (NoteEventList, NoteEventList) = phenome {
            print("RIFF1 : \(riffs.0.getDescription())")
            print("RIFF2 : \(riffs.1.getDescription())\n")
        }
        else {
            print("RIFF1 : EMPTY")
            print("RIFF2 : EMPTY\n")
        }
    }
    
    public let genomeSize : UInt32 = 61
    public var evoParams  : EvoParams
    
    public init(_ eParams: EvoParams) { self.evoParams = eParams }
    
    public var rootkey  : Notenum      = 0
    public var tonesets : ToneSet      = ToneSets.minorA
    public var stepmaps : StepRemapper = StepRemappers.A
    
    public var octave1       : Int = 0
    public var octave2       : Int = 1
    public var offsetRange1  : Int = 12
    public var offsetRange2  : Int = 16
    
    public var rhythms : [[Delta]]  = [[62, 38], [57, 43], [54, 46], [53, 47], [52, 48], [50, 50]]
    public var noteDensity : Int = 16
    
    var riff1NoteStates : RiffNoteStateLookup = [ .attack: .neither, .sustain: .both, .silence: .either ]
    var riff2NoteStates : RiffNoteStateLookup = [ .attack: .neither, .sustain: .either, .silence: .both ]
    
    fileprivate enum Alleles {
        public static let fractalPerm:       (Genome) -> [Int] = { g in [g[0],g[1],g[2],g[3],g[4]] }
        public static let toneset1:          (Genome) -> [Int] = { g in [g[5]] }
        public static let inNoteEventMask1:  (Genome) -> [Int] = { g in [g[6],g[7],g[8],g[9],g[10],g[11],g[12],g[13],g[14],g[15],g[16],g[17]] }
        public static let stepOffset1:       (Genome) -> [Int] = { g in [g[18]] }
        public static let outNoteEventMask1: (Genome) -> [Int] = { g in [g[19],g[20],g[21],g[22],g[23],g[24],g[25],g[26],g[27],g[28],g[29],g[30]] }
        public static let stepMapperIdx1:    (Genome) -> [Int] = { g in [g[31]] }
        public static let rhythmSet1:        (Genome) -> [Int] = { g in [g[32]] }
        public static let toneset2:          (Genome) -> [Int] = { g in [g[33]] }
        public static let inNoteEventMask2:  (Genome) -> [Int] = { g in [g[34],g[35],g[36],g[37],g[38],g[39],g[40],g[41],g[42],g[43],g[44],g[45]] }
        public static let stepOffset2:       (Genome) -> [Int] = { g in [g[46]] }
        public static let outNoteEventMask2: (Genome) -> [Int] = { g in [g[47],g[48],g[49],g[50],g[51],g[52],g[53],g[54],g[55],g[56],g[57],g[58]] }
        public static let stepMapperIdx2:    (Genome) -> [Int] = { g in [g[59]] }
        public static let rhythmSet2:        (Genome) -> [Int] = { g in [g[60]] }
    }
    
    public func doMapping(from g: Genome) -> Mapping {
        var riff1Parameters : RiffParamsLookup = [:]
        var riff2Parameters : RiffParamsLookup = [:]
        
        riff1Parameters[.toneset] = tonesets[ Alleles.toneset1(g)[0] % tonesets.count ]
        riff1Parameters[.stepmap] = stepmaps[ Alleles.stepMapperIdx1(g)[0] % stepmaps.count ]
        riff1Parameters[.offset]  = Alleles.stepOffset1(g).map { $0 % offsetRange1 }
        riff1Parameters[.inmask]  = Alleles.inNoteEventMask1(g).map  { $0 % noteDensity }
        riff1Parameters[.outmask] = Alleles.outNoteEventMask1(g).map { $0 % noteDensity }
        riff1Parameters[.octave]  = [octave1]
        riff1Parameters[.rhythm]  = rhythms[ Alleles.rhythmSet1(g)[0] % rhythms.count ] //.map { Int( $0 * 1000 ) }
        riff2Parameters[.toneset] = tonesets[ Alleles.toneset2(g)[0] % tonesets.count ]
        riff2Parameters[.stepmap] = stepmaps[ Alleles.stepMapperIdx2(g)[0] % stepmaps.count ]
        riff2Parameters[.offset]  = Alleles.stepOffset2(g).map { $0 % offsetRange2 }
        riff2Parameters[.inmask]  = Alleles.inNoteEventMask2(g).map  { $0 % noteDensity }
        riff2Parameters[.outmask] = Alleles.outNoteEventMask2(g).map { $0 % noteDensity }
        riff2Parameters[.octave]  = [octave2]
        riff2Parameters[.rhythm]  = rhythms[ Alleles.rhythmSet2(g)[0] % rhythms.count ] //.map { Int( $0 * 1000 ) }
        let stepPattern = P4.fractalShapeA( Alleles.fractalPerm(g) )
        
        let rmap = RiffMapping(
            noteStates: (riff1NoteStates, riff2NoteStates),
            parameters: (riff1Parameters, riff2Parameters),
            rootkey: rootkey,
            pattern: stepPattern
        )
        return rmap
    }
}

extension Riffer {
    public func evolveEpoch(numtimes: Int) -> Population<Riffer> {
        let pop = Population(from: self)
        pop.evolve(numcycles: numtimes, numPoolsToKeep: numtimes/2)
        return pop 
        // if let best = pop.pool.first as? Riff, let riffs = best.phenome { print("Best riffDuo = \(riffs)") }
    }
}
