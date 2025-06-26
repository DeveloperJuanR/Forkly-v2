//
//  StringUtilities.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Foundation

extension String {
    func splitIntoSteps() -> [String] {
        let cleaned = self.cleanHTMLTags()
        // Break on periods followed by a space and a capital letter
        let pattern = #"(?<=[.?!])\s+(?=[A-Z])"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: cleaned.utf16.count)
        let matches = regex?.matches(in: cleaned, options: [], range: range) ?? []

        var lastIndex = cleaned.startIndex
        var results: [String] = []

        for match in matches {
            let nsRange = match.range
            let swiftRange = Range(nsRange, in: cleaned)!
            let step = String(cleaned[lastIndex..<swiftRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            results.append(step)
            lastIndex = swiftRange.lowerBound
        }

        // Add remaining text
        let lastStep = String(cleaned[lastIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastStep.isEmpty {
            results.append(lastStep)
        }

        return results
    }
    
    func cleanHTMLTags() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return attributed.string
        }
        return self
    }
} 