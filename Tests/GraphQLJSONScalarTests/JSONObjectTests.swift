import GraphQL
import GraphQLJSONScalar
import NIO
import OrderedCollections
import XCTest

final class JSONObjectTests: XCTestCase {
    var schema: GraphQLSchema!
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    override func setUp() async throws {
        schema = try createSchema(type: GraphQLJSONObjectScalar)
    }

    /// should support serialization
    func testSerialize() throws {
        let result = try graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: fixture,
            eventLoopGroup: group
        ).wait()

        XCTAssertEqual(
            result.data?["rootValue"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should reject string value
    func testSerialize_String() throws {
        let result = try graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: "foo",
            eventLoopGroup: group
        ).wait()

        XCTAssertEqual(result.data?["rootValue"], .null)
        XCTAssertEqual(
            result.errors.count,
            1
        )
    }

    /// should reject array value
    func testSerialize_Array() throws {
        let result = try graphql(
            schema: schema,
            request: "{ rootValue }",
            rootValue: [],
            eventLoopGroup: group
        ).wait()

        XCTAssertEqual(result.data?["rootValue"], .null)
        XCTAssertEqual(
            result.errors.count,
            1
        )
    }

    /// should support parsing values
    func testParseValue() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query($arg: JSONObject!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": fixture]
        ).wait()

        XCTAssertEqual(
            result.data?["value"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should reject string value
    func testParseValue_String() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": "foo"]
        ).wait()

        XCTAssertEqual(result.data?["value"], nil)
        XCTAssertEqual(
            result.errors.count,
            1
        )
    }

    /// should reject array value
    func testParseValue_Array() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            eventLoopGroup: group,
            variableValues: ["arg": []]
        ).wait()

        XCTAssertEqual(result.data?["value"], nil)
        XCTAssertEqual(
            result.errors.count,
            1
        )
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

        XCTAssertEqual(
            result.data?["value"],
            fixture
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should reject string value
    func testParseLiteral_String() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query {
                value(arg: "foo")
            }
            """,
            eventLoopGroup: group
        ).wait()

        XCTAssertEqual(result.data?["value"], nil)
        XCTAssertEqual(
            result.errors.count,
            1
        )
    }

    /// should reject array literal
    func testParseLiteral_Array() throws {
        let result = try graphql(
            schema: schema,
            request: """
            query {
                value(arg: [])
            }
            """,
            eventLoopGroup: group
        ).wait()

        XCTAssertEqual(result.data?["value"], nil)
        XCTAssertEqual(
            result.errors.count,
            1
        )
    }
}
