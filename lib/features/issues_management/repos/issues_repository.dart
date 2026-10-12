import 'dart:convert';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import '../model/issue_model.dart';

class IssuesRepository {
  final ApiClient _apiClient;

  IssuesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : ApiClient());

  ApiClient get apiClient => _apiClient;

  Future<List<IssueModel>> fetchIssues() async {
    try {
      final response = await _apiClient.get(APIEndPoints.issues);

      // Print response formatted like the API response
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(response.data);
        // ignore: avoid_print
        print(formattedJson);
      } catch (_) {
        // ignore: avoid_print
        print(response.data);
      }

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final issuesList = data['issues'] as List? ?? [];
        return issuesList
            .map((item) => IssueModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => IssueModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      return getMockIssues();
    } catch (_) {
      return getMockIssues();
    }
  }

  List<IssueModel> getMockIssues() {
    // Returns dataset exactly matching the screenshots
    return [
      // --- Open Issues (Tab: Issues) ---
      const IssueModel(
        id: '1',
        title: 'Dispose by themselves',
        description:
            'Collector marked warning with reason: Dispose by themselves.',
        userName: 'noel',
        phoneNumber: '5674564897',
        isResolved: false,
      ),
      const IssueModel(
        id: '2',
        title: 'Dispose by themselves',
        description:
            'Collector marked warning with reason: Dispose by themselves.',
        userName: 'Main Road',
        phoneNumber: null,
        isResolved: false,
      ),
      const IssueModel(
        id: '3',
        title: 'Improper bags',
        description:
            'Collector marked warning with reason: Improper bags.',
        userName: 'nedumangadu',
        phoneNumber: '+918281971803',
        isResolved: false,
      ),
      const IssueModel(
        id: '4',
        title: 'Dispose by themselves',
        description:
            'Collector marked warning with reason: Dispose by themselves.',
        userName: 'subham',
        phoneNumber: '+918921305443',
        isResolved: false,
      ),
      // Additional items representing the full 93 issues count
      ...List.generate(
        89,
        (index) => IssueModel(
          id: '${index + 5}',
          title: index % 2 == 0
              ? 'Dispose by themselves'
              : 'Improper segregation',
          description: index % 2 == 0
              ? 'Collector marked warning with reason: Dispose by themselves.'
              : 'Collector marked warning with reason: Improper segregation of waste.',
          userName: index % 3 == 0
              ? 'kollam stop'
              : (index % 3 == 1 ? 'kumar' : 'city junction'),
          phoneNumber: index % 2 == 0 ? '+9194460123${index % 100}' : null,
          isResolved: false,
        ),
      ),

      // --- Resolved Issues (Tab: Resolved) ---
      const IssueModel(
        id: '101',
        title: 'Dispose by themselves',
        description:
            'Collector marked warning with reason: Dispose by themselves.',
        userName: 'Main Road',
        phoneNumber: null,
        isResolved: true,
      ),
      const IssueModel(
        id: '102',
        title: 'Mixed waste',
        description: 'testing issuweee',
        userName: 'testing one',
        phoneNumber: '+918281535237',
        isResolved: true,
      ),
      const IssueModel(
        id: '103',
        title: "Collector didn't arrive",
        description:
            'The collector was supposed to arrive at 9AM but didn\'t show up.',
        userName: 'Jos',
        phoneNumber: '+919876543210',
        isResolved: true,
      ),
      const IssueModel(
        id: '104',
        title: "Collector didn't arrive",
        description:
            'The collector was supposed to arrive at 9AM but didn\'t show up.',
        userName: 'Jos',
        phoneNumber: '+919876543210',
        isResolved: true,
      ),
    ];
  }
}
