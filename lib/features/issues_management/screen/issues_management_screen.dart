import 'package:floret_collector/core/di/injection.dart';
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
      create: (_) => getIt.isRegistered<IssuesViewModel>()
          ? getIt<IssuesViewModel>()
          : IssuesViewModel(),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
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
                              onTap: () => vm.setSelectedTab(IssueTab.issues),
                            ),
                          ),

                          // Tab 2: Resolved
                          Expanded(
                            child: _buildTabButton(
                              label: 'Resolved',
                              count: vm.resolvedCount,
                              isSelected: vm.selectedTab == IssueTab.resolved,
                              badgeColor: const Color(0xFF10B981),
                              onTap: () => vm.setSelectedTab(IssueTab.resolved),
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
                                  return InkWell(
                                      onTap: () {
                                        _showIssueDetailsBottomSheet(
                                            context, vm, item);
                                      },
                                      child: _buildIssueCard(item));
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _buildIssueCard(IssueModel item) {
    final isResolved = item.isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(11),
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

                          // Name and Phone
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.userName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
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
                                        Flexible(
                                          child: Text(
                                            item.phoneNumber!,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

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

  void _showIssueDetailsBottomSheet(
    BuildContext context,
    IssuesViewModel vm,
    IssueModel item,
  ) {
    final isResolved = item.isResolved;
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Drag Handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Header Row: Icon + "Issue Details" + Close Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 16, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
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
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Issue Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 24,
                                  color: Color(0xFF64748B),
                                ),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        // Card: Subject, Description, Divider, User Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SUBJECT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'DESCRIPTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description.isNotEmpty
                                      ? item.description
                                      : 'No description provided.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  color: Color(0xFFF1F5F9),
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          item.userInitial,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.userName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (item.phoneNumber != null &&
                                              item.phoneNumber!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone_outlined,
                                                  size: 13,
                                                  color: Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    item.phoneNumber!,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Resolution Notes
                        if (!isResolved) ...[
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Resolution Notes (Optional)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                controller: notesController,
                                minLines: 3,
                                maxLines: 5,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Enter details describing how issue was resolved...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ),
                        ] else if (item.resolutionNotes != null &&
                            item.resolutionNotes!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Resolution Notes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                item.resolutionNotes!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Bottom Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isResolved
                                  ? () => Navigator.pop(ctx)
                                  : (isSubmitting
                                      ? null
                                      : () async {
                                          setSheetState(
                                              () => isSubmitting = true);
                                          final success =
                                              await vm.resolveIssue(
                                            issue: item,
                                            resolutionNotes:
                                                notesController.text.trim(),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Issue marked as resolved successfully',
                                                  ),
                                                  backgroundColor:
                                                      Color(0xFF10B981),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to resolve issue. Please try again.',
                                                  ),
                                                  backgroundColor:
                                                      Color(0xFFEF4444),
                                                ),
                                              );
                                            }
                                          }
                                        }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      isResolved
                                          ? 'Close'
                                          : 'Mark as Resolved',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
