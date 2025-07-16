import Foundation
import Graphiti
import GraphitiJSONScalar
import GraphQL
import NIO
import OrderedCollections
import XCTest

struct TestResolver {
    func nullLiteral(context _: NoContext, arguments _: NoArguments) -> Map {
        return .null
    }

    func boolLiteral(context _: NoContext, arguments _: NoArguments) -> Map {
        return true
    }

    func numberLiteral(context _: NoContext, arguments _: NoArguments) -> Map {
        return 42
    }

    func stringLiteral(context _: NoContext, arguments _: NoArguments) -> Map {
        return "Fourty-two"
    }

    func array(context _: NoContext, arguments _: NoArguments) -> Map {
        return .array([
            .dictionary(["number": 42, "null": .null]),
            .dictionary(["string": "Fourty-two", "null": .null]),
        ])
    }

    func dictionary(context _: NoContext, arguments _: NoArguments) -> Map {
        return .dictionary([
            "null": .null,
            "bool": true,
            "number": 42,
            "string": "Fourty-two",
            "dictionary": [
                "null": .null,
                "bool": true,
                "number": 42,
                "string": "Fourty-two",
            ],
            "array": [
                [
                    "null": .null,
                    "bool": true,
                    "number": 42,
                    "string": "Fourty-two",
                ],
            ],
        ])
    }

    func value(context _: NoContext, arguments: ValueArguments) throws -> Map {
        return arguments.arg ?? .null
    }
}

struct ValueArguments: Codable {
    let arg: Map?
}

struct TestAPI: API {
    let resolver = TestResolver()
    let context: () = NoContext()

    let schema = try! Schema<TestResolver, NoContext> {
        Scalar.json()
        Query {
            Field("nullLiteral", at: TestResolver.nullLiteral)
            Field("boolLiteral", at: TestResolver.boolLiteral)
            Field("numberLiteral", at: TestResolver.numberLiteral)
            Field("stringLiteral", at: TestResolver.stringLiteral)
            Field("array", at: TestResolver.array)
            Field("dictionary", at: TestResolver.dictionary)
            Field("value", at: TestResolver.value) {
                Argument("arg", at: \.arg)
            }
        }
    }
}

class GraphitiJSONScalarTests: XCTestCase {
    private let api = TestAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    func testNullLiteral() async throws {
        let result = try await api.execute(
            request: "{ nullLiteral }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: ["nullLiteral": .null])
        )
    }

    func testBoolLiteral() async throws {
        let result = try await api.execute(
            request: "{ boolLiteral }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: ["boolLiteral": true])
        )
    }

    func testNumberLiteral() async throws {
        let result = try await api.execute(
            request: "{ numberLiteral }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: ["numberLiteral": 42])
        )
    }

    func testStringLiteral() async throws {
        let result = try await api.execute(
            request: "{ stringLiteral }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: ["stringLiteral": "Fourty-two"])
        )
    }

    func testArray() async throws {
        let result = try await api.execute(
            request: "{ array }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: ["array": [
                ["number": 42, "null": .null],
                ["string": "Fourty-two", "null": .null],
            ]])
        )
    }

    func testDictionary() async throws {
        let result = try await api.execute(
            request: "{ dictionary }",
            context: api.context,
            on: group
        )
        XCTAssertEqual(
            result,
            .init(data: [
                "dictionary": [
                    "null": .null,
                    "bool": true,
                    "number": 42,
                    "string": "Fourty-two",
                    "dictionary": [
                        "null": .null,
                        "bool": true,
                        "number": 42,
                        "string": "Fourty-two",
                    ],
                    "array": [
                        [
                            "null": .null,
                            "bool": true,
                            "number": 42,
                            "string": "Fourty-two",
                        ],
                    ],
                ],
            ])
        )
    }

    /// should support parsing values
    func testParseValue() async throws {
        let result = try await api.execute(
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            context: api.context,
            on: group,
            variables: ["arg": fixture]
        )

        let value = try XCTUnwrap(result.data?["value"])
        try XCTAssertEqualIgnoringOrder(value, fixture)
        XCTAssertEqual(result.errors, [GraphQLError]())
    }

    /// should support parsing literals
    func testParseLiteral() async throws {
        let result = try await api.execute(
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
            context: api.context,
            on: group
        )

        let value = try XCTUnwrap(result.data?["value"])
        try XCTAssertEqualIgnoringOrder(value, fixture)
        XCTAssertEqual(result.errors, [])
    }

    /// should handle null literal
    func testParseLiteral_Null() async throws {
        let result = try await api.execute(
            request: """
            query {
                value(arg: null)
            }
            """,
            context: api.context,
            on: group
        )

        XCTAssertEqual(
            result.data?["value"],
            .null
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should handle list literal
    func testParseLiteral_List() async throws {
        let result = try await api.execute(
            request: """
            query {
                value(arg: [])
            }
            """,
            context: api.context,
            on: group
        )

        XCTAssertEqual(
            result.data?["value"],
            []
        )
        XCTAssertEqual(result.errors, [])
    }

    /// should handle list literal
    func testParseLiteral_Invalid() async throws {
        let result = try await api.execute(
            request: """
            query {
                value(arg: INVALID)
            }
            """,
            context: api.context,
            on: group
        )

        XCTAssertEqual(result.data, nil)

        XCTAssertEqual(
            result.errors.count,
            1
        )
    }
}

let fixture = Map.dictionary([
    "string": "string",
    "int": 3,
    "float": 3.14,
    "true": true,
    "false": false,
    "null": nil,
    "object": [
        "string": "string",
        "int": 3,
        "float": 3.14,
        "true": true,
        "false": false,
        "null": nil,
    ],
    "array": ["string", 3, 3.14, true, false, nil],
])

// Checks for equality while ignoring order. We compare Maps this way because pure JSON doesn't care about order
func XCTAssertEqualIgnoringOrder(_ lhs: Map, _ rhs: Map, file _: StaticString = #filePath, line _: UInt = #line) throws {
    switch (lhs, rhs) {
    case (.undefined, .undefined):
        return
    case (.null, .null):
        return
    case let (.bool(l), .bool(r)):
        XCTAssertEqual(l, r)
    case let (.number(l), .number(r)):
        XCTAssertEqual(l, r)
    case let (.string(l), .string(r)):
        XCTAssertEqual(l, r)
    case let (.array(l), .array(r)):
        XCTAssertEqual(l, r)
    case let (.dictionary(l), .dictionary(r)):
        var lUnordered = [String: Map]()
        l.forEach { lUnordered[$0.0] = $0.1 }
        var rUnordered = [String: Map]()
        r.forEach { rUnordered[$0.0] = $0.1 }

        XCTAssertEqual(lUnordered.keys, rUnordered.keys)

        for key in lUnordered.keys {
            let lhsValue = try XCTUnwrap(lUnordered[key])
            let rhsValue = try XCTUnwrap(rUnordered[key])
            try XCTAssertEqualIgnoringOrder(lhsValue, rhsValue)
        }
    default:
        XCTFail()
    }
}
