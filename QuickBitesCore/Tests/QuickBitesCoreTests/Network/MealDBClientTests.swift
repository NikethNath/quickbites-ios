import Testing
import Foundation
@testable import QuickBitesCore

@Suite struct MealDBClientTests {
    @Test func categoriesMapToDomain() async throws {
        let transport = FakeTransport.json("""
        {
          "categories": [
            {
              "idCategory": "1",
              "strCategory": "Beef",
              "strCategoryThumb": "https://www.themealdb.com/images/category/beef.png",
              "strCategoryDescription": "Beef is the culinary name for meat from cattle."
            }
          ]
        }
        """)
        let client = MealDBClient(transport: transport)

        let categories = try await client.categories()

        #expect(categories == [
            Category(id: "1", name: "Beef", thumbURL: URL(string: "https://www.themealdb.com/images/category/beef.png"))
        ])
    }

    @Test func filterMealsNullReturnsEmptyArray() async throws {
        let transport = FakeTransport.json(#"{ "meals": null }"#)
        let client = MealDBClient(transport: transport)

        let meals = try await client.meals(inCategory: "Nonexistent")

        #expect(meals.isEmpty)
    }

    @Test func searchMapsToDomainWithPrice() async throws {
        let transport = FakeTransport.json("""
        {
          "meals": [
            { "idMeal": "52977", "strMeal": "Corba", "strMealThumb": "https://www.themealdb.com/images/media/meals/corba.jpg" }
          ]
        }
        """)
        let client = MealDBClient(transport: transport)

        let meals = try await client.search(query: "corba")

        #expect(meals.count == 1)
        #expect(meals[0].id == "52977")
        #expect(meals[0].name == "Corba")
        #expect(meals[0].priceInr == priceInr(mealId: "52977"))
    }

    @Test func detailFiltersBlankAndNilIngredientSlots() async throws {
        let transport = FakeTransport.json("""
        {
          "meals": [
            {
              "idMeal": "52977",
              "strMeal": "Corba",
              "strMealThumb": "https://www.themealdb.com/images/media/meals/corba.jpg",
              "strArea": "Turkish",
              "strCategory": "Vegetarian",
              "strInstructions": "Boil the lentils.",
              "strIngredient1": "Lentils",
              "strMeasure1": "1 cup",
              "strIngredient2": "",
              "strMeasure2": "",
              "strIngredient3": null,
              "strMeasure3": null,
              "strIngredient4": "Onion",
              "strMeasure4": "1"
            }
          ]
        }
        """)
        let client = MealDBClient(transport: transport)

        let detail = try #require(try await client.detail(id: "52977"))

        #expect(detail.ingredients == [
            Ingredient(name: "Lentils", measure: "1 cup"),
            Ingredient(name: "Onion", measure: "1"),
        ])
        #expect(detail.area == "Turkish")
        #expect(detail.instructions == "Boil the lentils.")
    }

    @Test func detailReturnsNilWhenMealsIsNull() async throws {
        let transport = FakeTransport.json(#"{ "meals": null }"#)
        let client = MealDBClient(transport: transport)

        let detail = try await client.detail(id: "0")

        #expect(detail == nil)
    }
}

@Suite struct PriceInrTests {
    @Test func isDeterministic() {
        #expect(priceInr(mealId: "52977") == priceInr(mealId: "52977"))
    }

    @Test func isWithinExpectedRange() {
        let ids = ["1", "52977", "53049", "999999"]
        for id in ids {
            let price = priceInr(mealId: id)
            #expect(price >= 99)
            #expect(price <= 499)
        }
    }

    @Test func matchesSpecFormula() {
        // 99 + Int((Int64(mealId)! * 2654435761) % 401) with nonnegative modulo
        let n: Int64 = 52977
        let expected = 99 + Int((((n &* 2_654_435_761) % 401) + 401) % 401)
        #expect(priceInr(mealId: "52977") == expected)
    }
}
