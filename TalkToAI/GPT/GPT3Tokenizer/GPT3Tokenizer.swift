import Foundation

// Swift version of https://github.com/dluc/openai-tools/blob/main/GPT-tokenizer-dotnet/Lib/GPT3Tokenizer.cs
class GPT3Tokenizer {
    
    private static var bpeCache = [String: String]()
    private static var bytesToUnicodeCache: [UInt8: Character]?
    
    static func encode(_ text: String) -> [Int] {
        if text.isEmpty {
            return []
        }
        
        let byteEncoder = bytesToUnicode()
        let pattern = "'s|'t|'re|'ve|'m|'ll|'d| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var bpeTokens: [Int] = []
        for match in matches {
            let matchedString = (text as NSString).substring(with: match.range)
            let token = String(matchedString.utf8.map { byteEncoder[$0]! })
            let newTokens = bytePairEncoding(token).split(separator: " ").compactMap { GPT3Settings.encoder[String($0)] }
            bpeTokens.append(contentsOf: newTokens)
        }
        
        return bpeTokens
    }

    
    static func encode(_ text: [Character]) -> [Int] {
        return encode(String(text))
    }
    
    private static func ord(_ string: String) -> UInt8 {
        return UInt8(string.utf8.first!)
    }
    
    private static func bytesToUnicode() -> [UInt8: Character] {
        if let cache = bytesToUnicodeCache {
            return cache
        }
        
        let firstRange = Array("!".unicodeScalars.first!.value...("~".unicodeScalars.first!.value))
        let secondRange = Array("¡".unicodeScalars.first!.value...("¬".unicodeScalars.first!.value))
        let thirdRange = Array("®".unicodeScalars.first!.value...("ÿ".unicodeScalars.first!.value))
        
        var bytes: [UInt8] = (firstRange + secondRange + thirdRange).map { UInt8($0) }
        var chars: [Character] = bytes.map { Character(UnicodeScalar($0)) }
        
        var n = 0
        for b: UInt8 in 0...255 {
            if bytes.contains(b) {
                continue
            }
            bytes.append(b)
            if let scalar = UnicodeScalar(256 + n) {
                chars.append(Character(scalar))
                n += 1
            }
        }
        
        bytesToUnicodeCache = Dictionary(uniqueKeysWithValues: zip(bytes, chars))
        return bytesToUnicodeCache!
    }

    
    private static func bytePairEncoding(_ token: String) -> String {
        if let cached = bpeCache[token] {
            return cached
        }
        
        var word = Array(token).map { String($0) }
        var pairs = getPairs(word)
        if pairs.isEmpty {
            bpeCache[token] = token
            return token
        }
        
        while true {
            var minPairs = [Int: GPT3Settings.StringPair]()
            for pair in pairs {
                let stringPair = GPT3Settings.StringPair(first: pair.first, second: pair.second)
                if let rank = GPT3Settings.bpeRanks[stringPair] {
                    minPairs[rank] = stringPair
                } else {
                    minPairs[Int.max] = stringPair
                }
            }
            
            let biGram = minPairs[minPairs.keys.min()!]
            if GPT3Settings.bpeRanks[biGram!] == nil { break }
            let first = biGram!.first
            let second = biGram!.second
            
            var newWord = [String]()
            var i = 0
            
            while i < word.count {
                if let j = word[i...].firstIndex(of: first) {
                    let slice = Array(word[i..<j])
                    newWord.append(contentsOf: slice)
                    i = j
                    
                    if word[i] == first, i < (word.count - 1), word[i + 1] == second {
                        newWord.append("\(first)\(second)")
                        i += 2
                    } else {
                        newWord.append(word[i])
                        i += 1
                    }
                } else {
                    let slice = Array(word[i...])
                    newWord.append(contentsOf: slice)
                    break
                }
            }
            
            word = newWord
            if word.count == 1 { break }
            pairs = getPairs(word)
        }
        
        let result = word.joined(separator: " ")
        bpeCache[token] = result
        return result
    }
    
    private static func getPairs(_ word: [String]) -> [GPT3Settings.StringPair] {
        var result = [GPT3Settings.StringPair]()
        var prevChar = word[0]
        for i in 1..<word.count {
            let currentChar = word[i]
            result.append(GPT3Settings.StringPair(first: prevChar, second: currentChar))
            prevChar = currentChar
        }
        return result
    }
}
