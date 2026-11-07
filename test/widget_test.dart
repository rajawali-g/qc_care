import 'package:flutter_test/flutter_test.dart';
import 'package:data_monitor/main.dart';

void main() {
  testWidgets('QC_MCE app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QcMceApp());
    expect(find.text('QC_MCE'), findsWidgets);
  });
}
