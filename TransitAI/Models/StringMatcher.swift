import Foundation

/// Advanced string matching with typo tolerance, phonetic matching, and Czech language support
class StringMatcher {
    
    // MARK: - Diacritics Removal
    
    private static let diacriticsMap: [Character: Character] = [
        "á": "a", "č": "c", "ď": "d", "é": "e", "ě": "e", "í": "i", "ň": "n",
        "ó": "o", "ř": "r", "š": "s", "ť": "t", "ú": "u", "ů": "u", "ý": "y", "ž": "z",
        "Á": "A", "Č": "C", "Ď": "D", "É": "E", "Ě": "E", "Í": "I", "Ň": "N",
        "Ó": "O", "Ř": "R", "Š": "S", "Ť": "T", "Ú": "U", "Ů": "U", "Ý": "Y", "Ž": "Z"
    ]
    
    static func removeDiacritics(_ str: String) -> String {
        String(str.map { diacriticsMap[$0] ?? $0 })
    }
    
    static func normalize(_ text: String) -> String {
        removeDiacritics(text.lowercased().trimmingCharacters(in: .whitespaces))
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    // MARK: - Levenshtein Distance
    
    static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a)
        let b = Array(b)
        
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count { dist[i][0] = i }
        for j in 0...b.count { dist[0][j] = j }
        
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                dist[i][j] = min(dist[i-1][j] + 1, dist[i][j-1] + 1, dist[i-1][j-1] + cost)
                
                // Transposition
                if i > 1 && j > 1 && a[i-1] == b[j-2] && a[i-2] == b[j-1] {
                    dist[i][j] = min(dist[i][j], dist[i-2][j-2] + cost)
                }
            }
        }
        return dist[a.count][b.count]
    }
    
    // MARK: - Phonetic Code
    
    static func phoneticCode(_ text: String) -> String {
        var result = normalize(text)
        let replacements = [("y", "i"), ("z", "s"), ("w", "v"), ("ch", "h"), ("ou", "u")]
        for (from, to) in replacements {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }
    
    // MARK: - Match Score (0.0 - 1.0)
    
    static func matchScore(_ query: String, _ target: String) -> Double {
        let nq = normalize(query)
        let nt = normalize(target)
        
        if nq.isEmpty || nt.isEmpty { return 0.0 }
        if nq == nt { return 1.0 }
        if nt.hasPrefix(nq) { return 0.95 }
        if nt.contains(nq) { return 0.85 }
        
        // Levenshtein
        let dist = levenshteinDistance(nq, nt)
        let maxLen = max(nq.count, nt.count)
        let levenScore = 1.0 - (Double(dist) / Double(maxLen))
        
        // Phonetic
        let pq = phoneticCode(query)
        let pt = phoneticCode(target)
        let phoneDist = levenshteinDistance(pq, pt)
        let phoneMax = max(pq.count, pt.count)
        let phoneScore = phoneMax > 0 ? 1.0 - (Double(phoneDist) / Double(phoneMax)) : 0.0
        
        return max(levenScore * 0.8, phoneScore * 0.7)
    }
    
    // MARK: - Find Best Matches
    
    static func findBestMatches(query: String, in stops: [PIDStop], maxResults: Int = 5, minScore: Double = 0.4) -> [(stop: PIDStop, score: Double)] {
        stops.map { (stop: $0, score: matchScore(query, $0.name)) }
            .filter { $0.score >= minScore }
            .sorted { $0.score > $1.score }
            .prefix(maxResults)
            .map { $0 }
    }
    
    static func findBestPlaceMatches(query: String, in places: [KnownPlace], maxResults: Int = 3) -> [(place: KnownPlace, score: Double)] {
        places.map { place -> (place: KnownPlace, score: Double) in
            var best = matchScore(query, place.name)
            best = max(best, matchScore(query, place.nameEn))
            for alias in place.aliases {
                best = max(best, matchScore(query, alias))
            }
            return (place, best)
        }
        .filter { $0.score >= 0.5 }
        .sorted { $0.score > $1.score }
        .prefix(maxResults)
        .map { $0 }
    }
    
    // MARK: - Disambiguation
    
    static func disambiguate(query: String, stops: [PIDStop]) -> DisambiguationResult {
        let matches = findBestMatches(query: query, in: stops, maxResults: 5, minScore: 0.35)
        
        guard !matches.isEmpty else {
            return DisambiguationResult(matches: [], confidence: 0.0, needsUserInput: false)
        }
        
        let bestScore = matches[0].score
        let needsInput = matches.count >= 2 && (matches[0].score - matches[1].score) < 0.15 && bestScore < 0.95
        
        return DisambiguationResult(
            matches: matches.map { $0.stop },
            confidence: bestScore,
            needsUserInput: needsInput
        )
    }
    
    // MARK: - Common Typos
    
    static let commonTypos: [String: String] = [
        "mustek": "můstek", "vaclavak": "václavské náměstí", "hlavak": "hlavní nádraží",
        "dejvice": "dejvická", "andel": "anděl", "florenc": "florenc", "vysehrad": "vyšehrad",
        "smichov": "smíchovské nádraží", "karlovka": "karlovo náměstí", "pankrac": "pankrác",
        "letnany": "letňany", "cerny most": "černý most", "zlicin": "zličín",
        "hradcany": "hradčanská", "staromak": "staroměstská", "hrad": "pražský hrad",
        "castle": "pražský hrad", "airport": "letiště václava havla", "letiste": "letiště václava havla"
    ]
    
    static func correctTypo(_ query: String) -> String? {
        commonTypos[normalize(query)]
    }
}
