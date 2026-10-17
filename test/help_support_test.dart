import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/features/help_support/model/faq_item_model.dart';
import 'package:floret_collector/features/help_support/model/help_support_model.dart';
import 'package:floret_collector/features/help_support/viewmodel/help_support_view_model.dart';
import 'package:floret_collector/features/help_support/screen/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Help & Support Model and ViewModel Tests', () {
    test('FaqItemModel creation and json serialization', () {
      const model = FaqItemModel(
        id: '1',
        question: 'How do I confirm a cash payment?',
        answer: 'Weigh waste and select Cash.',
      );

      expect(model.id, '1');
      expect(model.question, 'How do I confirm a cash payment?');
      expect(model.answer, 'Weigh waste and select Cash.');

      final json = model.toJson();
      expect(json['id'], '1');
      final parsed = FaqItemModel.fromJson(json);
      expect(parsed.question, model.question);
    });

    test('HelpSupportModel parses API response format correctly', () {
      final json = {
        "contact": {
          "email": "floretbilling@gmail.com",
          "phone": "94460 02666",
          "phone_formatted": "+91 94460 02666"
        },
        "support_hours": {
          "days": "Monday to Saturday",
          "time": "9:00 AM - 6:00 PM"
        },
        "services": [
          "Billing inquiries",
          "Payment issues",
          "Waste collection scheduling",
          "Account support",
          "Technical assistance"
        ]
      };

      final model = HelpSupportModel.fromJson(json);
      expect(model.contact.email, "floretbilling@gmail.com");
      expect(model.contact.phone, "94460 02666");
      expect(model.contact.phoneFormatted, "+91 94460 02666");
      expect(model.supportHours.days, "Monday to Saturday");
      expect(model.supportHours.time, "9:00 AM - 6:00 PM");
      expect(model.services.length, 5);
      expect(model.services.first, "Billing inquiries");
    });

    test('HelpSupportViewModel loads 6 FAQs initially', () async {
      final vm = HelpSupportViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.faqs.length, 6);
      expect(vm.filteredFaqs.length, 6);
      expect(vm.isRefreshing, isFalse);
    });

    test('HelpSupportViewModel search filtering works', () async {
      final vm = HelpSupportViewModel();
      await Future.delayed(Duration.zero);

      vm.setSearchQuery('cash payment');
      expect(vm.filteredFaqs.length, 1);
      expect(vm.filteredFaqs.first.question,
          'How do I confirm a cash payment?');

      vm.setSearchQuery('non-existent-query');
      expect(vm.filteredFaqs.isEmpty, isTrue);

      vm.setSearchQuery('');
      expect(vm.filteredFaqs.length, 6);
    });

    test('HelpSupportViewModel toggleExpanded works', () async {
      final vm = HelpSupportViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.isExpanded('1'), isFalse);
      vm.toggleExpanded('1');
      expect(vm.isExpanded('1'), isTrue);
      vm.toggleExpanded('1');
      expect(vm.isExpanded('1'), isFalse);
    });

    test('HelpSupportViewModel refresh shows 3-second progress state',
        () async {
      final vm = HelpSupportViewModel();
      await Future.delayed(Duration.zero);

      final refreshFuture = vm.refresh();
      expect(vm.isRefreshing, isTrue);

      await Future.delayed(const Duration(milliseconds: 3100));
      await refreshFuture;

      expect(vm.isRefreshing, isFalse);
      expect(vm.faqs.length, 6);
    });
  });

  group('HelpSupportScreen Widget Tests', () {
    testWidgets('Renders Help & Support screen with contact cards and FAQs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.text('Call Support'), findsOneWidget);
      expect(find.text('+91 92920 23601'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('florettechnologies@gmail.com'), findsOneWidget);
      expect(find.text('How can we help you? Search FAQs...'), findsOneWidget);

      // Verify FAQ Questions from Image 1
      expect(find.text('How do I confirm a cash payment?'), findsOneWidget);
      expect(
        find.text(
            'What should I do if the online payment QR code fails to load?'),
        findsOneWidget,
      );
      expect(find.text('How is the total waste collection fee calculated?'),
          findsOneWidget);
      expect(find.text('How do I report unsorted waste or locked gates?'),
          findsOneWidget);
      expect(find.text('How do I update my ward or collection route?'),
          findsOneWidget);
      expect(find.text('Can I use multiple bags for a single stop?'),
          findsOneWidget);
    });

    testWidgets('Tapping FAQ card expands and shows answer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially answer is not visible
      expect(
        find.textContaining('To confirm a cash payment, weigh the waste'),
        findsNothing,
      );

      // Tap on the first question to expand
      await tester.tap(find.text('How do I confirm a cash payment?'));
      await tester.pumpAndSettle();

      // Answer is now visible (Image 2)
      expect(
        find.textContaining('To confirm a cash payment, weigh the waste'),
        findsOneWidget,
      );

      // Tap again to collapse
      await tester.tap(find.text('How do I confirm a cash payment?'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('To confirm a cash payment, weigh the waste'),
        findsNothing,
      );
    });

    testWidgets('Tapping refresh shows CircularProgressIndicator for 3 sec',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap refresh button in AppBar
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      // Shows circular progress indicator (Image 4)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance by 1.5 seconds: still showing indicator
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past 3 seconds: completes and FAQs return
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('How do I confirm a cash payment?'), findsOneWidget);
    });

    testWidgets(
        'Tapping Call Support and Email Support cards triggers launcher without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Call Support'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Email Support'));
      await tester.pumpAndSettle();
    });
  });
}
