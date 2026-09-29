import Foundation

/// Normalizes food and brand names returned from search APIs.
///
/// FatSecret, USDA, and others often emit ALL CAPS names. Those are converted
/// to title case. Mixed-case names (including ones that keep a short acronym
/// such as "BBQ") are left untouched — we only transform when every letter in
/// the string is uppercase.
enum FoodNameFormatting {
    /// Title-cases `raw` when it is entirely uppercase; otherwise returns it as-is.
    static func displayName(from raw: String) -> String {
        guard isEntirelyUppercase(raw) else { return raw }
        return titleCase(raw)
    }

    /// True when the string has at least one letter and every letter is uppercase.
    /// Digits and punctuation do not affect the result.
    static func isEntirelyUppercase(_ string: String) -> Bool {
        var sawLetter = false
        for character in string where character.isLetter {
            sawLetter = true
            if !character.isUppercase { return false }
        }
        return sawLetter
    }

    /// Capitalizes the first letter of each word and lowercases the rest.
    ///
    /// Word boundaries include whitespace, hyphens, and parentheses. Apostrophes
    /// stay inside the current word so "MCDONALD'S" becomes "Mcdonald's"
    /// rather than "Mcdonald'S".
    static func titleCase(_ string: String) -> String {
        var output = ""
        output.reserveCapacity(string.count)
        var capitalizeNext = true

        for character in string {
            if character.isLetter {
                if capitalizeNext {
                    output.append(contentsOf: String(character).uppercased())
                } else {
                    output.append(contentsOf: String(character).lowercased())
                }
                capitalizeNext = false
            } else {
                output.append(character)
                if isApostrophe(character) {
                    capitalizeNext = false
                } else {
                    capitalizeNext = true
                }
            }
        }

        return output
    }

    private static func isApostrophe(_ character: Character) -> Bool {
        character == "'" || character == "\u{2019}" || character == "\u{02BC}"
    }
}

extension String {
    /// Search-display form of a food or brand name: title case if ALL CAPS, else unchanged.
    var foodDisplayName: String {
        FoodNameFormatting.displayName(from: self)
    }
}
