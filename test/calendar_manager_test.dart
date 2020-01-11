import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_manager/calendar_manager.dart';

void main() {
  const MethodChannel channel = MethodChannel('be.rmdy.calendar_manager');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await CalendarManager.platformVersion, '42');
  });
}
