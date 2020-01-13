import Flutter
import UIKit
import EventKit

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
    let json = Json()
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rmdy.be/calendar_manager", binaryMessenger: registrar.messenger())
        let instance = SwiftCalendarManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handleMethod(method:String, result:CalendarManagerResult, jsonArgs: Dictionary<String, AnyObject>) throws {
        let delegate = CalendarManagerDelegate(result: result)
        switch method {
        case "createEvents":
            let events = try json.parse(Array<Event>.self, from: jsonArgs["events"] as! String)
            try delegate.createEvents(events: events)
        case "createCalendar":
            let calendar = try json.parse(Calendar.self, from: jsonArgs["calendar"] as! String)
            try delegate.createCalendar(calendar: calendar)
        case "deleteAllEventsByCalendarId":
            let calendarId = jsonArgs["calendarId"] as! String
            try delegate.deleteAllEventsByCalendarId(calendarId: calendarId)
        default:
            result.notImplemented()
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let calendarManagerResult = CalendarManagerResult(result: result)
        calendarManagerResult.catchErrors {
            try self.handleMethod(method: call.method, result: calendarManagerResult, jsonArgs: call.arguments as! Dictionary<String, AnyObject>)
        }
    }
}

public struct ErrorCodes {
    static let UNKNOWN = "UNKNOWN"
    static let PERMISSIONS_NOT_GRANTED = "PERMISSIONS_NOT_GRANTED"
    static let CALENDAR_READ_ONLY = "CALENDAR_READ_ONLY"
    static let CALENDAR_NOT_FOUND = "CALENDAR_NOT_FOUND"
}

public class Json {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func parse<T>(_ type: T.Type, from data: String) throws -> T where T : Decodable {
        return try decoder.decode(type, from: data.data(using: .utf8)!)
    }
    
    func stringify<Value>(_ value: Value?) throws -> String? where Value : Encodable {
        if(value == nil) {
            return nil
        }
        
        if(value is String) {
            return "\"\(value.unsafelyUnwrapped)\""
        } else if(value is Int) {
            return String(value.unsafelyUnwrapped as! Int)
        }
        let data = try encoder.encode(value.unsafelyUnwrapped)
        return String(data: data, encoding: .utf8)
    }
}

public class CalendarManagerResult {
    private let result: FlutterResult
    
    init(result:@escaping FlutterResult) {
        self.result = result
    }
    
    public func success<T>(_ success:T?) {
        result(success)
    }
    
    func catchErrors(action: @escaping () throws -> Void) {
        do {
            try action()
        } catch let error {
            self.error(error)
        }
    }
    
    public func error<E>(_ e:E) {
        switch e {
        case let error as CalendarManagerError:
            result(FlutterError(code:error.code,message: error.message,details: error.details))
        case let error as FlutterError:
            result(FlutterError(code:error.code,message: error.message,details: error.details))
        case let error as NSException:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        case let error as NSError:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        case let error as NSExceptionName:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.rawValue, details: error.self))
        case let error as CocoaError:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.userInfo.debugDescription, details: error.self))
        case let error as Error:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: error.localizedDescription, details: error.self))
        default:
            result(FlutterError(code: ErrorCodes.UNKNOWN, message: nil, details: e.self))
        }
        
    }
    
    public func notImplemented() {
        result(FlutterMethodNotImplemented)
    }
}

protocol CalendarApi {
    func createCalendar(calendar: Calendar) throws
    func createEvents(events: Array<Event>) throws
    func deleteAllEventsByCalendarId(calendarId:String) throws
    
}

public class CalendarManagerDelegate : CalendarApi {
    let json = Json()
    let eventStore = EKEventStore()
    let result: CalendarManagerResult
    
    init(result:CalendarManagerResult) {
        self.result = result
    }
    
    public func createCalendar(calendar: Calendar) throws {
        withPermissions {
            self.success("ok 1")
        }
    }
    public func createEvents(events: Array<Event>) throws {
        withPermissions {
            self.success("ok 2")
        }
    }
    
    public func deleteAllEventsByCalendarId(calendarId:String) throws{
        withPermissions {
            self.success("ok 3")
        }
    }
    
    private func success<T>(_ successObj:T?) where T : Encodable {
        if(successObj == nil) {
            self.result.success(successObj)
        } else {
            catchErrors {
                self.result.success(try self.json.stringify(successObj))
            }
        }
    }
    
    func catchErrors(action: @escaping () throws -> Void) {
        result.catchErrors(action: action)
    }
    
    
    private func withPermissions(permissionsGrantedAction: @escaping () throws -> Void) {
        if hasPermissions() {
            catchErrors(action: permissionsGrantedAction)
            return
        } else {
            requestPermissions { (granted) in
                if(!granted) {
                    self.result.error(errorUnauthorized())
                } else {
                    self.catchErrors(action: permissionsGrantedAction)
                }
            }
        }
    }
    
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        if hasPermissions() {
            completion(true)
            return
        }
        eventStore.requestAccess(to: .event, completion: {
            (accessGranted: Bool, _: Error?) in
            completion(accessGranted)
        })
    }
    
    private func hasPermissions() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == EKAuthorizationStatus.authorized
    }
    
}

public struct CalendarManagerError : Error {
    public let code:String
    public let message:String?
    public let details:Any?
}

func errorUnauthorized() -> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.PERMISSIONS_NOT_GRANTED, message: "Permissions not granted", details: nil)
}

func errorCalendarNotFound(calendarId: String)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.CALENDAR_NOT_FOUND, message: "Calendar not found: \(calendarId)", details: calendarId)
}

func errorCalendarManagerError(calendarId: String)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.CALENDAR_READ_ONLY, message: "Trying to write to read only calendar: \(calendarId)", details: calendarId)
}

