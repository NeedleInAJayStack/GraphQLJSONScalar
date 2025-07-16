import GraphQL
import OrderedCollections

/// `GraphQLJSONScalar` represents any JSON-serializable value, including scalars, arrays, and objects.
public let GraphQLJSONScalar = try! GraphQLScalarType(
    name: "JSON",
    description: "The `JSON` scalar type represents JSON values as specified by [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).",
    serialize: { value in
        try map(from: value)
    },
    parseValue: { map in
        map
    },
    parseLiteral: { ast in
        try parseLiteral(typeName: "JSON", ast: ast)
    }
)

/// `GraphQLJSONObjectScalar` represents JSON objects.
public let GraphQLJSONObjectScalar = try! GraphQLScalarType(
    name: "JSONObject",
    description: "The `JSONObject` scalar type represents JSON values as specified by [ECMA-404](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf).",
    serialize: { value in
        let map = try map(from: value)
        switch map {
        case .dictionary:
            return map
        default:
            throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(map)")
        }
    },
    parseValue: { map in
        switch map {
        case .dictionary:
            return map
        default:
            throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(map)")
        }
    },
    parseLiteral: { ast in
        guard let ast = ast as? ObjectValue else {
            throw GraphQLError(message: "`JSONObject` cannot represent non-object value: \(ast)")
        }
        return try parseObject(typeName: "JSON", ast: ast)
    }
)

public func parseLiteral(typeName: String, ast: Value) throws -> Map {
    if let ast = ast as? StringValue {
        return .string(ast.value)
    } else if let ast = ast as? BooleanValue {
        return .bool(ast.value)
    } else if let ast = ast as? IntValue {
        guard let int = Int(ast.value) else {
            throw GraphQLError(message: "Int cannot represent value: \(ast.value)")
        }
        return .int(int)
    } else if let ast = ast as? FloatValue {
        guard let double = Double(ast.value) else {
            throw GraphQLError(message: "Double cannot represent value: \(ast.value)")
        }
        return .double(double)
    } else if let ast = ast as? ObjectValue {
        return try parseObject(typeName: typeName, ast: ast)
    } else if let ast = ast as? ListValue {
        return try .array(ast.values.map { value in
            try parseLiteral(typeName: typeName, ast: value)
        })
    } else if let _ = ast as? NullValue {
        return .null
    } else {
        throw GraphQLError(message: "\(typeName) cannot represent value: \(ast)")
    }
}

public func parseObject(typeName: String, ast: ObjectValue) throws -> Map {
    var object = OrderedDictionary<String, Map>()
    for field in ast.fields {
        object[field.name.value] = try parseLiteral(typeName: typeName, ast: field.value)
    }
    return .dictionary(object)
}
