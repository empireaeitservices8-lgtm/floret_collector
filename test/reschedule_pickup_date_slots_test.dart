import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/features/collection_route/repository/collection_history_repository.dart';

void main() {
  group('PickupDateSlot and Reschedule Filtering Tests', () {
    final sampleResponse = {
      "slots": [
        {
          "id": 56,
          "date": "2026-11-19",
          "time_slot": "10:00 AM - 12:00 AM",
          "max_pickups": 10,
          "current_pickups": 10,
          "is_available": true,
          "district": "Thiruvananthapuram",
          "local_body": "Nedumangadu Municipality",
          "is_slot_available": false
        },
        {
          "id": 59,
          "date": "2026-11-19",
          "time_slot": "10:00 AM - 12:00 AM",
          "max_pickups": 10,
          "current_pickups": 0,
          "is_available": true,
          "district": "Thiruvananthapuram",
          "local_body": "Varkala Municipality",
          "is_slot_available": true
        },
        {
          "id": 58,
          "date": "2026-11-20",
          "time_slot": "10:00 AM - 12:00 AM",
          "max_pickups": 10,
          "current_pickups": 0,
          "is_available": true,
          "district": "Thiruvananthapuram",
          "local_body": "Varkala Municipality",
          "is_slot_available": true
        }
      ]
    };

    test('PickupDateSlot.fromJson parses all fields accurately', () {
      final rawSlots = sampleResponse['slots'] as List<dynamic>;
      final slots = rawSlots
          .map((s) => PickupDateSlot.fromJson(s as Map<String, dynamic>))
          .toList();

      expect(slots.length, 3);

      expect(slots[0].id, 56);
      expect(slots[0].date, '2026-11-19');
      expect(slots[0].timeSlot, '10:00 AM - 12:00 AM');
      expect(slots[0].maxPickups, 10);
      expect(slots[0].currentPickups, 10);
      expect(slots[0].isAvailable, isTrue);
      expect(slots[0].district, 'Thiruvananthapuram');
      expect(slots[0].localBody, 'Nedumangadu Municipality');
      expect(slots[0].isSlotAvailable, isFalse);

      expect(slots[1].id, 59);
      expect(slots[1].date, '2026-11-19');
      expect(slots[1].localBody, 'Varkala Municipality');
      expect(slots[1].isSlotAvailable, isTrue);

      expect(slots[2].id, 58);
      expect(slots[2].date, '2026-11-20');
      expect(slots[2].localBody, 'Varkala Municipality');
      expect(slots[2].isSlotAvailable, isTrue);
    });

    bool matchesLocalBody(String slotLb, String userLb) {
      final s = slotLb.trim().toLowerCase();
      final u = userLb.trim().toLowerCase();
      if (s.isEmpty || u.isEmpty) return false;
      if (s == u) return true;

      final stripPattern = RegExp(
        r'\s+(municipality|panchayath|panchayat|corporation|grama panchayat)$',
        caseSensitive: false,
      );
      final cleanS = s.replaceAll(stripPattern, '').trim();
      final cleanU = u.replaceAll(stripPattern, '').trim();

      if (cleanS.isNotEmpty && cleanS == cleanU) return true;
      if (cleanS.isNotEmpty &&
          (cleanU.contains(cleanS) || cleanS.contains(cleanU))) {
        return true;
      }
      return false;
    }

    test('Filters slots for currently logged in user with Varkala Municipality', () {
      final rawSlots = sampleResponse['slots'] as List<dynamic>;
      final slots = rawSlots
          .map((s) => PickupDateSlot.fromJson(s as Map<String, dynamic>))
          .toList();

      const userLocalBody = 'Varkala Municipality';
      final matchingSlots = slots
          .where((s) => matchesLocalBody(s.localBody, userLocalBody))
          .toList();

      expect(matchingSlots.length, 2);
      expect(matchingSlots.map((s) => s.id).toList(), [59, 58]);
      expect(matchingSlots.map((s) => s.date).toList(), ['2026-11-19', '2026-11-20']);
    });

    test('Filters slots with case insensitivity and suffix variation', () {
      final rawSlots = sampleResponse['slots'] as List<dynamic>;
      final slots = rawSlots
          .map((s) => PickupDateSlot.fromJson(s as Map<String, dynamic>))
          .toList();

      const userLocalBody = 'varkala';
      final matchingSlots = slots
          .where((s) => matchesLocalBody(s.localBody, userLocalBody))
          .toList();

      expect(matchingSlots.length, 2);
      expect(matchingSlots.map((s) => s.id).toList(), [59, 58]);
    });

    test('Calendar predicate allows only filtered local body dates and disables others', () {
      final rawSlots = sampleResponse['slots'] as List<dynamic>;
      final slots = rawSlots
          .map((s) => PickupDateSlot.fromJson(s as Map<String, dynamic>))
          .toList();

      const userLocalBody = 'Varkala Municipality';
      final matchingSlots = slots
          .where((s) => matchesLocalBody(s.localBody, userLocalBody))
          .toList();

      final allowedDates = <DateTime>{};
      for (final slot in matchingSlots) {
        final pDate = slot.parsedDate;
        if (pDate != null) {
          allowedDates.add(DateTime(pDate.year, pDate.month, pDate.day));
        }
      }

      bool selectableDayPredicate(DateTime day) {
        final normalized = DateTime(day.year, day.month, day.day);
        return allowedDates.contains(normalized);
      }

      // Filtered dates should be clickable
      expect(selectableDayPredicate(DateTime(2026, 11, 19)), isTrue);
      expect(selectableDayPredicate(DateTime(2026, 11, 20)), isTrue);

      // Other dates should be unclickable
      expect(selectableDayPredicate(DateTime(2026, 11, 18)), isFalse);
      expect(selectableDayPredicate(DateTime(2026, 11, 21)), isFalse);
      expect(selectableDayPredicate(DateTime(2026, 11, 25)), isFalse);
      expect(selectableDayPredicate(DateTime(2026, 12, 1)), isFalse);
    });
  });
}
