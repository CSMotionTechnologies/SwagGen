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

    init(type: SchemaType?, propertyName: String? = nil) {
        let isIdentifier = propertyName?.lowercased().hasSuffix("id") ?? false

        switch type {
        case .boolean:
            self = .boolean(Example.bool)

        case .string:
            self = .string( isIdentifier ? Example.idString : Example.string)

        case .number:
            self = .number(Example.number)

        case .integer:
            self = .integer(Example.integer)

        case let .array(arraySchema):
            self = .array(Array(0...Example.arrayCount).map { _ in ResponseExample(arrayType: arraySchema) })

        case let .object(objectSchema):
            self = ResponseExample(objectScheme: objectSchema)

        case let .reference(referenceSchema):
            self = ResponseExample(type: referenceSchema.value.type)

        case let .group(groupSchema):
            self = ResponseExample(groupSchema: groupSchema)

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
            objectExample[property.name] = ResponseExample(type: property.schema.type, propertyName: property.name)
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
        case .unknown: return "<?>"
        case let .boolean(bool): return bool
        case let .string(string): return string
        case let .number(double): return double
        case let .integer(integer): return integer
        case let .array(examples): return examples.map { $0.raw }
        case let .object(object): return object.mapValues { $0.raw }
        }
    }

    var jsonString: String? {
        guard case .object = self,
              let data = try? JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted) else { return String(describing: raw) }
        return String(data: data, encoding: .utf8)
    }
}

private enum Example {
    static let string = "placeholder"
    static let idString = "identifier"
    static let bool = false
    static let number = 0.5
    static let integer = 1000
    static let arrayCount = 3
}
