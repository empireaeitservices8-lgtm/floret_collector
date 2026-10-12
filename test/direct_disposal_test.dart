import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/features/direct_disposal/model/direct_disposal_model.dart';
import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:floret_collector/features/direct_disposal/screen/direct_disposal_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Direct Disposal Model and ViewModel Tests', () {
    test('DirectDisposalLogModel creation and properties', () {
      const log = DirectDisposalLogModel(
        id: '1',
        customerName: 'uiui',
        phone: '1234567890',
        customerAddress: 'Main St',
        disposalType: 'WALK IN',
        wasteType: 'Bio waste',
        wasteDescription: 'Kitchen waste',
        weight: 569.0,
        rate: 21.99,
        gstRatePercent: 5.0,
        gstAmount: 2253.24,
        totalAmount: 14771.24,
        paymentMethod: 'ONLINE',
        paymentStatus: 'PENDING',
        formattedDate: '03 Oct 2026, 10:16 AM',
      );

      expect(log.customerName, 'uiui');
      expect(log.phone, '1234567890');
      expect(log.wasteType, 'Bio waste');
      expect(log.isPaid, isFalse);
    });

    test('DirectDisposalLogModel.fromJson parses API response format correctly', () {
      final json = {
        "id": 36,
        "customer_name": "John Doe",
        "customer_phone": "9876543210",
        "customer_address": "123 Main Street, Kochi",
        "disposal_type": "direct",
        "waste_type": "plastic",
        "waste_description": "Mixed plastic waste",
        "weight": "15.50",
        "disposal_rate": "15.00",
        "local_body": 15,
        "local_body_name": "Kalady Grama Panchayat",
        "ward": "1",
        "subtotal": "232.50",
        "gst_amount": "41.85",
        "total_amount": "274.35",
        "payment_status": "pending",
        "payment_method": null,
        "transaction_id": null,
        "remarks": null,
        "recorded_by": null,
        "disposal_date": "2026-10-12",
        "disposal_time": "06:51:30.513996",
        "created_at": "2026-10-12T06:51:30.514259Z",
        "updated_at": "2026-10-12T06:51:30.514293Z"
      };

      final log = DirectDisposalLogModel.fromJson(json);
      expect(log.id, '36');
      expect(log.customerName, 'John Doe');
      expect(log.phone, '9876543210');
      expect(log.customerAddress, '123 Main Street, Kochi');
      expect(log.disposalType, 'DIRECT');
      expect(log.wasteType, 'plastic');
      expect(log.weight, 15.5);
      expect(log.rate, 15.0);
      expect(log.gstAmount, 41.85);
      expect(log.totalAmount, 274.35);
      expect(log.paymentStatus, 'PENDING');
      expect(log.isPaid, isFalse);
    });

    test('Financial calculations update dynamically with weight and rate', () {
      final vm = DirectDisposalViewModel();

      vm.setWeight(10.0);
      vm.setRate(2.0);
      vm.setGstRateOption('5% GST (Standard)');

      expect(vm.subtotal, 20.0);
      expect(vm.gstAmount, 1.0);
      expect(vm.totalAmount, 21.0);

      // Change weight
      vm.setWeight(582.0);
      vm.setRate(2.0);
      expect(vm.subtotal, 1164.0);
      expect(vm.gstAmount, 58.2);
      expect(vm.totalAmount, 1222.2);
    });

    test('Validation fails when required fields are empty', () {
      final vm = DirectDisposalViewModel();

      final isValid = vm.validateForm();

      expect(isValid, isFalse);
      expect(vm.nameError, 'Name is required');
      expect(vm.phoneError, 'Phone number is required');
      expect(vm.addressError, 'Address is required');
      expect(vm.weightError, 'Weight required');
    });

    test('Validation succeeds when required fields are populated', () async {
      final vm = DirectDisposalViewModel();

      vm.setCustomerName('Rahul Kumar');
      vm.setPhone('9876543210');
      vm.setCustomerAddress('MG Road, Kochi');
      vm.setWeight(15.5);

      final isValid = vm.validateForm();

      expect(isValid, isTrue);
      expect(vm.nameError, isNull);
      expect(vm.phoneError, isNull);
      expect(vm.addressError, isNull);
      expect(vm.weightError, isNull);

      final submitted = await vm.submitRecord();
      expect(submitted, isTrue);
      expect(vm.selectedTab, DirectDisposalTab.disposalLogs);
      expect(vm.logs.first.customerName, 'Rahul Kumar');
    });
  });

  group('DirectDisposalScreen Widget Tests', () {
    testWidgets('Renders Direct Disposal screen with New Record and Disposal Logs tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DirectDisposalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direct Disposal'), findsOneWidget);
      expect(find.text('New Record'), findsOneWidget);
      expect(find.text('Disposal Logs'), findsOneWidget);

      // Section Headers in New Record
      expect(find.text('Customer Details'), findsOneWidget);
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Customer Address'), findsOneWidget);
      expect(find.text('Waste Parameters'), findsOneWidget);
    });

    testWidgets('Tapping Record Disposal shows customer details and weight validations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DirectDisposalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to tap 'Record Disposal' button
      await tester.scrollUntilVisible(
        find.text('Record Disposal'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Record Disposal'));
      await tester.pumpAndSettle();

      // Verify validation errors (Image 3 and Image 4)
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);
      expect(find.text('Weight required'), findsOneWidget);
    });

    testWidgets('Tapping Disposal Logs tab shows logs and search bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DirectDisposalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Disposal Logs tab
      await tester.tap(find.text('Disposal Logs'));
      await tester.pumpAndSettle();

      // Search bar
      expect(
        find.text('Search by Customer Name, Phone, or Was...'),
        findsOneWidget,
      );

      // Log items from Image 5
      expect(find.text('uiui'), findsOneWidget);
      expect(find.text('Phone: 1234567890'), findsOneWidget);
      expect(find.text('Bio waste'), findsOneWidget);
      expect(find.text('569.0 kg'), findsOneWidget);
      expect(find.text('₹2253.24'), findsOneWidget);
      expect(find.text('₹14771.24'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);

      expect(find.text('hfhn'), findsOneWidget);
      expect(find.text('Phone: 8285580088'), findsOneWidget);
      expect(find.text('Mixed waste'), findsOneWidget);

      expect(find.text('Adithya'), findsOneWidget);
      expect(find.text('Phone: 7736683620'), findsOneWidget);
      expect(find.text('Sanitary Waste'), findsOneWidget);
    });
  });
}
