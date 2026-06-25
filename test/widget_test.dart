import 'package:flutter_test/flutter_test.dart';

import 'package:ai_upcycling_recommender/app/app.dart';

void main() {
  testWidgets('EcoLoop login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoLoopApp());

    expect(find.text('EcoLoop'), findsOneWidget);
    expect(find.text('Your sustainability companion'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
