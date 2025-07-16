# GraphQLJSONScalar

This package provides `JSON` and `JSONObject` scalar types to GraphQL and Graphiti schemas.
This can be useful if you'd like your GraphQL to accept or emit untyped JSON.

It is primarily a Swift port of this package: https://github.com/taion/graphql-type-json

## Usage

To use the package, you should add it as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/NeedleInAJayStack/GraphQLJSONScalar.git", from: ...),
]
```

### Graphiti

After adding the `GraphitiJSONScalar` library as dependency for your target, you can use the
`Scalar.json()` or `Scalar.jsonObject()` functions inside your schema builder:

```swift
let schema = try Schema<TestResolver, NoContext> {
    Scalar.json()
    ...
}
```

`json` can represent any JSON-serializable value, including scalars, arrays, and objects.
`jsonObject` represents JSON objects specifically (i.e. not scalars or arrays).

Unfortunately at this time you may include *either* `json` or `jsonObject`, but cannot include both.

### GraphQL

After adding the `GraphQLJSONScalar` library as dependency for your target, you can add the
`GraphQLJSONScalar` or `GraphQLJSONObjectScalar` objects directly onto the `GraphQLSchema` types:

```swift
GraphQLSchema(
    ...
    types: [
        GraphQLJSONScalar,
        GraphQLJSONObjectScalar
    ]
    ...
)
```
