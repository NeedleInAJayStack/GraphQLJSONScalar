// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "GraphQLJSONScalar",
    products: [
        .library(name: "GraphQLJSONScalar", targets: ["GraphQLJSONScalar"]),
        .library(name: "GraphitiJSONScalar", targets: ["GraphitiJSONScalar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "2.0.0"),
        // TODO: Mainline after merged: https://github.com/GraphQLSwift/Graphiti/pull/118
        .package(url: "https://github.com/NeedleInAJayStack/Graphiti.git", branch: "feature/scalar-extensions"),
//        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GraphQLJSONScalar",
            dependencies: ["GraphQL"]),
        .target(
            name: "GraphitiJSONScalar",
            dependencies: ["GraphQLJSONScalar", "Graphiti"]),
        .testTarget(
            name: "GraphQLJSONScalarTests",
            dependencies: ["GraphQLJSONScalar"]),
        .testTarget(
            name: "GraphitiJSONScalarTests",
            dependencies: ["GraphitiJSONScalar"]),
    ]
)
