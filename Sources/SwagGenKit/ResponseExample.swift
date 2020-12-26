import Foundation
import Swagger

public enum ResponseExample {
    indirect case object([String: ResponseExample])
    indirect case array([ResponseExample])
    case boolean(Bool)
    case string(String)
    case number(Double)
    case integer(Int)
    case unknown

    init(type: SchemaType?) {
        switch type {
        case .boolean: self = .boolean(Example.bool())
        case .string: self = .string(Example.string())
        case .number: self = .number(Example.number())
        case .integer: self = .integer(Example.integer())
        case let .array(arraySchema): self = .array(Array(0...Example.arrayCount()).map { _ in ResponseExample(arrayType: arraySchema) })
        case let .object(objectSchema): self = ResponseExample(objectScheme: objectSchema)
        case let .reference(referenceSchema): self = ResponseExample(type: referenceSchema.value.type)
        case let .group(groupSchema): self = ResponseExample(groupSchema: groupSchema)
        default: self = .unknown
        }
    }

    init(arrayType: ArraySchema) {
        switch arrayType.items {
        case let .single(schema): self = ResponseExample(type: schema.type)
        case let .multiple(schemas):
            guard let schema = schemas.first else {
                self = .unknown
                return
            }
            if schemas.count > 1 {
                print("warning: multiple schemas are not supported, using first \(schema.type.object.debugDescription)")
            }
            self = ResponseExample(type: schema.type)
        }
    }

    init(objectScheme: ObjectSchema) {
        var objectExample = [String: ResponseExample]()
        objectScheme.properties.forEach { property in
            objectExample[property.name] = ResponseExample(type: property.schema.type)
        }
        self = .object(objectExample)
    }

    init(groupSchema: GroupSchema) {
        let schemas = groupSchema.schemas
        guard let schema = groupSchema.schemas.first else {
            self = .unknown
            return
        }

        if schemas.count > 1 {
            print("warning: multiple schemas are not supported, using first \(schema.type.object.debugDescription)")
        }

        self = ResponseExample(type: schema.type)
    }

    var raw: Any {
        switch self {
        case .unknown: return "?"
        case let .boolean(bool): return bool
        case let .string(string): return string
        case let .number(double): return double
        case let .integer(integer): return integer
        case let .array(examples): return examples.map { $0.raw }
        case let .object(object): return object.mapValues { $0.raw }
        }
    }
}

private enum Example {
    static let string = { UUID().uuidString }
    static let bool = { Bool.random() }
    static let number = { Double.random(in: 0...1) }
    static let integer = { Int.random(in: 0...100) }
    static let arrayCount = { Int.random(in: 2...3) }
}
