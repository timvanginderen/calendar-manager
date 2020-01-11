import Flutter
import UIKit

public struct Calendar: Codable {
    let id: String
    let name: String
}

public struct Event: Codable {
    let calendarId: String
    let title: String
    let description: String?
    let startDate: Int64
    let endDate: Int64
    let location: String?
}


public class SwiftCalendarManagerPlugin: NSObject, FlutterPlugin {
    let delegate = CalendarManagerDelegate()
    let decoder = JSONDecoder()
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rmdy.be/calendar_manager", binaryMessenger: registrar.messenger())
    let instance = SwiftCalendarManagerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
    func handleMethod(method:String, jsonArgs: String) throws -> Any? {
        let jsonData = jsonArgs.data(using: .utf8)!
        switch method {
        case "createEvents":
            let events = try decoder.decode(Array<Event>.self, from: jsonData)
            return delegate.createEvents(events: events)
        case "createCalendar":
            let calendar = try decoder.decode(Calendar.self, from: jsonData)
           return delegate.createCalendar(calendar: calendar)
        case "deleteAllEventsByCalendarId":
            let calendarId = try decoder.decode(String.self, from: jsonData)
            return delegate.deleteAllEventsByCalendarId(calendarId: calendarId)
        default:
           return FlutterMethodNotImplemented
        }
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
        let success = try handleMethod(method: call.method, jsonArgs: call.arguments as! String)
        result(success)
    } catch let error as FlutterError {
        result(error)
    } catch _ {
        result(FlutterError(code:"UNKNOWN", message: nil,details: nil))
    }
    }
}



public class CalendarManagerDelegate {
    public func createEvents(events: Array<Event>) {
        
    }
    
    public func deleteAllEventsByCalendarId(calendarId:String) {
        
    }
    
    public func createCalendar(calendar: Calendar) {
        
    }
}
