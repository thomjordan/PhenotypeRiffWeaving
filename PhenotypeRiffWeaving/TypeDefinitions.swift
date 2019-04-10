//
//  TypeDefinitions.swift
//  PhenotypeRiffWeaving
//
//  Created by Thom Jordan on 2/1/18.
//  Copyright © 2018 Thom Jordan. All rights reserved.
//

import Foundation

public enum Parameter { case toneset, stepmap, offset, inmask, outmask, octave, rhythm }
public enum Directive { case attack, sustain, silence }
public enum RestType  { case inrest, outrest, either, both, neither }

public typealias RiffParamsLookup = [ Parameter : [Int] ]
public typealias RiffNoteStateLookup = [ Directive : RestType ]
public typealias NoteAttackSustainOrRestEvent  = ( Int, Int, Int )




