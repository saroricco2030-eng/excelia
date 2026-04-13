import 'package:flutter_test/flutter_test.dart';
import 'package:excelia/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExceliaApp());
    expect(find.text('Excelia'), findsWidgets);
  });
}
