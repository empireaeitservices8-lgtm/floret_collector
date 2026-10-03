import '../model/issue_model.dart';
import 'package:floret_collector/services/web_api_services.dart';

class IssuesRepository {
  final WebAPIService _webAPIService;

  IssuesRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  WebAPIService get webAPIService => _webAPIService;

  Future<List<IssueModel>> fetchIssues() async {
    try {
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
    } catch (_) {
      return [];
    }
  }
}
