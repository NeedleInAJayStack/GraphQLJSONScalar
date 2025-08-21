// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "GraphQLJSONScalar",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(name: "GraphQLJSONScalar", targets: ["GraphQLJSONScalar"]),
        .library(name: "GraphitiJSONScalar", targets: ["GraphitiJSONScalar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", "4.0.0" ..< "5.0.0"),
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", "3.0.0" ..< "4.0.0"),
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
