import Foundation
import Graphiti
import GraphQL
import GraphQLJSONScalar
import OrderedCollections

public extension Scalar where ScalarType == Map {
    /// Returns a scalar that represents any JSON-serializable value, including scalars, arrays, and objects.
    static func json() -> Scalar<Resolver, Context, Map> {
        return Scalar(
            Map.self,
            as: "JSON",
            serialize: { value, _ in
                try map(from: value)
            },
            parseValue: { map, _ in
                map
            },
            parseLiteral: { ast, _ in
                try parseLiteral(typeName: "JSON", ast: ast)
            }
        ).description("The `JSONObject` scalar type represents JSON values as specified by [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).")
    }

    /// Returns a represents JSON objects.
    static func jsonObject() -> Scalar<Resolver, Context, Map> {
        return Scalar(
            Map.self,
            as: "JSONObject",
            serialize: { value, _ in
                let map = try map(from: value)
                switch map {
                case .dictionary:
                    return map
                default:
                    throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(map)")
                }
            },
            parseValue: { map, _ in
                switch map {
                case .dictionary:
                    return map
                default:
                    throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(map)")
                }
            },
            parseLiteral: { ast, _ in
                guard let ast = ast as? ObjectValue else {
                    throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(ast)")
                }
                return try parseObject(typeName: "JSON", ast: ast)
            }
        ).description("The `JSONObject` scalar type represents JSON values as specified by [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).")
    }
}
