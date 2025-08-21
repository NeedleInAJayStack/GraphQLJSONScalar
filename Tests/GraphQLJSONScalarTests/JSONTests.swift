import GraphQL
import GraphQLJSONScalar
import OrderedCollections
import XCTest

final class JSONTests: XCTestCase {
    var schema: GraphQLSchema!

    override func setUp() async throws {
        schema = try createSchema(type: GraphQLJSONScalar)
    }

    /// should support serialization
    func testSerialize() async throws {
        let result = try await graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: fixture
        )

        XCTAssertEqual(
            result.data?["rootValue"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should support parsing values
    func testParseValue() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            variableValues: ["arg": fixture]
        )

        XCTAssertEqual(
            result.data?["value"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should support parsing literals
    func testParseLiteral() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(
                    arg: {
                        string: "string"
                        int: 3
                        float: 3.14
                        true: true
                        false: false
                        null: null
                        object: {
                            string: "string"
                            int: 3
                            float: 3.14
                            true: true
                            false: false
                            null: null
                        }
                        array: ["string", 3, 3.14, true, false, null]
                    }
                )
            }
            """
        )

        XCTAssertEqual(
            result.data?["value"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should handle null literal
    func testParseLiteral_Null() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(arg: null)
            }
            """
        )

        XCTAssertEqual(
            result.data?["value"],
            .null
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should handle list literal
    func testParseLiteral_List() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(arg: [])
            }
            """
        )

        XCTAssertEqual(
            result.data?["value"],
            []
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should reject invalid literal
    func testParseLiteral_Invalid() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(arg: INVALID)
            }
            """
        )

        XCTAssertEqual(result.data, nil)

        XCTAssertEqual(
            result.errors.count,
            1
        )
    }
}
