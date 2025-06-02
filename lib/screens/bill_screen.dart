import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';

import '../screens/admin_bill_toggles.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Management'),
        centerTitle: true,
        actions: [
          if (appState.currentUser?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Bill Splitting Toggles',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AdminBillTogglesScreen()),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Bills'),
            Tab(text: 'All Bills'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PersonalBillsTab(),
                _AllBillsTab(),
              ],
            ),
          ),
          // AdMob banner placeholder (actual AdMob integration pending)
          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'AdMob banner coming soon',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: appState.currentUser?.isAdmin ?? false
          ? FloatingActionButton(
              onPressed: () => _showAddBillDialog(context),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.add_rounded),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOut)
          : null,
    );
  }

  void _showAddBillDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddBillForm(),
      ),
    );
  }
}

class _PersonalBillsTab extends StatelessWidget {
  const _PersonalBillsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    // final theme = Theme.of(context);

    final bills = appState.currentUserBills;

    if (bills.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        message: 'You don\'t have any bills yet',
        actionLabel:
            appState.currentUser?.isAdmin ?? false ? 'Create Bill' : null,
        onActionPressed: appState.currentUser?.isAdmin ?? false
            ? () {
                (context.findAncestorStateOfType<_BillScreenState>()
                        as _BillScreenState)
                    ._showAddBillDialog(context);
              }
            : null,
      );
    }

    // Separate bills by payment status
    final unpaidBills = <Bill>[];
    final paidBills = <Bill>[];

    for (var bill in bills) {
      final status = bill.paymentStatus[appState.currentUser!.id];
      if (status == PaymentStatus.paid) {
        paidBills.add(bill);
      } else {
        unpaidBills.add(bill);
      }
    }

    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bill Summary
          _BillSummaryWidget(
            unpaidCount: unpaidBills.length,
            paidCount: paidBills.length,
            totalBills: bills.length,
          ),

          const SizedBox(height: 24),

          if (unpaidBills.isNotEmpty) ...[
            _buildSectionHeader(
                context, 'Unpaid Bills', Icons.pending_actions_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidBills.length,
              itemBuilder: (context, index) {
                return _BillCard(
                  bill: unpaidBills[index],
                  showPayButton: true,
                  onPayPressed: (billId) => appState.payBill(billId),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          if (paidBills.isNotEmpty) ...[
            _buildSectionHeader(
                context, 'Paid Bills', Icons.check_circle_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paidBills.length,
              itemBuilder: (context, index) {
                return _BillCard(
                  bill: paidBills[index],
                  showPayButton: false,
                  onPayPressed: (_) {},
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _AllBillsTab extends StatelessWidget {
  const _AllBillsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    if (!appState.currentUser!.isAdmin) {
      return const Center(
        child: Text('Only admins can view all bills'),
      );
    }

    final bills = appState.bills;

    if (bills.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        message: 'No bills have been created yet',
        actionLabel: 'Create Bill',
        onActionPressed: () {
          (context.findAncestorStateOfType<_BillScreenState>()
                  as _BillScreenState)
              ._showAddBillDialog(context);
        },
      );
    }

    // Group bills by type
    final Map<BillType, List<Bill>> billsByType = {};

    for (var bill in bills) {
      if (!billsByType.containsKey(bill.type)) {
        billsByType[bill.type] = [];
      }
      billsByType[bill.type]!.add(bill);
    }

    // Sort bill types for consistent order
    final sortedTypes = billsByType.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bill Summary
          _BillSummaryWidget(
            totalBills: bills.length,
            totalTypes: billsByType.length,
          ),

          const SizedBox(height: 24),

          // Bills by type
          for (var type in sortedTypes) ...[
            _buildTypeHeader(context, type),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: billsByType[type]!.length,
              itemBuilder: (context, index) {
                return _BillCard(
                  bill: billsByType[type]![index],
                  showPayButton: false,
                  showProgress: true,
                  onPayPressed: (_) {},
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeHeader(BuildContext context, BillType type) {
    final theme = Theme.of(context);

    String title;
    IconData icon;
    Color color;

    switch (type) {
      case BillType.rent:
        title = 'Rent Bills';
        icon = Icons.home_rounded;
        color = theme.colorScheme.primary;
        break;
      case BillType.utility:
        title = 'Utility Bills';
        icon = Icons.bolt_rounded;
        color = Colors.amber;
        break;
      case BillType.groceries:
        title = 'Grocery Bills';
        icon = Icons.shopping_cart_rounded;
        color = Colors.green;
        break;
      case BillType.communityMeals:
        title = 'Community Meals';
        icon = Icons.restaurant_rounded;
        color = theme.colorScheme.tertiary;
        break;
      case BillType.drinkingWater:
        title = 'Drinking Water';
        icon = Icons.water_drop_rounded;
        color = theme.colorScheme.secondary;
        break;
      case BillType.other:
        title = 'Other Bills';
        icon = Icons.receipt_rounded;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _BillSummaryWidget extends StatelessWidget {
  final int? unpaidCount;
  final int? paidCount;
  final int? totalBills;
  final int? totalTypes;

  const _BillSummaryWidget({
    this.unpaidCount,
    this.paidCount,
    this.totalBills,
    this.totalTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (unpaidCount != null && paidCount != null) {
      // Personal bills summary
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bills Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    count: unpaidCount!,
                    label: 'Unpaid',
                    icon: Icons.pending_actions_rounded,
                    textColor: theme.colorScheme.error,
                  ),
                  _SummaryItem(
                    count: paidCount!,
                    label: 'Paid',
                    icon: Icons.check_circle_rounded,
                    textColor: theme.colorScheme.secondary,
                  ),
                  _SummaryItem(
                    count: totalBills!,
                    label: 'Total',
                    icon: Icons.receipt_long_rounded,
                    textColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LabeledProgressIndicator(
                value: totalBills! > 0 ? paidCount! / totalBills! : 0,
                label: 'Payment Progress',
                progressColor: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms);
    } else {
      // Admin all bills summary
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bills Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    count: totalBills!,
                    label: 'Total Bills',
                    icon: Icons.receipt_long_rounded,
                    textColor: theme.colorScheme.primary,
                  ),
                  _SummaryItem(
                    count: totalTypes!,
                    label: 'Categories',
                    icon: Icons.category_rounded,
                    textColor: theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color textColor;

  const _SummaryItem({
    required this.count,
    required this.label,
    required this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: textColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final bool showPayButton;
  final bool showProgress;
  final Function(String) onPayPressed;

  const _BillCard({
    required this.bill,
    this.showPayButton = false,
    this.showProgress = false,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    // Get payment status for current user
    final status = bill.paymentStatus[appState.currentUser!.id];
    final isPaid = status == PaymentStatus.paid;

    // Get color based on bill type
    Color billColor;
    IconData billIcon;

    switch (bill.type) {
      case BillType.rent:
        billColor = theme.colorScheme.primary;
        billIcon = Icons.home_rounded;
        break;
      case BillType.utility:
        billColor = Colors.amber;
        billIcon = Icons.bolt_rounded;
        break;
      case BillType.groceries:
        billColor = Colors.green;
        billIcon = Icons.shopping_cart_rounded;
        break;
      case BillType.communityMeals:
        billColor = theme.colorScheme.tertiary;
        billIcon = Icons.restaurant_rounded;
        break;
      case BillType.drinkingWater:
        billColor = theme.colorScheme.secondary;
        billIcon = Icons.water_drop_rounded;
        break;
      case BillType.other:
        billColor = Colors.grey;
        billIcon = Icons.receipt_rounded;
        break;
    }

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: billColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    billIcon,
                    color: billColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${bill.getFormattedDueDate()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: bill.isOverdue() && !isPaid
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${bill.getAmountPerUser().toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: billColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPaid)
                      StatusBadge(
                        text: 'PAID',
                        color: theme.colorScheme.secondary,
                      )
                    else if (showPayButton)
                      ElevatedButton(
                        onPressed: () => onPayPressed(bill.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: billColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Pay Now'),
                      )
                    else
                      StatusBadge(
                        text: 'UNPAID',
                        color: theme.colorScheme.error,
                      ),
                  ],
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabeledProgressIndicator(
                      value: bill.getPaymentProgress(),
                      label:
                          'Payment Progress (${bill.getPaidCount()}/${bill.userIds.length})',
                      progressColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(
        begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
  }
}

class _AddBillForm extends StatefulWidget {
  const _AddBillForm();

  @override
  State<_AddBillForm> createState() => _AddBillFormState();
}

class _AddBillFormState extends State<_AddBillForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  BillType _selectedType = BillType.utility;
  List<String> _selectedUsers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Bill',
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bill Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Bill Name',
                hintText: 'e.g. Electricity Bill - July',
                prefixIcon: Icon(Icons.description_rounded,
                    color: theme.colorScheme.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for the bill';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bill Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                hintText: 'Total bill amount',
                prefixIcon: Icon(Icons.attach_money_rounded,
                    color: theme.colorScheme.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the bill amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Due Date: ${DateFormat.yMMMd().format(_dueDate)}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dueDate = pickedDate;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bill Type
            Text(
              'Bill Type',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _BillTypeChip(
                  type: BillType.rent,
                  label: 'Rent',
                  icon: Icons.home_rounded,
                  isSelected: _selectedType == BillType.rent,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.rent;
                      });
                    }
                  },
                ),
                _BillTypeChip(
                  type: BillType.utility,
                  label: 'Utility',
                  icon: Icons.bolt_rounded,
                  isSelected: _selectedType == BillType.utility,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.utility;
                      });
                    }
                  },
                ),
                _BillTypeChip(
                  type: BillType.groceries,
                  label: 'Grocery',
                  icon: Icons.shopping_cart_rounded,
                  isSelected: _selectedType == BillType.groceries,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.groceries;
                      });
                    }
                  },
                ),
                _BillTypeChip(
                  type: BillType.communityMeals,
                  label: 'Community Meals',
                  icon: Icons.restaurant_rounded,
                  isSelected: _selectedType == BillType.communityMeals,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.communityMeals;
                      });
                    }
                  },
                ),
                _BillTypeChip(
                  type: BillType.drinkingWater,
                  label: 'Drinking Water',
                  icon: Icons.water_drop_rounded,
                  isSelected: _selectedType == BillType.drinkingWater,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.drinkingWater;
                      });
                    }
                  },
                ),
                _BillTypeChip(
                  type: BillType.other,
                  label: 'Other',
                  icon: Icons.receipt_rounded,
                  isSelected: _selectedType == BillType.other,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = BillType.other;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Select Users
            Text(
              'Select Users',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected: ${_selectedUsers.length} users',
                        style: theme.textTheme.bodyMedium,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedUsers =
                                appState.users.map((user) => user.id).toList();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Select All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.users.length,
                    itemBuilder: (context, index) {
                      final user = appState.users[index];
                      final isSelected = _selectedUsers.contains(user.id);

                      return CheckboxListTile(
                        title: Text(user.name),
                        subtitle: Text(
                          'Role: ${user.role.name}',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUsers.add(user.id);
                            } else {
                              _selectedUsers.remove(user.id);
                            }
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                        checkColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newBill = Bill(
                    id: const Uuid().v4(),
                    title: _nameController.text.trim(),
                    description: '',
                    amount: double.parse(_amountController.text.trim()),
                    dueDate: _dueDate,
                    type: _selectedType,
                    userIds: _selectedUsers,
                    paymentStatus: {},
                  );

                  appState.createBill(newBill);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Bill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillTypeChip extends StatelessWidget {
  final BillType type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _BillTypeChip({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
