//
//  Arbitrary.swift
//  Vinyl
//
//  Created by Robert Widmann on 2/20/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import SwiftCheck

/// Generates an array of lowercase alphabetic `Character`s.
let lowerStringGen = 
    Gen<Character>.fromElementsIn("a"..."z")
    .proliferateNonEmpty
    .map(String.init)

/// Generates a URL of the form `(http|https)://<domain>.com`.
let urlStringGen : Gen<String> = sequence([ 
    Gen<String>.fromElementsOf(["http://", "https://"]),
    lowerStringGen,
    Gen.pure(".com"),
].reverse()).map { $0.reduce("", combine: +) }

/// Generates a path of the form `<some>/<path>/<to>/.../<somewhere>`.
let urlPathGen : Gen<String> = 
    (curry(+) <^> Gen.pure("/") <*> lowerStringGen)
    .proliferate
    .map { $0.reduce("", combine: +) }

/// Generates an array of parameters of the form `<param>=<arg>`,
let parameterGen : Gen<String> = sequence([
	lowerStringGen,
	Gen.pure("="),
	lowerStringGen,
].reverse()).map { $0.reduce("", combine: +) }

/// Generates a set of parameters. 
let pathParameterGen : Gen<String> = Gen.sized { sz in
	return parameterGen.proliferateSized(sz + 1)
} .map { xs in 
	return xs.reduce("?") { $0 == "?" ? "?" + $1 : $0 + "&" + $1 } 
}

private func curry<A, B, C>(f : (A, B) -> C) -> A -> B -> C {
    return { a in { b in f(a, b) } }
}

extension Dictionary {
    init<S : SequenceType where S.Generator.Element == Element>(_ pairs : S) {
        self.init()
        var g = pairs.generate()
        while let (k, v) : (Key, Value) = g.next() {
            self[k] = v
        }
    }
}
