import 'package:flutter_test/flutter_test.dart';
import 'package:greenoffice360/features/issues/screens/issue_select_category.dart';

void main() {
  testWidgets('shows the issue category picker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IssueSelectCategoryScreen()));

    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);
  });
}
