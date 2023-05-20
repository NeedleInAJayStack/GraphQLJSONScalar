import Foundation
import GraphQL
import Graphiti
import GraphitiJSONScalar
import OrderedCollections
import NIO
import XCTest

struct TestResolver {
    func nullLiteral(context: NoContext, arguments _: NoArguments) -> Map {
        return .null
    }
    func boolLiteral(context: NoContext, arguments _: NoArguments) -> Map {
        return true
    }
    func numberLiteral(context: NoContext, arguments _: NoArguments) -> Map {
        return 42
    }
    func stringLiteral(context: NoContext, arguments _: NoArguments) -> Map {
        return "Fourty-two"
    }
    func array(context: NoContext, arguments _: NoArguments) -> Map {
        return .array([
            .dictionary(["number": 42, "null": .null]),
            .dictionary(["string": "Fourty-two", "null": .null])
        ])
    }
    func dictionary(context: NoContext, arguments _: NoArguments) -> Map {
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
                ]
            ]
        ])
    }
    
    func value(context: NoContext, arguments: ValueArguments) throws -> Map {
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
    
    func testNullLiteral() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ nullLiteral }",
                context: api.context,
                on: group
            ).wait(),
            .init(data: ["nullLiteral": .null])
        )
    }
    
    func testBoolLiteral() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ boolLiteral }",
                context: api.context,
                on: group
            ).wait(),
            .init(data: ["boolLiteral": true])
        )
    }
    
    func testNumberLiteral() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ numberLiteral }",
                context: api.context,
                on: group
            ).wait(),
            .init(data: ["numberLiteral": 42])
        )
    }
    
    func testStringLiteral() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ stringLiteral }",
                context: api.context,
                on: group
            ).wait(),
            .init(data: ["stringLiteral": "Fourty-two"])
        )
    }
    
    func testArray() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ array }",
                context: api.context,
                on: group
            ).wait(),
            .init(data: ["array": [
                ["number": 42, "null": .null],
                ["string": "Fourty-two", "null": .null]
            ]])
        )
    }
    
    func testDictionary() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ dictionary }",
                context: api.context,
                on: group
            ).wait(),
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
                        ]
                    ]
                ]
            ])
        )
    }
    
    /// should support parsing values
    func testParseValue() throws {
        let result = try api.execute(
            request: """
            query($arg: JSON!) {
                value(arg: $arg)
            }
            """,
            context: api.context,
            on: group,
            variables: ["arg": fixture]
        ).wait()
        
        let value = try XCTUnwrap(result.data?["value"])
        // Compare by description because ordering doesn't matter, but will cause us to fail
        XCTAssertEqual(value.description, fixture.description)
        XCTAssertEqual(result.errors, [])
    }
    
    /// should support parsing literals
    func testParseLiteral() throws {
        let result = try api.execute(
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
        ).wait()
        
        let value = try XCTUnwrap(result.data?["value"])
        // Compare by description because ordering doesn't matter, but will cause us to fail
        XCTAssertEqual(value.description, fixture.description)
        XCTAssertEqual(result.errors, [])
    }
    
    /// should handle null literal
    func testParseLiteral_Null() throws {
        let result = try api.execute(
            request: """
            query {
                value(arg: null)
            }
            """,
            context: api.context,
            on: group
        ).wait()
        
        XCTAssertEqual(
            result.data?["value"],
            .null
        )
        XCTAssertEqual(result.errors, [])
    }
    
    /// should handle list literal
    func testParseLiteral_List() throws {
        let result = try api.execute(
            request: """
            query {
                value(arg: [])
            }
            """,
            context: api.context,
            on: group
        ).wait()
        
        XCTAssertEqual(
            result.data?["value"],
            []
        )
        XCTAssertEqual(result.errors, [])
    }
    
    /// should handle list literal
    func testParseLiteral_Invalid() throws {
        let result = try api.execute(
            request: """
            query {
                value(arg: INVALID)
            }
            """,
            context: api.context,
            on: group
        ).wait()
        
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
