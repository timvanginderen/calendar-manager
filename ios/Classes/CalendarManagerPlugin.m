#import "CalendarManagerPlugin.h"
#if __has_include(<calendar_manager/calendar_manager-Swift.h>)
#import <calendar_manager/calendar_manager-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "calendar_manager-Swift.h"
#endif

@implementation CalendarManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCalendarManagerPlugin registerWithRegistrar:registrar];
}
@end
