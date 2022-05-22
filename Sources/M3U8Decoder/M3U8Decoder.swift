import Foundation

public class M3U8Decoder: JSONDecoder {
    
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        guard let dict = M3U8Parser().parse(data: data),
              let jsonData = try? JSONSerialization.data(withJSONObject: dict)
        else {
            throw "Bad data."
        }
        
        return try super.decode(type, from: jsonData)
    }
}
