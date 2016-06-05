import Foundation

public func XCTAssertEqual<T: Equatable>(lhs: T, _ rhs: T) -> String {
    let icon = lhs == rhs ? "✔" : "❌"
    let matcher = lhs == rhs ? "is" : "is not"
    return "\(icon) '\(lhs)' \(matcher) equal to '\(rhs)'"
}

public func XCTAssert(condition: Bool) -> String {
    return "\(condition)"
}
