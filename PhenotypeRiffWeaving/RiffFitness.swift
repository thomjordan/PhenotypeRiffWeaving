//
//  RiffFitness.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 1/22/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import EvolutionModule
import Utilities
import Prelude 

// RiffFitness is a namespace only, for accessing functional constructs (i.e. functions)

public enum RiffFitness {
    public enum API     { }
    public enum Density { }
    public enum Zipf    { }
}

extension RiffFitness.API {
    
    static func getFitness(_ weights:[Float64]) -> (NoteEventList, NoteEventList) -> (Fitness.Value, Fitness.Value) {
        return { (riff1, riff2) in
            let result : (Fitness.Value, Fitness.Value) = (1.0, 0.0)
            guard weights.count > 0 else { return result }
            var scalars  : Cycle<Float64> = Cycle(weights)
            var fitfuncs : [ (NoteEventList, NoteEventList) -> (Fitness.Value, Fitness.Value) ] = []
            fitfuncs += [avg <| pitchZipf]
            fitfuncs += [avg <| pitchMod12Zipf]
            fitfuncs += [avg <| pitchRestsZipf]
            fitfuncs += [avg <| pitchMod12RestsZipf]
            fitfuncs += [avg <| melodicIntervalsZipf]
            fitfuncs += [avg <| melodicIntervalsMod12Zipf]
            fitfuncs += [avg <| binaryDurations]
            fitfuncs += [avg <| restRatioRange()] // input min,max,mix arguments here
            let scores = fitfuncs.map { f in f(riff1,riff2) }
            var numeratorZΔ : Float64 = 0.0
            var numeratorR2 : Float64 = 0.0
            var denominator : Float64 = 0.0
            for score in scores {
                let weight = scalars.next()!
                numeratorZΔ += score.0 * weight
                numeratorR2 += score.1 * weight
                denominator += weight
            }
            guard denominator != 0 else { return result }
            return ((numeratorZΔ / denominator), (numeratorR2 / denominator))
            //return (0.5, 1.0)
        }
    }
    
    public static func avg(_ fitfunc: @escaping (NoteEventList) -> (Fitness.Value, Fitness.Value)) -> (NoteEventList, NoteEventList) -> (Fitness.Value, Fitness.Value) {
        return { (riff1, riff2) in
            let temp1 = fitfunc(riff1)
            let temp2 = fitfunc(riff2)
            let result1 = (temp1.0 + temp2.0) / 2.0
            let result2 = (temp1.1 + temp2.1) / 2.0
            return (result1, result2) 
        }
    }
    
    // arousing
    public static func pitchZipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Zipf.calc(removeRests(evlist))
        return result
    }
    
    // creative
    public static func pitchMod12Zipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Zipf.calc(mod12(removeRests(evlist)))
        return result
    }
    
    // joyous
    public static func pitchRestsZipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Zipf.calc(evlist)
        return result
    }
    
    // abysmal
    public static func pitchMod12RestsZipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Zipf.calc(mod12WithRests(evlist))
        return result
    }
    
    // gentle
    public static func melodicIntervalsZipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Zipf.calc(calcIntervals(evlist.notenums))
        return result
    }
    
    // clinging
    public static func melodicIntervalsMod12Zipf(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let mod12Intervals = calcIntervals(evlist.notenums).map { $0 % 12 }
        let result = RiffFitness.Zipf.calc(mod12Intervals)
        return result
    }
    
    // still
    public static func binaryDurations(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        let result = RiffFitness.Density.binaryDurations(evlist)
        return result
    }
    
    // receptive
    public static func restRatioRange(min:Float64=0.0, max:Float64=0.382, mix:Float64=0.001) -> (NoteEventList) -> (Fitness.Value, Fitness.Value) {
        return { (evlist) in
            let ratio = RiffFitness.Density.restsRatio(evlist, mix)
            if ratio < min || ratio > max { return (0.0001, 1.0) }
            else { return (0.9999, 1.0) }
        }
    }
    
}


extension RiffFitness.Zipf {
    
    public static func calc(_ evlist: NoteEventList) -> (Fitness.Value, Fitness.Value) {
        var freqs : [Float64] = []
        let uniques = evlist.notenums.unique
        for uval in uniques {
            let idxs = evlist.notenums.indexesOf(uval)
            let sum  = idxs.map { Float64(evlist.deltas[$0]) / 100.0 }.reduce(0) { $0 + $1 }
            freqs.append(sum)
        }
        return getSlopeR2(freqs)
    }
    
    public static func calc<T: Equatable & Hashable>(_ valt: [T]) -> (Fitness.Value, Fitness.Value) {
        var freqs : [Float64] = []
        let uniques = valt.unique
        for uval in uniques {
            let idxs = valt.indexesOf(uval)
            let sum  = Float64(idxs.count)
            freqs.append(sum)
        }
        return getSlopeR2(freqs)
    }
}

extension Int { public var isRest : Bool { return self == 1000 } }

extension RiffFitness.Density {
    
    public static func restsRatio(_ evlist: NoteEventList, _ mix: Float64 = 0.5) -> Float64 {
        let restIdxs = evlist.notenums.indexesOf(1000)
        let restsNum = Float64(restIdxs.count)
        let restsSum = restIdxs.map { evlist.floatDurations[$0] }.reduce(0) { $0 + $1 }
        let totalNum = Float64(evlist.notenums.count)
        let totalSum = evlist.floatDurations.reduce(0.0) { $0 + $1 }
        let resultδ : Float64 = (restsNum * restsSum) / (totalNum * totalSum)
        let resultβ : Float64 = restsSum / totalSum
        let result  : Float64 = (mix * resultδ) + ((1.0 - mix) * resultβ)
        return result
    }
    
    public static func binaryDurations(_ evlist: NoteEventList ) -> (Fitness.Value, Fitness.Value) {
        var notenums = evlist.notenums
        var notelens = evlist.deltas
        while notenums[0] == 1000 {
            notenums.append(notenums.removeFirst())
            notelens.append(notelens.removeFirst())
        }
        var deltas : [Int] = []
        var dur : Int = 0
        for (idx, nnum) in notenums.enumerated() {
            if nnum.isRest {
                dur += notelens[idx]
            } else {
                deltas.append(dur)
                dur = notelens[idx]
            }
        }
        deltas.append(dur)
        if deltas.count > 0, deltas[0] == 0 {
            deltas.removeFirst()
        }
        let result = RiffFitness.Zipf.calc(deltas)
        return result
    }
}

// PRIVATE

extension RiffFitness.API {
    
    private static func removeRests(_ evlist: NoteEventList) -> NoteEventList {
        let restIdxs  = evlist.notenums.indexesOf(1000).sorted(by: >)
        var pitchnums = evlist.notenums
        var pitchlens = evlist.deltas
        for idx in restIdxs {
            pitchnums.remove(at: idx)
            pitchlens.remove(at: idx)
        }
        let pitchvals = NoteEventList(notenums: pitchnums, deltas: pitchlens)
        return pitchvals
    }
    
    private static func removeRests(_ valz: [Int]) -> [Int] {
        let restIdxs  = valz.indexesOf(1000).sorted().reversed()
        var pitchnums = valz
        for idx in restIdxs { pitchnums.remove(at: idx) }
        return pitchnums
    }
    
    private static func mod12WithRests(_ evlist: NoteEventList) -> NoteEventList {
        var modnums : [Int] = []
        for val in evlist.notenums {
            if val == 1000 { modnums.append(1000) }
            else { modnums.append( val % 12 ) }
        }
        let modpairs = NoteEventList(notenums: modnums, deltas: evlist.deltas)
        return modpairs
    }
    
    private static func mod12(_ evlist: NoteEventList) -> NoteEventList {
        let modnums  = evlist.notenums.map { $0 % 12 }
        let modpairs = NoteEventList(notenums: modnums, deltas: evlist.deltas)
        return modpairs
    }
    
    private static func calcIntervals(_ valc: [Int]) -> [Int] {
        let pitchnums = removeRests(valc)
        guard pitchnums.count > 2 else { return [] }
        var intervals : [Int] = []
        for i in 0..<pitchnums.count-1 {
            intervals.append( pitchnums[i+1] - pitchnums[i] )
        }
        return intervals
    }
}


extension RiffFitness.Zipf {
    
    private static func getSlopeR2(_ freqs: [Float64]) -> (Fitness.Value, Fitness.Value) {
        
        var sumX  : Float64 = 0.0
        var sumY  : Float64 = 0.0
        var sumXY : Float64 = 0.0
        var sumX2 : Float64 = 0.0
        var sumY2 : Float64 = 0.0
        
        var slope : Float64 = 0.0
        var r2    : Float64 = 0.0
        
        let numberOfRanks = freqs.count
        
        guard numberOfRanks > 1      else { return (0.0, 0.0) }
        guard freqs.unique.count > 1 else { return (0.0001, 1.0) } // if all freqs are equal
        
        let frqs = Array(freqs.sorted().reversed())
        
        for idx in 0..<numberOfRanks {
            let logCurrRank = log10(Float64(idx+1))
            let logCurrFreq = log10(frqs[idx])
            sumX  += logCurrRank
            sumY  += logCurrFreq
            sumXY += logCurrRank * logCurrFreq
            sumX2 += pow(logCurrRank, 2)
            sumY2 += pow(logCurrFreq, 2)
        }
        
        let size = Float64(numberOfRanks)
        let numerator = size * sumXY - sumX * sumY
        
        // calculate the slope
        let slopeDenominator = size * sumX2 - sumX * sumX
        if slopeDenominator == 0.0 { slope = 0.0 }
        else { slope = numerator / slopeDenominator }
        
        // calculate the r2
        let r2Denominator = sqrt( slopeDenominator * (size * sumY2 - sumY * sumY) )
        if r2Denominator == 0.0 { r2 = 0.0 }
        else { let r = numerator / r2Denominator ; r2 = r * r }
        
        // calculate y-intercept
        // let yint = (sumY - slope * sumX) / size
        
        let differenceFromIdealZipfianSlope = abs( slope + 1.0 ) // abs difference from -1.0
        
        return (differenceFromIdealZipfianSlope, r2)
    }
    
    private static func metric(_ freqs: [Float64]) -> Float64 {
        var zipf : [Float64] = []
        for (index, freq) in freqs.enumerated() {
            zipf.append( Float64(index+1) * freq ) // Zipf value = rank * freq
        }
        zipf = zipf.sorted()
        var sum : Float64 = 0.0
        if zipf.count > 1 {
            for z in 0..<zipf.count-1 {
                sum += (zipf[z+1] - zipf[z])
            }
            return sum / Float64(zipf.count)
        }
        else { return 0.999 }
    }
}

