// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "GraphQLJSONScalar",
    products: [
        .library(name: "GraphQLJSONScalar", targets: ["GraphQLJSONScalar"]),
        .library(name: "GraphitiJSONScalar", targets: ["GraphitiJSONScalar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", "2.3.0" ..< "4.0.0"),
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", "1.11.0" ..< "3.0.0"),
    ],
    targets: [
        .target(
            name: "GraphQLJSONScalar",
            dependencies: ["GraphQL"]
        ),
        .target(
            name: "GraphitiJSONScalar",
            dependencies: ["GraphQLJSONScalar", "Graphiti"]
        ),
        .testTarget(
            name: "GraphQLJSONScalarTests",
            dependencies: ["GraphQLJSONScalar"]
        ),
        .testTarget(
            name: "GraphitiJSONScalarTests",
            dependencies: ["GraphitiJSONScalar"]
        ),
    ]
)
