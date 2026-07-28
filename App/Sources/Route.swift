enum Route: Hashable {
    case browseCategory(id: String, name: String)
    case browseSearch(query: String)
    case detail(mealId: String)
}
