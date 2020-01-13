import Flutter
import UIKit
import EventKit

public struct CreateCalendar : Codable {
    let name:String
}

public struct CalendarResult : Codable {
    let id:String
    let name:String
    let readOnly:Bool
}

public struct Event: Codable {
    let calendarId: String
    let title: String
    let description: String?
    let startDate: Int64
    let endDate: Int64
    let location: String?
}

protocol CalendarApi {
    func requestPermissions() throws
    func findAllCalendars() throws
    func createEvent(event: Event) throws
    func createCalendar(calendar: CreateCalendar) throws
    func deleteAllEventsByCalendarId(calendarId:String) throws
}


public class SwiftCalendarManagerPlugin: NSObject, FlutterPlugin {
    let json = Json()
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rmdy.be/calendar_manager", binaryMessenger: registrar.messenger())
        let instance = SwiftCalendarManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handleMethod(method:String, result:CalendarManagerResult, jsonArgs: Dictionary<String, AnyObject>) throws {
        let api = CalendarManagerDelegate(result: result)
        switch method {
        case "requestPermissions":
            try api.requestPermissions()
        case "findAllCalendars":
            try api.findAllCalendars()
        case "createEvent":
            let event = try json.parse(Event.self, from: jsonArgs["event"] as! String)
            try api.createEvent(event: event)
        case "createCalendar":
            let calendar = try json.parse(CreateCalendar.self, from: jsonArgs["calendar"] as! String)
            try api.createCalendar(calendar: calendar)
        case "deleteAllEventsByCalendarId":
            let calendarId = jsonArgs["calendarId"] as! String
            try api.deleteAllEventsByCalendarId(calendarId: calendarId)
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
            return "\"\(value!)\""
        } else if(value is Int) {
            return String(value! as! Int)
        }
        let data = try encoder.encode(value!)
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


extension EKCalendar {
    
    func toCalendarResult() -> CalendarResult {
        return CalendarResult(id: calendarIdentifier, name: title, readOnly: !allowsContentModifications)
    }
}

public class CalendarManagerDelegate : CalendarApi {
    let json = Json()
    let eventStore = EKEventStore()
    let result: CalendarManagerResult
    
    init(result:CalendarManagerResult) {
        self.result = result
    }
    
    func requestPermissions() throws {
        return requestPermissions({ (granted) in
              self.result.success(granted)
        })
    }
    func findAllCalendars() throws {
        try throwIfUnauthorized()
        let results = self.eventStore.calendars(for: .event).map { (cal) in
            cal.toCalendarResult()
        }
        result.success(results)
    }
    public func createCalendar(calendar: CreateCalendar) throws {
        try throwIfUnauthorized()
        let ekCalendar = EKCalendar(for: .event,
                                    eventStore: self.eventStore)
        ekCalendar.title = calendar.name
        ekCalendar.source = self.eventStore.defaultCalendarForNewEvents?.source
        
        try self.eventStore.saveCalendar(ekCalendar, commit: true)
        self.finishWithSuccess()
    }
    func createEvent(event: Event) throws {
        try throwIfUnauthorized()
        let ekCalendar = eventStore.calendar(withIdentifier: event.calendarId)
        if(ekCalendar == nil) {
            throw errorCalendarNotFound(calendarId: event.calendarId)
        }
        try createEvent(ekCalendar: ekCalendar!, event: event)
        finishWithSuccess()
    }
    
    public func deleteAllEventsByCalendarId(calendarId:String) throws{
        try throwIfUnauthorized()
        let ekCalendar = try findWriteableCalendarOrThrow(calendarId: calendarId)
        let predicate = self.eventStore.predicateForEvents(
            withStart: Date(timeIntervalSince1970: 0),
            end: Date().plusYear(year: 100),
            calendars: [ekCalendar])
        let events = self.eventStore.events(matching: predicate)
        for event in events {
            try self.eventStore.remove(event, span: EKSpan.thisEvent, commit: false)
        }
        try self.eventStore.commit()
        self.finishWithSuccess()
    }
    
    public func findWriteableCalendarOrThrow(calendarId:String) throws -> EKCalendar {
        let ekCalendar = eventStore.calendar(withIdentifier: calendarId)
        if(ekCalendar == nil) {
            throw errorCalendarNotFound(calendarId: calendarId)
        }
        let cal = ekCalendar!
        if(!cal.allowsContentModifications) {
            throw errorCalendarReadOnly(calendar: cal)
        }
        return cal
    }
    
    private func createEvent(ekCalendar:EKCalendar, event:Event) throws {
        let ekEvent:EKEvent = EKEvent(eventStore: eventStore)
        
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate.asDate()
        ekEvent.endDate = event.endDate.asDate()
        ekEvent.notes = event.description
        ekEvent.location = event.location
        ekEvent.calendar = ekCalendar
        try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: true)
    }

   
    
    private func finishWithSuccess() {
        let x:String? = nil
        self.result.success(x)
    }
    
    private func finishWithSuccess<T>(_ successObj:T?) where T : Encodable {
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
    
    
    private func throwIfUnauthorized() throws {
        if !hasPermissions() {
           throw errorUnauthorized()
        }
    }
    
    private func requestPermissions(_ completion: @escaping (Bool) -> Void) {
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
    return CalendarManagerError(code: ErrorCodes.CALENDAR_NOT_FOUND, message: "Calendar with identifier not found: \(calendarId)", details: calendarId)
}

func errorCalendarReadOnly(calendar: EKCalendar)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.CALENDAR_READ_ONLY, message: "Trying to write to read only calendar: \(calendar)", details: calendar)
}

extension Int64 {
    func asDate() -> Date {
        return Date (timeIntervalSince1970: Double(self) / 1000.0)
    }
}

extension Date {
    func plusYear(year:Int) -> Date {
        var dateComponent = DateComponents()
        
        dateComponent.year = year
        
        return Calendar.current.date(byAdding: dateComponent, to: self)!
    }
}
