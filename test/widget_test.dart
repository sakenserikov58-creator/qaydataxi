import 'package:flutter_test/flutter_test.dart';
import 'package:qayda_taxi_app/main_passenger.dart';

void main() {
  testWidgets('PassengerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PassengerApp());
    // Basic smoke test — app loads without crashing
    await tester.pump(const Duration(seconds: 1));
  });
}
