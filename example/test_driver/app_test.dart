import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// no main code allowed here
void main() {
  group('Calender Manager', () {
    FlutterDriver driver;
    final versionTextFinder = find.byValueKey('version');

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        try {
          driver.close();
        } catch (e) {
          print(e);
        }
      }
    });

    setUp(() {});

    test('version contains Android', () async {
      await Future.delayed(Duration(milliseconds: 50));
      final version = await driver.getText(versionTextFinder);
      expect(version, contains("Android"));
    });
  });
}
