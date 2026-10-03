import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/issue_model.dart';
import '../viewmodel/issues_view_model.dart';

class IssuesManagementScreen extends StatefulWidget {
  static const String routeName = '/IssuesManagementScreen';

  const IssuesManagementScreen({super.key});

  @override
  State<IssuesManagementScreen> createState() => _IssuesManagementScreenState();
}

class _IssuesManagementScreenState extends State<IssuesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<IssuesViewModel>(
      create: (_) => IssuesViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<IssuesViewModel>(
            builder: (context, vm, _) {
              final issues = vm.currentTabIssues;

              return Column(
                children: [
                  const SizedBox(height: 4),

                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                          tooltip: 'Back',
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Issues Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => vm.refresh(delaySeconds: 3),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF0F172A),
                              size: 22,
                            ),
                            tooltip: 'Refresh',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Segmented Tabs: Issues (93) | Resolved (4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEEF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Tab 1: Issues
                          Expanded(
                            child: _buildTabButton(
                              label: 'Issues',
                              count: vm.openCount,
                              isSelected: vm.selectedTab == IssueTab.issues,
                              badgeColor: const Color(0xFFEF4444),
                              onTap: () =>
                                  vm.setSelectedTab(IssueTab.issues),
                            ),
                          ),

                          // Tab 2: Resolved
                          Expanded(
                            child: _buildTabButton(
                              label: 'Resolved',
                              count: vm.resolvedCount,
                              isSelected: vm.selectedTab == IssueTab.resolved,
                              badgeColor: const Color(0xFF10B981),
                              onTap: () =>
                                  vm.setSelectedTab(IssueTab.resolved),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Body Content: CircularProgressIndicator for 3s during refresh, or List
                  Expanded(
                    child: vm.isRefreshing
                        ? const Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          )
                        : issues.isEmpty
                            ? _buildEmptyState(vm.selectedTab)
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: issues.length,
                                itemBuilder: (context, index) {
                                  final item = issues[index];
                                  return _buildIssueCard(item);
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? badgeColor : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(IssueModel item) {
    final isResolved = item.isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Vertical Accent Stripe (Red for Issues, Green for Resolved)
              Container(
                width: 5,
                color: isResolved
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon + Title
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                isResolved
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.warning_amber_rounded,
                                color: isResolved
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Description
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(
                        color: Color(0xFFF1F5F9),
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 10),

                      // Bottom Row: Avatar + Name + Phone + Chevron
                      Row(
                        children: [
                          // Avatar Initial Circle
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                item.userInitial,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Name
                          Text(
                            item.userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),

                          // Phone Pill
                          if (item.phoneNumber != null &&
                              item.phoneNumber!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.phoneNumber!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Chevron Right Icon
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IssueTab tab) {
    final isResolved = tab == IssueTab.resolved;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isResolved
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isResolved
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: isResolved
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isResolved ? 'No Resolved Issues' : 'No Open Issues Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isResolved
                  ? 'Resolved collection issues will appear here.'
                  : 'Reported collection issues will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
