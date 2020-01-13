import Flutter
import UIKit
import EventKit


public struct CalendarData: Codable {
    let name: String
}

public struct EventData: Codable {
    let title: String
    let description: String?
    let startDate: Int64
    let endDate: Int64
    let location: String?
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
            let events = try json.parse(Array<EventData>.self, from: jsonArgs["events"] as! String)
            let calendar = try json.parse(CalendarData.self, from: jsonArgs["calendar"] as! String)
            try delegate.createEvents(calendar: calendar, events: events)
        case "createCalendar":
            let calendar = try json.parse(CalendarData.self, from: jsonArgs["calendar"] as! String)
            try delegate.createCalendar(calendar: calendar)
        case "deleteAllEventsByCalendarId":
            let calendar = try json.parse(CalendarData.self, from: jsonArgs["calendar"] as! String)
            try delegate.deleteAllEventsByCalendar(calendar: calendar)
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
    static let CALENDAR_MULTIPLE_MATCHES = "CALENDAR_MULTIPLE_MATCHES"
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

protocol CalendarApi {
    func createCalendar(calendar: CalendarData) throws
    func createEvents(calendar: CalendarData, events: Array<EventData>) throws
    func deleteAllEventsByCalendar(calendar:CalendarData) throws
    
}

extension CalendarData {
    
    func isSameAs(_ cal:EKCalendar)->Bool {
        return self.name == cal.title
    }
}

public class CalendarManagerDelegate : CalendarApi {
    let json = Json()
    let eventStore = EKEventStore()
    let result: CalendarManagerResult
    
    init(result:CalendarManagerResult) {
        self.result = result
    }
    
    public func findCalendarOrThrow(calendar:CalendarData) throws -> EKCalendar {
        let ekCalendar = try self.findCalendar(calendar: calendar)
        if(ekCalendar == nil) {
            throw errorCalendarNotFound(calendar: calendar)
        }
        return ekCalendar!
    }
    
    public func findCalendar(calendar:CalendarData) throws -> EKCalendar? {
        let results = self.eventStore.calendars(for: .event).filter({ (cal) -> Bool in
            calendar.isSameAs(cal)
        })
        if(results.isEmpty) {
            return nil
        }
        if(results.count == 1) {
            return results.first
        }
        throw CalendarManagerError(code: ErrorCodes.CALENDAR_MULTIPLE_MATCHES, message: "Multiple matches (\(results.count)) found for calendar: \(calendar)", details: results)
    }
    
    
    public func createCalendar(calendar: CalendarData) throws {
        withPermissions {
            let ekCalendar = try self.findCalendar(calendar: calendar)
            if(ekCalendar == nil) {
                let ekCalendar = EKCalendar(for: .event,
                                            eventStore: self.eventStore)
                
                ekCalendar.title = calendar.name
                ekCalendar.source = self.eventStore.defaultCalendarForNewEvents?.source
                
                try self.eventStore.saveCalendar(ekCalendar, commit: true)
            }
            self.success()
        }
    }
    private func createEvent(ekCalendar:EKCalendar, event:EventData) throws {
        
        let ekEvent:EKEvent = EKEvent(eventStore: eventStore)
        
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate.asDate()
        ekEvent.endDate = event.endDate.asDate()
        ekEvent.notes = event.description
        ekEvent.location = event.location
        ekEvent.calendar = ekCalendar
        try self.eventStore.save(ekEvent, span: EKSpan.thisEvent, commit: false)
    }
    public func createEvents(calendar:CalendarData, events: Array<EventData>) throws {
        withPermissions {
            let ekCalendar = try self.findCalendarOrThrow(calendar: calendar)
            for event in events {
                try self.createEvent(ekCalendar: ekCalendar, event: event)
            }
            try self.eventStore.commit()
            
            self.success()
        }
    }
    
    public func deleteAllEventsByCalendar(calendar:CalendarData) throws{
        withPermissions {
            let ekCalendar = try self.findCalendarOrThrow(calendar: calendar)
            let predicate = self.eventStore.predicateForEvents(
                withStart: Date(timeIntervalSince1970: 0),
                end: Date().plusYear(year: 100),
                calendars: [ekCalendar])
            let events = self.eventStore.events(matching: predicate)
            for event in events {
                try self.eventStore.remove(event, span: EKSpan.thisEvent, commit: false)
            }
            try self.eventStore.commit()
            self.success()
        }
    }
    private func success() {
        let x:String? = nil
        self.result.success(x)
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

func errorCalendarNotFound(calendar: CalendarData)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.CALENDAR_NOT_FOUND, message: "Calendar not found: \(calendar)", details: calendar)
}

func errorCalendarReadOnly(calendar: EKCalendar)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCodes.CALENDAR_READ_ONLY, message: "Trying to write to read only calendar: \(calendar)", details: calendar)
}

