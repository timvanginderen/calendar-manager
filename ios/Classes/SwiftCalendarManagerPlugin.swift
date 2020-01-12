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
    let json = Json()
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rmdy.be/calendar_manager", binaryMessenger: registrar.messenger())
        let instance = SwiftCalendarManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handleMethod(method:String, jsonArgs: Dictionary<String, AnyObject>) throws -> Any? {
        switch method {
        case "createEvents":
            let events = try json.parse(Array<Event>.self, from: jsonArgs["events"] as! String)
            return try delegate.createEvents(events: events)
        case "createCalendar":
            let calendar = try json.parse(Calendar.self, from: jsonArgs["calendar"] as! String)
            return try delegate.createCalendar(calendar: calendar)
        case "deleteAllEventsByCalendarId":
            let calendarId = jsonArgs["calendarId"] as! String
            return try delegate.deleteAllEventsByCalendarId(calendarId: calendarId)
        default:
            return FlutterMethodNotImplemented
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let success = try handleMethod(method: call.method, jsonArgs: call.arguments as! Dictionary<String, AnyObject>)
            result(success)
        } catch let error as FlutterError {
            result(error)
        } catch let error as NSException {
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        } catch let error as NSError {
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        } catch let error as NSExceptionName {
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.rawValue, details: error.self))
        } catch let error as CocoaError {
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        } catch {
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.localizedDescription, details: error.self))
        }
    }
}

public struct ErrorCodes {
    static let UNKNOWN = "UNKNOWN"
}

public class Json {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func parse<T>(_ type: T.Type, from data: String) throws -> T where T : Decodable {
        return try decoder.decode(type, from: data.data(using: .utf8)!)
    }
    
    func stringify<Value>(_ value: Value) throws -> String? where Value : Encodable {
        if(value is String) {
            return "\"\(value)\""
        } else if(value is Int) {
            return String(value as! Int)
        }
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8)
    }
}



public class CalendarManagerDelegate {
    let json = Json()
    public func createEvents(events: Array<Event>) throws -> String? {
        
        return try json.stringify("ok 1")
    }
    
    public func deleteAllEventsByCalendarId(calendarId:String) throws -> String? {
        
        return try json.stringify("ok 2")
    }
    
    public func createCalendar(calendar: Calendar) throws -> String? {
        
        return try json.stringify("ok 3")
    }
}
