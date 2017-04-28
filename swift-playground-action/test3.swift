//import Dispatch
import Foundation
import SwiftyJSON
import Conversation

//let json: JSON = "I'm a json"
let json = JSON(["name":"Paul", "age": 25])
if let name = json["name"].string {
   print("Hello ", name);
}
