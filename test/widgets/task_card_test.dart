import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veritask/widgets/app_widgets.dart';

void main() {
  testWidgets('TaskCard displays title, due date, and progress',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            title: 'Review Proposal',
            dueDate: 'Tomorrow',
            status: 'submitted',
            priority: 'high',
            category: 'development',
            progress: 0.55,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Review Proposal'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(find.byIcon(Icons.code_rounded), findsOneWidget);
  });
}
