import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/features/direct_disposal/screen/widgets/direct_tabs.dart';
import 'package:floret_collector/features/direct_disposal/screen/widgets/log_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/direct_disposal_view_model.dart';

class DirectDisposalScreen extends StatefulWidget {
  static const String routeName = '/DirectDisposalScreen';

  final int? remainingBags;

  const DirectDisposalScreen({
    super.key,
    this.remainingBags,
  });

  @override
  State<DirectDisposalScreen> createState() => _DirectDisposalScreenState();
}

class _DirectDisposalScreenState extends State<DirectDisposalScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _descController;
  late final TextEditingController _weightController;
  late final TextEditingController _rateController;
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _descController = TextEditingController();
    _weightController = TextEditingController();
    _rateController = TextEditingController(text: '2.00');
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _weightController.dispose();
    _rateController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(DirectDisposalViewModel vm) async {
    setState(() => _isSubmitting = true);
    try {
      final success = await vm.submitRecord();
      if (!mounted) return;
      if (success) {
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _descController.clear();
        _weightController.clear();
        _rateController.text = '2.00';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Direct disposal recorded successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DirectDisposalViewModel>(
      create: (_) {
        final vm = getIt.isRegistered<DirectDisposalViewModel>()
            ? getIt<DirectDisposalViewModel>()
            : DirectDisposalViewModel();

        return vm;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<DirectDisposalViewModel>(
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
                              'Direct Disposal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balances the back button
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tabs: New Record | Disposal Logs
                  buildTabs(vm),
                  // Body Content
                  Expanded(
                    child: vm.selectedTab == DirectDisposalTab.newRecord
                        ? buildNewRecordForm(
                            context: context,
                            vm: vm,
                            scrollController: _scrollController,
                            nameController: _nameController,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            descController: _descController,
                            weightController: _weightController,
                            rateController: _rateController,
                            remainingBags: widget.remainingBags,
                            isSubmitting: _isSubmitting,
                            onSubmit: () => _handleSubmit(vm),
                          )
                        : buildDisposalLogsList(
                            context: context,
                            vm: vm,
                            searchController: _searchController,
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
}
