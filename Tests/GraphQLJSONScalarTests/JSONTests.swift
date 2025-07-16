import GraphQL
import GraphQLJSONScalar
import NIO
import OrderedCollections
import Testing

@Suite class JSONTests {
    var schema: GraphQLSchema!
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    init() async throws {
        schema = try createSchema(type: GraphQLJSONScalar)
    }

    /// should support serialization
    func testSerialize() throws {
        let result = try graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: fixture,
            eventLoopGroup: group
        ).wait()

        #expect(result.data?["rootValue"] == fixture)
        #expect(result.errors == [])
    }

    /// should support parsing values
    func testParseValue() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": fixture]
        ).wait()

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
    }

    /// should support parsing literals
    func testParseLiteral() throws {
        let result = try graphql(
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
        ).wait()

        #expect(result.data?["value"] == fixture)
        #expect(result.errors == [])
    }

    /// should handle null literal
    func testParseLiteral_Null() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query {
                value(arg: null)
            }
            """,
            eventLoopGroup: group
        ).wait()

        #expect(result.data?["value"] == .null)
        #expect(result.errors == [])
    }

    /// should handle list literal
    func testParseLiteral_List() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query {
                value(arg: [])
            }
            """,
            eventLoopGroup: group
        ).wait()

        #expect(result.data?["value"] == [])
        #expect(result.errors == [])
    }

    /// should reject invalid literal
    func testParseLiteral_Invalid() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query {
                value(arg: INVALID)
            }
            """,
            eventLoopGroup: group
        ).wait()

        #expect(result.data == nil)
        #expect(result.errors.count == 1)
    }
}
