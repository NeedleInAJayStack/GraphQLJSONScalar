import GraphQL
import GraphQLJSONScalar
import NIO
import OrderedCollections
import XCTest

func createSchema(type: GraphQLScalarType) throws -> GraphQLSchema {
    return try GraphQLSchema(
        query: GraphQLObjectType(
            name: "Query",
            fields: [
                "value": GraphQLField(
                    type: type,
                    args: [
                        "arg": GraphQLArgument(type: type),
                    ],
                    resolve: { _, args, _, _ in
                        switch args {
                        case let .dictionary(args):
                            return args["arg"]
                        default:
                            throw GraphQLError(message: "Expected object")
                        }
                    }
                ),
                "rootValue": GraphQLField(
                    type: type,
                    resolve: { obj, _, _, _ in
                        obj
                    }
                ),
            ]
        ),

        types: [
            GraphQLJSONScalar,
            GraphQLJSONObjectScalar,
        ]
    )
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
