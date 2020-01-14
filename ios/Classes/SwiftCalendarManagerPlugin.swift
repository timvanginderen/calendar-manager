import Flutter
import UIKit
import EventKit

public struct CreateCalendar : Codable {
    let name:String
    let color:Int32?
}

public struct CalendarResult : Codable {
    let id:String
    let name:String
    let color:Int32?
    let isReadOnly:Bool
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
    func deleteCalendar(calendarId:String) throws
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
        case "deleteCalendar":
            let calendarId = jsonArgs["calendarId"] as! String
            try api.deleteCalendar(calendarId: calendarId)
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

public enum ErrorCode {
    case UNKNOWN
    case PERMISSIONS_NOT_GRANTED
    case CALENDAR_READ_ONLY
    case CALENDAR_NOT_FOUND
    
    var name: String {
        get { return String(describing: self) }
    }
}

public class Json {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func parse<T>(_ type: T.Type, from data: String) throws -> T where T : Decodable {
        return try decoder.decode(type, from: data.data(using: .utf8)!)
    }
    
    func stringify<Value>(_ value: Value?) throws -> Any? where Value : Encodable {
        guard let v = value else {
            return nil
        }
        switch(v.self) {
        case is String, is Int, is Bool, is Double:
            return v
        default:
            let data = try encoder.encode(value!)
            return String(data: data, encoding: .utf8)
        }
        
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
    
    private func errorUnknown(message:String?, details:Any?) -> CalendarManagerError {
        return CalendarManagerError(code: ErrorCode.UNKNOWN, message: message, details: details)
    }
    
    private func toCalendarManagerError(_ e:Any) -> CalendarManagerError {
        switch e {
        case let error as CalendarManagerError:
            return error
        case let error as NSException:
            return errorUnknown(message: error.userInfo.debugDescription, details: error.self)
        case let error as NSError:
            return errorUnknown(message: error.userInfo.debugDescription, details: error.self)
        case let error as NSExceptionName:
            return (errorUnknown(message: error.rawValue, details: error.self))
        case let error as CocoaError:
            return (errorUnknown(message: error.userInfo.debugDescription, details: error.self))
        case let error as Error:
            return (errorUnknown(message: error.localizedDescription, details: error.self))
        default:
            return (errorUnknown(message: nil, details: e.self))
        }
    }
    
    public func error<E>(_ e:E) {
        let error = toCalendarManagerError(e)
        result(FlutterError(code:error.code.name,message: error.message,details: error.details))
    }
    
    public func notImplemented() {
        result(FlutterMethodNotImplemented)
    }
}

extension UIColor {
    func rgb() -> Int32? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)
            
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return Int32(rgb)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

extension CGColor {
    func toInt() -> Int32? {
        return UIColor(cgColor: self).rgb()
    }
}

extension Int32 {
    
    func toCgColor() -> CGColor {
        var bytes = withUnsafeBytes(of: bigEndian) { Array($0) }
        let alpha = CGFloat(bytes[0]/255)
        let red = CGFloat(bytes[1]/255)
        let green = CGFloat(bytes[2]/255)
        let blue = CGFloat(bytes[3]/255)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
    }
}

extension EKCalendar {
    
    func toCalendarResult() -> CalendarResult {
        return CalendarResult(id: calendarIdentifier, name: title, color: cgColor?.toInt(), isReadOnly: !allowsContentModifications)
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
        finishWithSuccess(results)
    }
    public func createCalendar(calendar: CreateCalendar) throws {
        try throwIfUnauthorized()
        let ekCalendar = EKCalendar(for: .event,
                                    eventStore: self.eventStore)
        ekCalendar.title = calendar.name
        ekCalendar.cgColor = calendar.color?.toCgColor()
        ekCalendar.source = self.eventStore.defaultCalendarForNewEvents?.source
        
        try self.eventStore.saveCalendar(ekCalendar, commit: true)
        self.finishWithSuccess(ekCalendar.toCalendarResult())
    }
    func createEvent(event: Event) throws {
        try throwIfUnauthorized()
        guard let ekCalendar = eventStore.calendar(withIdentifier: event.calendarId) else {
            throw errorCalendarNotFound(calendarId: event.calendarId)
        }
        try createEvent(ekCalendar: ekCalendar, event: event)
        finishWithSuccess()
    }
    
    public func deleteCalendar(calendarId:String) throws{
        try throwIfUnauthorized()
        let ekCalendar = try findCalendarOrThrow(calendarId: calendarId, requireWritable: false)
        try eventStore.removeCalendar(ekCalendar, commit: true)
        self.finishWithSuccess()
    }
    
    public func findCalendarOrThrow(calendarId:String, requireWritable:Bool = true) throws -> EKCalendar {
        guard let ekCalendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw errorCalendarNotFound(calendarId: calendarId)
        }
        
        let cal = ekCalendar
        if(requireWritable && !cal.allowsContentModifications) {
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
        guard let s = successObj else {
            return self.result.success(successObj)
        }
        
        return catchErrors {
            self.result.success(try self.json.stringify(s))
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
    public let code:ErrorCode
    public let message:String?
    public let details:Any?
}


func errorUnauthorized() -> CalendarManagerError {
    return CalendarManagerError(code: ErrorCode.PERMISSIONS_NOT_GRANTED, message: "Permissions not granted", details: nil)
}

func errorCalendarNotFound(calendarId: String)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCode.CALENDAR_NOT_FOUND, message: "Calendar with identifier not found: \(calendarId)", details: calendarId)
}

func errorCalendarReadOnly(calendar: EKCalendar)-> CalendarManagerError {
    return CalendarManagerError(code: ErrorCode.CALENDAR_READ_ONLY, message: "Trying to write to read only calendar: \(calendar)", details: calendar)
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
