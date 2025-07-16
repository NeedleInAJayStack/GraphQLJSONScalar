import GraphQL
import GraphQLJSONScalar
import OrderedCollections
import Testing

@Suite class JSONTests {
    var schema: GraphQLSchema!

    init() async throws {
        schema = try createSchema(type: GraphQLJSONScalar)
    }

    /// should support serialization
    func testSerialize() async throws {
        let result = try await graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: fixture
        )

        #expect(result.data?["rootValue"] == fixture)
        #expect(result.errors == [])
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

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
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

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
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

        #expect(result.data?["value"] == .null)
        #expect(result.errors == [])
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

        #expect(result.data?["value"] == [])
        #expect(result.errors == [])
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

        #expect(result.data == nil)
        #expect(result.errors.count == 1)
    }
}
