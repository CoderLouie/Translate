//
//  Translate.swift
//  Translate
//
//  Created by 李阳 on 2022/1/21.
//

import Foundation
extension String {
    @discardableResult
    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

fileprivate extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    subscript<R>(safe range: R) -> String? where R: RangeExpression, R.Bound == Int {
        let range = range.relative(to: Int.min..<Int.max)
        guard range.lowerBound >= 0,
            let lowerIndex = index(startIndex, offsetBy: range.lowerBound, limitedBy: endIndex),
            let upperIndex = index(startIndex, offsetBy: range.upperBound, limitedBy: endIndex) else {
                return nil
        }

        return String(self[lowerIndex..<upperIndex])
    }
}

fileprivate extension Scanner {
    // 方便 Debug时查看当前扫面到哪里了
    func peek(range: ClosedRange<Int>) -> String? {
        let i = scanLocation
        return string[safe: i+range.lowerBound...i+range.upperBound]
    }
    
    @discardableResult
    func move(to string: String) -> String? {
        var result: NSString? = nil
        while !isAtEnd {
            if scanString(string, into: &result) {
                return result as String?
            }
            scanLocation += 1
        }
        return nil
    }
    
    @discardableResult
    func moveUpTo(_ string: String) -> String? {
        var result: NSString? = nil
        while !isAtEnd {
            if scanUpTo(string, into: &result) {
                return result as String?
            }
            scanLocation += 1
        }
        return nil
    }
    @discardableResult
    func moveToCharacters(of set: CharacterSet, beforeOccurrencesIn occSet: CharacterSet) -> String? {
        var result: NSString? = nil
        let oriLocation = scanLocation
        var maxLocation: Int?
        while !isAtEnd {
            if scanCharacters(from: occSet, into: nil) {
                maxLocation = scanLocation
                break
            }
            scanLocation += 1
        }
        scanLocation = oriLocation
        
        while !isAtEnd {
            if scanCharacters(from: set, into: &result) {
                if let max = maxLocation {
                    if scanLocation < max {
                        return result as String?
                    } else {
                        scanLocation = oriLocation
                        return nil
                    }
                }
                return result as String?
            }
            scanLocation += 1
        }
        return nil
    }
    @discardableResult
    func moveToCharacters(of set: CharacterSet) -> String? {
        var result: NSString? = nil
        while !isAtEnd {
            if scanCharacters(from: set, into: &result) {
                return result as String?
            }
            scanLocation += 1
        }
        return nil
    }
    @discardableResult
    func moveToCharacters(in string: String, beforeOccurrencesSetInstring occString: String) -> String? {
        return moveToCharacters(of: .init(charactersIn: string), beforeOccurrencesIn: .init(charactersIn: occString))
    }
    @discardableResult
    func moveToCharacters(in string: String) -> String? {
        return moveToCharacters(of: .init(charactersIn: string))
    }
    
    @discardableResult
    func moveUpToCharacters(of set: CharacterSet) -> String? {
        var result: NSString? = nil
        while !isAtEnd {
            if scanUpToCharacters(from: set, into: &result) {
                return result as String?
            }
            scanLocation += 1
        }
        return nil
    }
    @discardableResult
    func moveUpToCharacters(in string: String) -> String? {
        return moveUpToCharacters(of: .init(charactersIn: string))
    }
     
    func scanQuoteWithInfo() -> (value: String, li: Int, ri: Int)? {
        let quote = "\"“”"
        guard moveToCharacters(in: quote) != nil else { return nil }
        let li = scanLocation
        guard let result = moveUpToCharacters(in: quote) else { return nil }
        return (result, li, scanLocation)
    }
    func scanQuote() -> String? {
        scanQuoteWithInfo()?.value
    }
}

enum Translate {
    static func strings(from excel: String, refer sample: String) -> String {
        let answer: [String]
        if excel.contains("=") {
            var temp: [String] = []
            let scanner = Scanner(string: excel)
            while !scanner.isAtEnd {
                guard scanner.move(to: "=") != nil else { break }
                guard let ans = scanner.scanQuote() else { fatalError() }
                temp.append(ans)
            }
            answer = temp
        } else {
            answer = excel.components(separatedBy: "\n").map { $0.trim() }.filter { !$0.isEmpty }
        }
        return makeAnswer(sample: sample, answer: answer)
    }
    private static func makeAnswer(sample: String, answer: [String]) -> String {
        var result = ""
        var index = 0
        
        let scanner = Scanner(string: sample)
        var location = 0
        while !scanner.isAtEnd, index < answer.count {
            guard let keyInfo = scanner.scanQuoteWithInfo() else { break }
            
            result.append(sample[safe: location..<keyInfo.li - 1]!)
            result.append("\"\(keyInfo.value)\" = ")
            
            guard scanner.move(to: "=") != nil else { fatalError() }
            
            guard scanner.scanQuote() != nil else { fatalError() }
            result.append("\"\(answer[index])\";")
            guard scanner.moveToCharacters(in: ";；") != nil else { fatalError() }
            index += 1
            location = scanner.scanLocation
        }
        result.append(sample[safe: location..<sample.count]!)
        
        return result
    }
    
    static func excel(from strings: String) -> (key: String, value: String) {
        var keys: [String] = []
        var values: [String] = []
        
        let scanner = Scanner(string: strings)
        while !scanner.isAtEnd {
            guard let key = scanner.scanQuote() else { break }
            keys.append(key)
            
            guard scanner.move(to: "=") != nil else { fatalError() }
            guard let value = scanner.scanQuote() else { fatalError() }
            values.append(value.replacingOccurrences(of: "\n", with: "#"))
            
            guard scanner.moveToCharacters(in: ";；") != nil else { fatalError() }
        }
        
        return (keys.joined(separator: "\n"), values.joined(separator: "\n"))
    }

    @discardableResult
    func validFormat(strings: String) -> String? {
        let defaultLoc = "can't location invalid string range"
        let scanner = Scanner(string: strings)
        while !scanner.isAtEnd {
            guard let _ = scanner.scanQuoteWithInfo() else { break }
            guard scanner.move(to: "=") != nil else {
                return scanner.peek(range: -5...0) ?? defaultLoc
            }
            guard scanner.scanQuote() != nil else {
                return scanner.peek(range: -5...0) ?? defaultLoc
            }
            guard scanner.moveToCharacters(in: ";", beforeOccurrencesSetInstring: "\"“”") != nil else {
                return scanner.peek(range: -5...0) ?? defaultLoc
            }
        }
        return nil
    }
}
 
