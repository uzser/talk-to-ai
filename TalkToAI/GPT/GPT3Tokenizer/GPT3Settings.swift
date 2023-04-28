import Foundation

struct GPT3Settings {
    
    struct StringPair: Hashable {
        let first: String
        let second: String
    }
    
    static var encoder: [String: Int] = {
        return buildEncoder()
    }()
    
    static var bpeRanks: [StringPair: Int] = {
        return buildBpeRanks()
    }()
    
    private static func buildBpeRanks() -> [StringPair: Int] {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "bpe"),
              let content = try? String(contentsOf: url) else {
            return [:]
        }
        
        let lines = content.split(separator: "\n")
        let bpeMerges: [StringPair] = lines[1...].compactMap { line in
            let parts = line.split(separator: " ")
            return StringPair(first: String(parts[0]), second: String(parts[1]))
        }
        
        return dictZip(bpeMerges, Array(0..<bpeMerges.count))
    }
    
    private static func buildEncoder() -> [String: Int] {
        guard let url = Bundle.main.url(forResource: "encoder", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let encoder = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        
        return encoder
    }
    
    private static func dictZip(_ x: [StringPair], _ y: [Int]) -> [StringPair: Int] {
        var result = [StringPair: Int]()
        for i in 0..<x.count {
            result[x[i]] = y[i]
        }
        return result
    }
}
