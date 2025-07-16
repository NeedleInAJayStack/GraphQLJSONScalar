import GraphQL
import GraphQLJSONScalar
import NIO
import OrderedCollections
import Testing

@Suite class JSONObjectTests {
    var schema: GraphQLSchema!
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    init() async throws {
        schema = try createSchema(type: GraphQLJSONObjectScalar)
    }

    /// should support serialization
    func testSerialize() async throws {
        let result = try await graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: fixture,
            eventLoopGroup: group
        )

        #expect(result.data?["rootValue"] == fixture)
        #expect(result.errors == [])
    }

    /// should reject string value
    func testSerialize_String() async throws {
        let result = try await graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: "foo",
            eventLoopGroup: group
        )

        #expect(result.data?["rootValue"] == .null)
        #expect(result.errors.count == 1)
    }

    /// should reject array value
    func testSerialize_Array() async throws {
        let result = try await graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: [],
            eventLoopGroup: group
        )

        #expect(result.data?["rootValue"] == .null)
        #expect(result.errors.count == 1)
    }

    /// should support parsing values
    func testParseValue() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query($arg: JSONObject!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": fixture]
        )

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
    }

    /// should reject string value
    func testParseValue_String() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": "foo"]
        )

        #expect(result.data?["value"] == nil)
        #expect(result.errors.count == 1)
    }

    /// should reject array value
    func testParseValue_Array() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": []]
        )

        #expect(result.data?["value"] == nil)
        #expect(result.errors.count == 1)
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
            """,
            eventLoopGroup: group
        )

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
    }

    /// should reject string value
    func testParseLiteral_String() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(arg: "foo")
            }
            """,
            eventLoopGroup: group
        )

        #expect(result.data?["value"] == nil)
        #expect(result.errors.count == 1)
    }

    /// should reject array literal
    func testParseLiteral_Array() async throws {
        let result = try await graphql(
            schema: schema,
            request: """
            query {
                value(arg: [])
            }
            """,
            eventLoopGroup: group
        )

        #expect(result.data?["value"] == nil)
        #expect(result.errors.count == 1)
    }
}
