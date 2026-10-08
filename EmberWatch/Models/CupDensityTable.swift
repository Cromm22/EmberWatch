import Foundation

/// One density-table row. `phrases` are alternative names for the same food;
/// the longest matching phrase wins across the whole table.
struct CupDensityEntry: Equatable, Sendable {
    let phrases: [String]
    let gramsPerCup: Double
}

/// USDA-style grams per US cup, matched by keywords in a food name.
/// Split into small arrays so the Swift type checker stays happy.
enum CupDensityTable: Sendable {
    /// Case-insensitive; most specific (longest) matching phrase wins.
    static func gramsPerCup(matching foodName: String) -> Double? {
        let haystack = foodName.lowercased()
        guard !haystack.isEmpty else { return nil }
        var bestLength = 0
        var bestGrams: Double?
        for entry in entries {
            for phrase in entry.phrases {
                let length = phrase.count
                guard length > bestLength else { continue }
                if phraseMatches(phrase, haystack: haystack) {
                    bestLength = length
                    bestGrams = entry.gramsPerCup
                }
            }
        }
        return bestGrams
    }

    /// Whole-phrase match with letter boundaries, or every token present as a word.
    static func phraseMatches(_ phrase: String, haystack: String) -> Bool {
        let needle = phrase.lowercased()
        if needle.isEmpty { return false }
        if containsWord(needle, in: haystack) {
            return true
        }
        let tokens = needle.split(whereSeparator: { $0 == " " || $0 == "," }).map { String($0) }
        if tokens.count < 2 { return false }
        for token in tokens {
            if token.isEmpty { continue }
            if !containsWord(token, in: haystack) {
                return false
            }
        }
        return true
    }

    static func containsWord(_ word: String, in haystack: String) -> Bool {
        guard !word.isEmpty else { return false }
        var searchStart = haystack.startIndex
        while searchStart < haystack.endIndex,
              let range = haystack.range(of: word, range: searchStart..<haystack.endIndex) {
            let beforeOK: Bool
            if range.lowerBound == haystack.startIndex {
                beforeOK = true
            } else {
                let previous = haystack.index(before: range.lowerBound)
                beforeOK = !haystack[previous].isLetter
            }
            let afterOK: Bool
            if range.upperBound == haystack.endIndex {
                afterOK = true
            } else {
                afterOK = !haystack[range.upperBound].isLetter
            }
            if beforeOK && afterOK {
                return true
            }
            searchStart = range.upperBound
        }
        return false
    }

    static let entries: [CupDensityEntry] = makeEntries()

    private static func makeEntries() -> [CupDensityEntry] {
        var all: [CupDensityEntry] = []
        all.append(contentsOf: sweeteners())
        all.append(contentsOf: flours())
        all.append(contentsOf: grains())
        all.append(contentsOf: legumes())
        all.append(contentsOf: dairy())
        all.append(contentsOf: fatsAndNuts())
        all.append(contentsOf: vegetables())
        all.append(contentsOf: fruit())
        all.append(contentsOf: drinksAndOther())
        return all
    }

    private static func sweeteners() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(
                phrases: ["powdered sugar", "confectioners sugar", "confectioner's sugar", "icing sugar"],
                gramsPerCup: 120
            ),
            CupDensityEntry(
                phrases: ["brown sugar packed", "packed brown sugar", "brown sugar"],
                gramsPerCup: 220
            ),
            CupDensityEntry(
                phrases: ["granulated sugar", "white sugar", "cane sugar", "sugar"],
                gramsPerCup: 200
            ),
            CupDensityEntry(phrases: ["honey"], gramsPerCup: 340),
            CupDensityEntry(phrases: ["maple syrup"], gramsPerCup: 315),
            CupDensityEntry(phrases: ["molasses"], gramsPerCup: 337),
            CupDensityEntry(phrases: ["corn syrup"], gramsPerCup: 328),
            CupDensityEntry(phrases: ["agave"], gramsPerCup: 336)
        ]
        return rows
    }

    private static func flours() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(
                phrases: ["all-purpose flour", "all purpose flour", "plain flour"],
                gramsPerCup: 125
            ),
            CupDensityEntry(phrases: ["whole wheat flour", "wholewheat flour"], gramsPerCup: 120),
            CupDensityEntry(phrases: ["bread flour"], gramsPerCup: 127),
            CupDensityEntry(phrases: ["cake flour"], gramsPerCup: 114),
            CupDensityEntry(phrases: ["almond flour", "almond meal"], gramsPerCup: 96),
            CupDensityEntry(phrases: ["coconut flour"], gramsPerCup: 112),
            CupDensityEntry(phrases: ["corn starch", "cornstarch"], gramsPerCup: 128),
            CupDensityEntry(phrases: ["cornmeal", "corn meal"], gramsPerCup: 156),
            CupDensityEntry(phrases: ["flour"], gramsPerCup: 125)
        ]
        return rows
    }

    private static func grains() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(
                phrases: ["rolled oats", "old fashioned oats", "dry oats", "uncooked oats", "oats dry"],
                gramsPerCup: 81
            ),
            CupDensityEntry(
                phrases: ["oatmeal cooked", "cooked oatmeal", "cooked oats"],
                gramsPerCup: 234
            ),
            CupDensityEntry(phrases: ["oats", "oatmeal"], gramsPerCup: 81),
            CupDensityEntry(
                phrases: ["uncooked rice", "dry rice", "raw rice", "rice uncooked"],
                gramsPerCup: 185
            ),
            CupDensityEntry(
                phrases: ["cooked rice", "rice cooked", "steamed rice"],
                gramsPerCup: 158
            ),
            CupDensityEntry(phrases: ["brown rice cooked"], gramsPerCup: 195),
            CupDensityEntry(phrases: ["brown rice"], gramsPerCup: 190),
            CupDensityEntry(phrases: ["rice"], gramsPerCup: 158),
            CupDensityEntry(phrases: ["quinoa cooked", "cooked quinoa"], gramsPerCup: 185),
            CupDensityEntry(phrases: ["quinoa"], gramsPerCup: 170),
            CupDensityEntry(
                phrases: ["pasta cooked", "cooked pasta", "cooked spaghetti", "cooked noodles"],
                gramsPerCup: 140
            ),
            CupDensityEntry(phrases: ["pasta", "spaghetti", "noodles"], gramsPerCup: 91),
            CupDensityEntry(phrases: ["couscous cooked", "cooked couscous"], gramsPerCup: 157),
            CupDensityEntry(phrases: ["couscous"], gramsPerCup: 173),
            CupDensityEntry(phrases: ["barley cooked", "cooked barley"], gramsPerCup: 157),
            CupDensityEntry(phrases: ["barley"], gramsPerCup: 200)
        ]
        return rows
    }

    private static func legumes() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(phrases: ["black beans"], gramsPerCup: 172),
            CupDensityEntry(phrases: ["kidney beans"], gramsPerCup: 177),
            CupDensityEntry(phrases: ["chickpeas", "garbanzo"], gramsPerCup: 164),
            CupDensityEntry(phrases: ["lentils cooked", "cooked lentils"], gramsPerCup: 198),
            CupDensityEntry(phrases: ["lentils"], gramsPerCup: 198),
            CupDensityEntry(phrases: ["beans cooked", "cooked beans", "beans"], gramsPerCup: 172),
            CupDensityEntry(phrases: ["green peas", "peas cooked", "cooked peas"], gramsPerCup: 160),
            CupDensityEntry(phrases: ["edamame"], gramsPerCup: 155)
        ]
        return rows
    }

    private static func dairy() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(phrases: ["almond milk"], gramsPerCup: 240),
            CupDensityEntry(phrases: ["oat milk"], gramsPerCup: 240),
            CupDensityEntry(phrases: ["soy milk"], gramsPerCup: 243),
            CupDensityEntry(phrases: ["coconut milk"], gramsPerCup: 240),
            CupDensityEntry(
                phrases: ["whole milk", "2% milk", "2 percent milk", "skim milk", "1% milk", "nonfat milk", "milk"],
                gramsPerCup: 244
            ),
            CupDensityEntry(
                phrases: ["heavy cream", "heavy whipping cream", "whipping cream"],
                gramsPerCup: 238
            ),
            CupDensityEntry(phrases: ["half and half", "half-and-half"], gramsPerCup: 242),
            CupDensityEntry(phrases: ["greek yogurt", "greek yoghurt"], gramsPerCup: 227),
            CupDensityEntry(phrases: ["yogurt", "yoghurt"], gramsPerCup: 245),
            CupDensityEntry(phrases: ["sour cream"], gramsPerCup: 230),
            CupDensityEntry(phrases: ["cottage cheese"], gramsPerCup: 226),
            CupDensityEntry(phrases: ["cream cheese"], gramsPerCup: 232),
            CupDensityEntry(
                phrases: ["shredded cheese", "grated cheese", "cheese shredded"],
                gramsPerCup: 113
            ),
            CupDensityEntry(phrases: ["parmesan"], gramsPerCup: 100),
            CupDensityEntry(phrases: ["butter"], gramsPerCup: 227),
            CupDensityEntry(phrases: ["margarine"], gramsPerCup: 218)
        ]
        return rows
    }

    private static func fatsAndNuts() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(
                phrases: ["olive oil", "vegetable oil", "canola oil", "coconut oil", "oil"],
                gramsPerCup: 218
            ),
            CupDensityEntry(phrases: ["peanut butter"], gramsPerCup: 258),
            CupDensityEntry(phrases: ["almond butter"], gramsPerCup: 250),
            CupDensityEntry(phrases: ["mayonnaise", "mayo"], gramsPerCup: 220),
            CupDensityEntry(phrases: ["almonds"], gramsPerCup: 143),
            CupDensityEntry(phrases: ["walnuts"], gramsPerCup: 117),
            CupDensityEntry(phrases: ["peanuts"], gramsPerCup: 146),
            CupDensityEntry(phrases: ["cashews"], gramsPerCup: 137),
            CupDensityEntry(phrases: ["pecans"], gramsPerCup: 109),
            CupDensityEntry(phrases: ["pistachios"], gramsPerCup: 123),
            CupDensityEntry(phrases: ["chia seeds", "chia"], gramsPerCup: 168),
            CupDensityEntry(phrases: ["flaxseed", "flax seed"], gramsPerCup: 168),
            CupDensityEntry(phrases: ["sunflower seeds"], gramsPerCup: 140),
            CupDensityEntry(phrases: ["pumpkin seeds"], gramsPerCup: 129)
        ]
        return rows
    }

    private static func vegetables() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(phrases: ["spinach"], gramsPerCup: 30),
            CupDensityEntry(phrases: ["lettuce"], gramsPerCup: 47),
            CupDensityEntry(phrases: ["kale"], gramsPerCup: 21),
            CupDensityEntry(phrases: ["broccoli"], gramsPerCup: 91),
            CupDensityEntry(phrases: ["carrots", "carrot"], gramsPerCup: 128),
            CupDensityEntry(phrases: ["celery"], gramsPerCup: 101),
            CupDensityEntry(phrases: ["onion", "onions"], gramsPerCup: 160),
            CupDensityEntry(phrases: ["tomatoes", "tomato"], gramsPerCup: 180),
            CupDensityEntry(phrases: ["cucumber"], gramsPerCup: 104),
            CupDensityEntry(phrases: ["bell pepper", "peppers", "pepper"], gramsPerCup: 149),
            CupDensityEntry(phrases: ["mushrooms", "mushroom"], gramsPerCup: 70),
            CupDensityEntry(phrases: ["zucchini"], gramsPerCup: 124),
            CupDensityEntry(phrases: ["corn kernels", "sweet corn"], gramsPerCup: 145),
            CupDensityEntry(phrases: ["avocado"], gramsPerCup: 150),
            CupDensityEntry(
                phrases: ["mixed vegetables", "chopped vegetables"],
                gramsPerCup: 182
            ),
            CupDensityEntry(phrases: ["green beans"], gramsPerCup: 125),
            CupDensityEntry(phrases: ["cabbage"], gramsPerCup: 89),
            CupDensityEntry(phrases: ["sweet potato"], gramsPerCup: 133),
            CupDensityEntry(phrases: ["potato", "potatoes"], gramsPerCup: 150)
        ]
        return rows
    }

    private static func fruit() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(phrases: ["blueberries", "blueberry"], gramsPerCup: 148),
            CupDensityEntry(phrases: ["strawberries sliced", "sliced strawberries"], gramsPerCup: 166),
            CupDensityEntry(phrases: ["strawberries", "strawberry"], gramsPerCup: 152),
            CupDensityEntry(phrases: ["raspberries", "raspberry"], gramsPerCup: 123),
            CupDensityEntry(phrases: ["blackberries", "blackberry"], gramsPerCup: 144),
            CupDensityEntry(phrases: ["grapes", "grape"], gramsPerCup: 151),
            CupDensityEntry(phrases: ["banana", "bananas"], gramsPerCup: 150),
            CupDensityEntry(phrases: ["apple", "apples"], gramsPerCup: 125),
            CupDensityEntry(phrases: ["pineapple"], gramsPerCup: 165),
            CupDensityEntry(phrases: ["mango"], gramsPerCup: 165),
            CupDensityEntry(phrases: ["watermelon"], gramsPerCup: 152),
            CupDensityEntry(phrases: ["cherries", "cherry"], gramsPerCup: 154),
            CupDensityEntry(phrases: ["peach", "peaches"], gramsPerCup: 154)
        ]
        return rows
    }

    private static func drinksAndOther() -> [CupDensityEntry] {
        let rows: [CupDensityEntry] = [
            CupDensityEntry(phrases: ["chocolate milk"], gramsPerCup: 250),
            CupDensityEntry(phrases: ["orange juice"], gramsPerCup: 248),
            CupDensityEntry(phrases: ["apple juice"], gramsPerCup: 248),
            CupDensityEntry(phrases: ["coffee"], gramsPerCup: 237),
            CupDensityEntry(phrases: ["tea"], gramsPerCup: 237),
            CupDensityEntry(phrases: ["water"], gramsPerCup: 237),
            CupDensityEntry(phrases: ["soda", "cola"], gramsPerCup: 246),
            CupDensityEntry(phrases: ["orange"], gramsPerCup: 180),
            CupDensityEntry(phrases: ["soup"], gramsPerCup: 245),
            CupDensityEntry(phrases: ["broth"], gramsPerCup: 240),
            CupDensityEntry(phrases: ["ice cream"], gramsPerCup: 132),
            CupDensityEntry(phrases: ["frozen yogurt"], gramsPerCup: 174),
            CupDensityEntry(phrases: ["chocolate chips", "chocolate chip"], gramsPerCup: 168),
            CupDensityEntry(phrases: ["cocoa powder", "cocoa"], gramsPerCup: 86),
            CupDensityEntry(phrases: ["bran flakes"], gramsPerCup: 40),
            CupDensityEntry(phrases: ["corn flakes"], gramsPerCup: 28),
            CupDensityEntry(phrases: ["cheerios", "oat cereal"], gramsPerCup: 28),
            CupDensityEntry(phrases: ["rice krispies", "crispy rice"], gramsPerCup: 28),
            CupDensityEntry(phrases: ["cereal flakes", "cereal"], gramsPerCup: 35),
            CupDensityEntry(phrases: ["granola"], gramsPerCup: 122),
            CupDensityEntry(phrases: ["raisins"], gramsPerCup: 165),
            CupDensityEntry(
                phrases: ["shredded coconut", "coconut shredded"],
                gramsPerCup: 85
            ),
            CupDensityEntry(phrases: ["breadcrumbs", "bread crumbs"], gramsPerCup: 108),
            CupDensityEntry(phrases: ["tofu"], gramsPerCup: 252),
            CupDensityEntry(phrases: ["jam", "jelly"], gramsPerCup: 320),
            CupDensityEntry(phrases: ["hummus"], gramsPerCup: 246),
            CupDensityEntry(phrases: ["popcorn"], gramsPerCup: 8),
            CupDensityEntry(phrases: ["salsa"], gramsPerCup: 260),
            CupDensityEntry(phrases: ["ketchup"], gramsPerCup: 240),
            CupDensityEntry(phrases: ["protein powder"], gramsPerCup: 120),
            CupDensityEntry(phrases: ["chocolate"], gramsPerCup: 170)
        ]
        return rows
    }
}
