//
//  SemanticVersioningParser.swift
//
//  Copyright (c) 2015 Alexander Ney. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

private let defaultDelimiter = "."
private let prereleaseDelimiter = "-"
private let buildMetaDataDelimiter = "+"

private let numericCharacterSet = CharacterSet.decimalDigits
private let identifierCharacterSet: CharacterSet = {
    var characterSet = NSMutableCharacterSet.alphanumeric()
    characterSet.addCharacters(in: "-")
    return characterSet as CharacterSet
}()

/**
* SemanticVersionParser parses a semantic version string and returns the parsed components
*/
open class SemanticVersionParser {

    private let stringRepresentation: String

    public struct Result {
        public var major: Int?
        public var minor: Int?
        public var patch: Int?
        public var prereleaseIdentifiers: [String]?
        public var buildMetadataIdentifiers: [String]?
    }

    /**
    Represents the result of the string parsing
    
    - Success: Success case with an array of successfully parsed components
    - Failure: Failure case with the location in the original string,
     the failed component and the already successful parsed components
    */
    public struct ParsingError: Error {
        public let location: Int
        public let failedComponent: ParserComponent
        public let reason: Error
        public let result: Result
    }

    public enum ConsistencyError: Error {
        case nonNumericValue
        case delimiterExpected
        case malformedIdentifiers([String])
        case endOfStringExpected
    }

    public enum ParserComponent: String {
        case major, minor, patch, prereleaseIdentifiers, buildMetadataIdentifiers
    }

    /**
    Default initializer
    
    - parameter :versionString String representing the version
    - returns: valid SemanticVersionParser
    */
    public init(_ versionString: String) {
        stringRepresentation = versionString
    }

    /**
    starts parsing the version string
    - returns: Result object representing the success of the parsing operation
    */
    open func parse() throws -> Result {

        let scanner = Scanner(string: stringRepresentation)
        var component: ParserComponent = .major
        var result = Result()

        do {
            result.major = try scanNumericComponent(scanner)
            try scanDelimiter(defaultDelimiter, scanner)

            component = .minor
            result.minor = try scanNumericComponent(scanner)
            try scanDelimiter(defaultDelimiter, scanner)

            component = .patch
            result.patch = try scanNumericComponent(scanner)

            if scanOptionalDelimiter(prereleaseDelimiter, scanner) {
                component = .prereleaseIdentifiers
                do {
                    result.prereleaseIdentifiers = try scanIdentifiersComponent(scanner)
                } catch ConsistencyError.malformedIdentifiers(let identifiers) {
                    result.prereleaseIdentifiers = identifiers
                    throw ConsistencyError.malformedIdentifiers(identifiers)
                }
            }

            if scanOptionalDelimiter(buildMetaDataDelimiter, scanner) {
                component = .buildMetadataIdentifiers
                do {
                    result.buildMetadataIdentifiers = try scanIdentifiersComponent(scanner)
                } catch ConsistencyError.malformedIdentifiers(let identifiers) {
                    result.buildMetadataIdentifiers = identifiers
                    throw ConsistencyError.malformedIdentifiers(identifiers)
                }
            }

            guard scanner.isAtEnd else { throw ConsistencyError.endOfStringExpected }

        } catch let error {

            throw ParsingError(location: scanner.scanLocation,
                               failedComponent: component,
                               reason: error,
                               result: result)
        }

        return result
    }

    fileprivate func scanNumericComponent(_ scanner: Scanner, upTo delimiter: String = defaultDelimiter) throws -> Int {
        let string = scanner.scanCharacters(from: numericCharacterSet)
        
        guard let numberString = string as String?,
              let number = Int(numberString) else {
            throw ConsistencyError.nonNumericValue
        }
        return number
    }

    fileprivate func scanIdentifiersComponent(_ scanner: Scanner) throws -> [String] {
        var identifiers: [String] = []
        repeat {
            let string = scanner.scanCharacters(from: identifierCharacterSet)
            
            guard let identifier = string as String?, !identifier.isEmpty else {
                throw ConsistencyError.malformedIdentifiers(identifiers)

            }
            identifiers.append(identifier)
            guard scanOptionalDelimiter(defaultDelimiter, scanner) else { break }
        } while (true)
        return identifiers
    }

    private func scanOptionalDelimiter(_ delimiter: String, _ scanner: Scanner) -> Bool {
        return scanner.scanString(delimiter, into: nil)
    }

    private func scanDelimiter(_ delimiter: String, _ scanner: Scanner) throws {
        guard scanOptionalDelimiter(delimiter, scanner) else {
            throw ConsistencyError.delimiterExpected
        }
    }

}

/**
*  Extension of SemanticVersion the conform to StringLiteralConvertible
*  so Versions can be initialized by assigning a String like:
*  `let version : SemanticVersion = "1.2.0"`
*/
extension Version: ExpressibleByStringLiteral {

    /**
    Will try to initialize a SemanticVersion from a specified String
    
    - parameter versionString: String representing a version
    - parameter strict: Bool specifies if the string should be parsed strictly according to the
     Semantic Versioning specification or not. If strict is false usually obligatory values like
     minor and path can be omitted
    - returns: initialized SemanticVersion or nil if version string could not be parsed
    */
    public init(_ versionString: String, strict: Bool = true) throws {
        let parser = SemanticVersionParser(versionString)
        let result: SemanticVersionParser.Result
        do {
           result  = try parser.parse()
        } catch let parsingError as SemanticVersionParser.ParsingError where !strict {
            // Only Major Version becomes mandatory
            guard parsingError.result.major != nil else { throw parsingError }
            result = parsingError.result
        } catch {
            throw error
        }
        self.init(parserResult: result)
    }

    fileprivate init(parserResult: SemanticVersionParser.Result) {

        self.major = parserResult.major ?? 0
        self.minor = parserResult.minor ?? 0
        self.patch = parserResult.patch ?? 0
        self.preReleaseIdentifier = parserResult.prereleaseIdentifiers ?? []
        self.buildMetadataIdentifier = parserResult.buildMetadataIdentifiers ?? []
    }

    // MARK: StringLiteralConvertible

    public init(stringLiteral value: String) {
        self = (try? Version(value)) ?? Version(major: 0)
    }
}
