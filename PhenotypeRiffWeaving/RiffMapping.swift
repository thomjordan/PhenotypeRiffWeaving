//
//  Factory.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 1/22/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation
import EvolutionModule
import Utilities

typealias RestTypeIdentifier = (Int,Int) -> Bool
typealias RestTypeIdentifierLookup = [ RestType : RestTypeIdentifier ]


public struct RiffMapping {
    
    init( noteStates : (RiffNoteStateLookup, RiffNoteStateLookup),
          parameters : (RiffParamsLookup, RiffParamsLookup),
          rootkey    :  Notenum,
          pattern    : [Notenum] ) {
        
        self.riff1NoteStates = noteStates.0
        self.riff2NoteStates = noteStates.1
        self.riff1Params     = parameters.0
        self.riff2Params     = parameters.1
        self.rootkey         = rootkey
        self.stepPattern     = pattern
    }
    
    var riff1NoteStates : RiffNoteStateLookup
    var riff2NoteStates : RiffNoteStateLookup
    
    var riff1Params : RiffParamsLookup
    var riff2Params : RiffParamsLookup
     
    var rootkey     :  Notenum
    var stepPattern : [Notenum]
    
    fileprivate func mapPitches(_ params: RiffParamsLookup, globalOffset: Int = 0) -> ([NoteAttackSustainOrRestEvent], [Delta])? {
        
        guard let stepmap = params[.stepmap] else { return nil }
        guard let offset  = params[.offset]  else { return nil }
        guard let inMask  = params[.inmask]  else { return nil }
        guard let toneset = params[.toneset] else { return nil }
        guard let outMask = params[.outmask] else { return nil }
        guard let octave  = params[.octave]  else { return nil }
        guard let rhythm  = params[.rhythm]  else { return nil }
        
        let numstepsInOctave = stepmap.count
        var outPattern = [NoteAttackSustainOrRestEvent]()
        
        for step in stepPattern {
            let pstep      = step + offset[0] + globalOffset    // add offset & globalOffset to basepattern step
            let nowOct     = pstep / numstepsInOctave           // put aside the octave part of the current pstep
            let scaleStep  = stepmap[pstep % numstepsInOctave]  // use pstep % numstepsInOctave as an index to stepmap
            let inRest     = inMask[(pstep % numstepsInOctave) % inMask.count] // check if the element of inMask corresponding to scaleStep is a rest
            let tone       = toneset[scaleStep % toneset.count] // use the scaleStep value as an index to get tone (pitch-class) from toneset
            let outRest    = outMask[tone % outMask.count]      // check if the element of outMask corresponding to pitch-class (tone val) is a rest
            let notenum    = tone + (nowOct * numstepsInOctave) + rootkey + (octave[0] * numstepsInOctave) // add the other values back in to get actual notenum value
            outPattern.append( (notenum,inRest,outRest) )
        }
        let rhythmPattern = rhythm.map { Delta($0) }
//        print("\(#function):")
//        print("outPattern: ")
//        let _ = outPattern.map { print("\($0)") }
//        print("rhythmPattern: ")
//        let _ = rhythmPattern.map { print("\($0)") }
        return (outPattern, rhythmPattern)
    }
    
    public func renderRiff1(from offset: Int = 0) -> NoteEventList? {
        guard let sseq1 = mapPitches(riff1Params, globalOffset: offset) else { return nil }
        guard let riff1 = calcEventList(sseq1, riff1NoteStates)         else { return nil }
        return riff1
    }
    
    public func renderRiff2(from offset: Int = 0) -> NoteEventList? {
        guard let sseq2 = mapPitches(riff2Params, globalOffset: offset) else { return nil }
        guard let riff2 = calcEventList(sseq2, riff2NoteStates)         else { return nil }
        return riff2
    }
    
    fileprivate func calcEventList(_ events: ([NoteAttackSustainOrRestEvent], [Delta]), _ noteStates: RiffNoteStateLookup) -> NoteEventList? {
        guard let att = noteStates[.attack],  let attack  = isRestType[att] else { return nil }
        guard let sus = noteStates[.sustain], let sustain = isRestType[sus] else { return nil }
        guard let sil = noteStates[.silence], let silence = isRestType[sil] else { return nil }
        let stepSequence = events.0
        var rhythmCycle  = Cycle( events.1 )
        var notenum  : Notenum  = 1000 // start with signifier for a rest
        var notelen  : Delta = 0
        var notenums : [Notenum] = []
        var notelens : [Delta]   = []
        rhythmCycle.reset()
        
        for step in stepSequence {
            if attack(step.1, step.2) {
                notenums.append(notenum)
                notelens.append(notelen)
                notenum = step.0
                notelen = rhythmCycle.next()!
            }
            else if sustain(step.1, step.2) {
                notelen += rhythmCycle.next()!
            }
            else if silence(step.1, step.2) {

                if notenum == 1000 {               // if previous event was a rest
                    notelen += rhythmCycle.next()! // extend that rest instead of appending a new rest event
                }
                else {
                    notenums.append(notenum)
                    notelens.append(notelen)
                    notenum = 1000
                    notelen = rhythmCycle.next()!
                }
            }
//            notenums.append(notenum)
//            notelens.append(notelen)
//            notenum = step.0
//            notelen = rhythmCycle.next()!
        }
        notenums.append(notenum)
        notelens.append(notelen)
        
        if notenums[0] == 1000 && notelens[0] == 0 {
            notenums.removeFirst()
            notelens.removeFirst()
        }
        
        //let roundedDurs = notelens.map { Int32( round( 100 * $0 ) ) }

        let result = NoteEventList(notenums: notenums, deltas: notelens)
        //print(result)
        return result
    }
    
    fileprivate let isRestType : RestTypeIdentifierLookup = [
        .inrest:  {( $0 == 0 ) && ( $1 != 0 )},
        .outrest: {( $0 != 0 ) && ( $1 == 0 )},
        .either:  {( $0 == 0 ) != ( $1 == 0 )},
        .both:    {( $0 == 0 ) && ( $1 == 0 )},
        .neither: {( $0 != 0 ) && ( $1 != 0 )}
    ]
    
}


