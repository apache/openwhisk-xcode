//import Dispatch
import Foundation
import SwiftyJSON

//let json: JSON = "I'm a json"
let json = JSON(["name":"Joe Doe", "age": 25])
if let name = json["name"].string {
   print("Hello", name);
}
