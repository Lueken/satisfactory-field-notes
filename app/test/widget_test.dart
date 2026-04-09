import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satisfactory_field_notes/main.dart';

void main() {
  testWidgets('App renders with navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FieldNotesApp()));
    expect(find.text('Field Notes'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
  });
}
