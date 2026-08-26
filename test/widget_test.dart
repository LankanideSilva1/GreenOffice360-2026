import 'package:flutter_test/flutter_test.dart';

import 'package:greenoffice360/main.dart';

void main() {
  testWidgets('shows the GreenOffice splash screen', (tester) async {
    await tester.pumpWidget(const GreenOfficeApp());

    expect(find.textContaining('Want to check out this file?'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });
}
