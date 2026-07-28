import Foundation

struct CategoriesResponseDTO: Decodable {
    let categories: [CategoryDTO]
}

struct CategoryDTO: Decodable {
    let idCategory: String
    let strCategory: String
    let strCategoryThumb: String?

    func toDomain() -> Category {
        Category(id: idCategory, name: strCategory, thumbURL: strCategoryThumb.flatMap(URL.init(string:)))
    }
}

struct MealsResponseDTO: Decodable {
    let meals: [MealSummaryDTO]?
}

struct MealSummaryDTO: Decodable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String?

    func toDomain() -> MealSummary {
        MealSummary(
            id: idMeal,
            name: strMeal,
            thumbURL: strMealThumb.flatMap(URL.init(string:)),
            priceInr: priceInr(mealId: idMeal)
        )
    }
}

struct IngredientDTO {
    let name: String
    let measure: String

    func toDomain() -> Ingredient {
        Ingredient(name: name, measure: measure)
    }
}

struct MealDetailResponseDTO: Decodable {
    let meals: [MealDetailDTO]?
}

struct MealDetailDTO: Decodable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String?
    let strArea: String?
    let strCategory: String?
    let strInstructions: String?
    let ingredients: [IngredientDTO]

    private enum CodingKeys: String, CodingKey {
        case idMeal, strMeal, strMealThumb, strArea, strCategory, strInstructions
    }

    private struct SlotKey: CodingKey {
        let stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        idMeal = try container.decode(String.self, forKey: .idMeal)
        strMeal = try container.decode(String.self, forKey: .strMeal)
        strMealThumb = try container.decodeIfPresent(String.self, forKey: .strMealThumb)
        strArea = try container.decodeIfPresent(String.self, forKey: .strArea)
        strCategory = try container.decodeIfPresent(String.self, forKey: .strCategory)
        strInstructions = try container.decodeIfPresent(String.self, forKey: .strInstructions)

        let slots = try decoder.container(keyedBy: SlotKey.self)
        var pairs: [IngredientDTO] = []
        for n in 1...20 {
            guard let nameKey = SlotKey(stringValue: "strIngredient\(n)"),
                  let measureKey = SlotKey(stringValue: "strMeasure\(n)") else { continue }
            let rawName = try? slots.decodeIfPresent(String.self, forKey: nameKey)
            let rawMeasure = try? slots.decodeIfPresent(String.self, forKey: measureKey)
            let name = (rawName ?? nil)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let measure = (rawMeasure ?? nil)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { continue }
            pairs.append(IngredientDTO(name: name, measure: measure))
        }
        ingredients = pairs
    }

    func toDomain() -> MealDetail {
        MealDetail(
            id: idMeal,
            name: strMeal,
            thumbURL: strMealThumb.flatMap(URL.init(string:)),
            priceInr: priceInr(mealId: idMeal),
            area: strArea,
            category: strCategory,
            instructions: strInstructions,
            ingredients: ingredients.map { $0.toDomain() }
        )
    }
}
