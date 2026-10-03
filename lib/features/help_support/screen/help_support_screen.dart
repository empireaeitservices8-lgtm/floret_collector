import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/faq_item_model.dart';
import '../viewmodel/help_support_view_model.dart';

class HelpSupportScreen extends StatefulWidget {
  static const String routeName = '/HelpSupportScreen';

  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HelpSupportViewModel>(
      create: (_) => HelpSupportViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<HelpSupportViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  const SizedBox(height: 4),

                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                              'Help & Support',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: vm.isRefreshing ? null : vm.refresh,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Contact Cards: Call Support & Email Support
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Card 1: Call Support
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.phone_forwarded_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBgColor: const Color(0xFFDCFCE7),
                            title: 'Call Support',
                            subtitle: '+91 92920 23601',
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card 2: Email Support
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.mail_outline_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            title: 'Email Support',
                            subtitle: 'florettechnologi...',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: vm.setSearchQuery,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'How can we help you? Search FAQs...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          suffixIcon: vm.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    vm.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main FAQ Body or Refresh Indicator
                  Expanded(
                    child: vm.isRefreshing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E293B),
                              strokeWidth: 3,
                            ),
                          )
                        : _buildFaqList(vm),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList(HelpSupportViewModel vm) {
    final faqs = vm.filteredFaqs;

    if (faqs.isEmpty) {
      return const Center(
        child: Text(
          'No FAQs found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        final isExpanded = vm.isExpanded(faq.id);

        return _buildFaqCard(
          faq: faq,
          isExpanded: isExpanded,
          onTap: () => vm.toggleExpanded(faq.id),
        );
      },
    );
  }

  Widget _buildFaqCard({
    required FaqItemModel faq,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
