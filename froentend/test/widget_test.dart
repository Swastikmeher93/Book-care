import 'package:flutter_test/flutter_test.dart';
import 'package:health_care/app.dart';

import 'package:health_care/main.dart';

void main() {
  testWidgets('shows the home services list', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('CareBook'), findsOneWidget);
    expect(find.text('Wound Dressing'), findsOneWidget);
    expect(find.text('Book Now'), findsWidgets);
  });
}
