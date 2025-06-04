import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state_provider.dart';
import '../models/bill_model.dart'; // Correct: Use Bill, BillType, PaymentStatus from here
import '../models/app_models.dart' show SubscriptionType, Task, Vote, Apartment; // Keep other needed models from app_models
// AppUser is already available via AppStateProvider
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';
import '../screens/admin_bill_toggles.dart'; // This might need adjustment if it uses old Bill model

// Note: Ensure AdminBillTogglesScreen is also updated if it uses Bill model directly.

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
          // Assuming appState.currentUser.role is how admin status is checked now
          if (appState.currentUser?.role == 'Roommate-Admin' || appState.currentUser?.role == 'Owner-Admin')
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
              theme.colorScheme.onSurface.withOpacity(0.7), // Updated for clarity
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
      floatingActionButton: (appState.currentUser?.role == 'Roommate-Admin' || appState.currentUser?.role == 'Owner-Admin')
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
        builder: (_, controller) => const _AddBillForm(), // _AddBillForm will need AppStateProvider
      ),
    );
  }
}

class _PersonalBillsTab extends StatelessWidget {
  const _PersonalBillsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bool isAdmin = appState.currentUser?.role == 'Roommate-Admin' || appState.currentUser?.role == 'Owner-Admin';


    final bills = appState.currentUserBills; // This getter in AppStateProvider should use the correct Bill model

    if (bills.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        message: 'You don\'t have any bills yet',
        actionLabel: isAdmin ? 'Create Bill' : null,
        onActionPressed: isAdmin
            ? () {
                (context.findAncestorStateOfType<_BillScreenState>()
                        as _BillScreenState)
                    ._showAddBillDialog(context);
              }
            : null,
      );
    }

    final unpaidBills = <Bill>[];
    final paidBills = <Bill>[];

    for (var bill in bills) {
      final status = bill.paymentStatus[appState.currentUser!.id];
      if (status == PaymentStatus.paid) { // Correct PaymentStatus from bill_model.dart
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
          _BillSummaryWidget(
            unpaidCount: unpaidBills.length,
            paidCount: paidBills.length,
            totalBills: bills.length,
          ),
          const SizedBox(height: 24),
          if (unpaidBills.isNotEmpty) ...[
            _buildSectionHeader(context, 'Unpaid Bills', Icons.pending_actions_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidBills.length,
              itemBuilder: (context, index) {
                // Calculate portion here before passing to _BillCard
                return FutureBuilder<RentPortionDetails>( // Expect RentPortionDetails
                  future: appState.getCalculatedBillPortionForUser(unpaidBills[index], appState.currentUser!.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                       final tempBill = unpaidBills[index];
                       // Simplified placeholder, ideally show a loading shimmer or similar for the card
                       final simplePortion = tempBill.amount / (tempBill.userIds.isEmpty ? 1 : tempBill.userIds.length);
                       return Opacity(opacity: 0.5, child: _BillCard(bill: tempBill, userPortion: simplePortion, rentDetails: null, showPayButton: true, onPayPressed: (billId) => appState.payBill(billId)));
                    }
                    if (snapshot.hasError) {
                      debugPrint("Error fetching bill portion: ${snapshot.error}");
                      return Opacity(opacity: 0.7, child: _BillCard(bill: unpaidBills[index], userPortion: 0.0, rentDetails: null, showPayButton: true, onPayPressed: (billId) => appState.payBill(billId), errorMessage: "Could not calculate amount"));
                    }
                    final rentDetails = snapshot.data;
                    return _BillCard(
                        bill: unpaidBills[index],
                        userPortion: rentDetails?.totalAmountDue ?? 0.0,
                        rentDetails: rentDetails,
                        showPayButton: true,
                        onPayPressed: (billId) => appState.payBill(billId)
                    );
                  }
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          if (paidBills.isNotEmpty) ...[
            _buildSectionHeader(context, 'Paid Bills', Icons.check_circle_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paidBills.length,
              itemBuilder: (context, index) {
                 return FutureBuilder<RentPortionDetails>( // Expect RentPortionDetails
                  future: appState.getCalculatedBillPortionForUser(paidBills[index], appState.currentUser!.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                       final tempBill = paidBills[index];
                       final simplePortion = tempBill.amount / (tempBill.userIds.isEmpty ? 1 : tempBill.userIds.length);
                       return Opacity(opacity: 0.5, child: _BillCard(bill: tempBill, userPortion: simplePortion, rentDetails: null, showPayButton: false, onPayPressed: (_){}));
                    }
                     if (snapshot.hasError) {
                      debugPrint("Error fetching bill portion: ${snapshot.error}");
                      return Opacity(opacity: 0.7, child: _BillCard(bill: paidBills[index], userPortion: 0.0, rentDetails: null, showPayButton: false, onPayPressed: (_){}, errorMessage: "Could not calculate amount"));
                    }
                    final rentDetails = snapshot.data;
                    return _BillCard(
                        bill: paidBills[index],
                        userPortion: rentDetails?.totalAmountDue ?? 0.0,
                        rentDetails: rentDetails,
                        showPayButton: false,
                        onPayPressed: (_){}
                    );
                  }
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _AllBillsTab extends StatelessWidget {
  const _AllBillsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bool isAdmin = appState.currentUser?.role == 'Roommate-Admin' || appState.currentUser?.role == 'Owner-Admin';

    if (!isAdmin) {
      return const Center(child: Text('Only admins can view all bills'));
    }

    final bills = appState.bills; // Uses correct Bill model from AppStateProvider

    if (bills.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded, message: 'No bills have been created yet',
        actionLabel: 'Create Bill',
        onActionPressed: () => (context.findAncestorStateOfType<_BillScreenState>() as _BillScreenState)._showAddBillDialog(context),
      );
    }

    final Map<BillType, List<Bill>> billsByType = {};
    for (var bill in bills) {
      billsByType.putIfAbsent(bill.type, () => []).add(bill);
    }
    final sortedTypes = billsByType.keys.toList()..sort((a, b) => a.index.compareTo(b.index));

    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BillSummaryWidget(totalBills: bills.length, totalTypes: billsByType.length),
          const SizedBox(height: 24),
          for (var type in sortedTypes) ...[
            _buildTypeHeader(context, type), // Uses correct BillType from bill_model.dart
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: billsByType[type]!.length,
              itemBuilder: (context, index) {
                final bill = billsByType[type]![index];
                bool isMultiUserBill = bill.userIds.length > 1;

                Widget billCard = _BillCard(
                  bill: bill,
                  userPortion: bill.amount, // Show total amount for the main card in this tab
                  rentDetails: null, // No breakdown needed for the main card here
                  showPayButton: false,
                  showProgress: true,
                  onPayPressed: (_) {},
                );

                if (!isMultiUserBill || bill.userIds.isEmpty) {
                  return billCard; // Show only the card if single user or no users
                }

                return ExpansionTile(
                  key: PageStorageKey<String>(bill.id), // Keep expansion state
                  title: billCard,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: bill.userIds.map((userId) {
                    final user = appState.users.firstWhere((u) => u.id == userId, orElse: () => null);
                    if (user == null) return const SizedBox.shrink();

                    final paymentStatus = bill.paymentStatus[userId] ?? PaymentStatus.unpaid;
                    final bool isUserPaid = paymentStatus == PaymentStatus.paid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                                FutureBuilder<RentPortionDetails>(
                                  future: appState.getCalculatedBillPortionForUser(bill, userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Text('Calculating...', style: TextStyle(fontSize: 12, color: Colors.grey));
                                    }
                                    if (snapshot.hasError) {
                                      return const Text('Error', style: TextStyle(fontSize: 12, color: Colors.red));
                                    }
                                    final details = snapshot.data;
                                    final formattedPortion = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(details?.totalAmountDue ?? 0.0);
                                    return Text('Portion: $formattedPortion', style: Theme.of(context).textTheme.bodySmall);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(
                                paymentStatus.toString().split('.').last.toUpperCase(), // e.g. "PAID", "UNPAID"
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUserPaid ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              if (isAdmin) // Only show buttons if current user is admin
                                TextButton(
                                  onPressed: () {
                                    appState.markUserBillPayment(bill.id, userId, isUserPaid ? PaymentStatus.unpaid : PaymentStatus.paid);
                                  },
                                  child: Text(isUserPaid ? 'Mark Unpaid' : 'Mark Paid'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(50,30), // Adjust size
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

   Widget _buildTypeHeader(BuildContext context, BillType type) { // BillType from bill_model.dart
    final theme = Theme.of(context);
    String title; IconData icon; Color color;
    switch (type) {
      case BillType.rent: title = 'Rent Bills'; icon = Icons.home_rounded; color = theme.colorScheme.primary; break;
      case BillType.utility: title = 'Utility Bills'; icon = Icons.bolt_rounded; color = Colors.amber; break;
      // case BillType.groceries: title = 'Grocery Bills'; icon = Icons.shopping_cart_rounded; color = Colors.green; break; // Assuming groceries is not in bill_model.BillType
      case BillType.communityMeals: title = 'Community Meals'; icon = Icons.restaurant_rounded; color = theme.colorScheme.tertiary; break;
      case BillType.drinkingWater: title = 'Drinking Water'; icon = Icons.water_drop_rounded; color = theme.colorScheme.secondary; break;
      case BillType.other: title = 'Other Bills'; icon = Icons.receipt_rounded; color = Colors.grey; break;
      default: title = 'Unknown Bills'; icon = Icons.help_outline; color = Colors.grey; // Handle any other types just in case
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// _BillSummaryWidget remains largely the same, ensure labels/icons are generic enough
// or adapt if specific BillType logic was deeply embedded.
// For now, assuming it's okay as it deals with counts.
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
            color: textColor.withOpacity(0.1), // Updated for clarity
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
            color: theme.colorScheme.onSurface.withOpacity(0.7), // Updated for clarity
          ),
        ),
      ],
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final double userPortion;
  final RentPortionDetails? rentDetails; // Made this non-nullable in previous thought, but it should be nullable for _AllBillsTab
  final bool showPayButton;
  final bool showProgress;
  final Function(String) onPayPressed;
  final String? errorMessage; // Optional error message

  const _BillCard({
    required this.bill,
    required this.userPortion,
    this.rentDetails, // Nullable
    this.showPayButton = false,
    this.showProgress = false,
    required this.onPayPressed,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final currentUser = appState.currentUser; // Could be null

    final status = currentUser != null ? bill.paymentStatus[currentUser.id] : null;
    final isPaid = status == PaymentStatus.paid; // PaymentStatus from bill_model.dart

    Color billColor; IconData billIcon;
    switch (bill.type) { // BillType from bill_model.dart
      case BillType.rent: billColor = theme.colorScheme.primary; billIcon = Icons.home_rounded; break;
      case BillType.utility: billColor = Colors.amber; billIcon = Icons.bolt_rounded; break;
      case BillType.communityMeals: billColor = theme.colorScheme.tertiary; billIcon = Icons.restaurant_rounded; break;
      case BillType.drinkingWater: billColor = theme.colorScheme.secondary; billIcon = Icons.water_drop_rounded; break;
      case BillType.other: billColor = Colors.grey; billIcon = Icons.receipt_rounded; break;
      // Removed groceries as it's not in bill_model.BillType
      default: billColor = Colors.grey; billIcon = Icons.help_outline;
    }

    final String formattedAmount = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(userPortion);


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
                  decoration: BoxDecoration(color: billColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(billIcon, color: billColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), // Changed from bill.title
                      if (bill.description != null && bill.description!.isNotEmpty) ...[
                        Text(bill.description!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat.yMMMd().format(bill.dueDate)}', // Used DateFormat
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: bill.dueDate.isBefore(DateTime.now()) && !isPaid ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.7),
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
                    if (errorMessage != null)
                      Text(errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12))
                    else
                      Text(
                        formattedAmount,
                        style: theme.textTheme.titleMedium?.copyWith(color: billColor, fontWeight: FontWeight.bold),
                      ),
                    if (errorMessage == null) ...[ // Only show status/button if no error
                      if (isPaid)
                        StatusBadge(text: 'PAID', color: theme.colorScheme.secondary)
                      else if (showPayButton && currentUser != null && bill.userIds.contains(currentUser.id))
                        ElevatedButton(
                          onPressed: () => onPayPressed(bill.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: billColor, foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Pay Now'),
                        )
                      else if (bill.userIds.contains(currentUser?.id))
                         StatusBadge(text: 'UNPAID', color: theme.colorScheme.error)
                      else
                         Container(),
                    ]
                  ],
                ),
              ],
            ),
            if (rentDetails != null && rentDetails!.vacancyShortfallShare > 0 && bill.type == BillType.rent && errorMessage == null) ...[
              const Divider(height: 24, thickness: 0.5),
              Text('Rent Breakdown:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Base Rent:', style: theme.textTheme.bodySmall),
                  Text(NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(rentDetails!.baseRentPortion), style: theme.textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vacancy/Shortfall Share:', style: theme.textTheme.bodySmall),
                  Text('+ ${NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(rentDetails!.vacancyShortfallShare)}', style: theme.textTheme.bodySmall),
                ],
              ),
               const SizedBox(height: 4),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Total Rent:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(rentDetails!.totalAmountDue), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            if (showProgress && errorMessage == null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: LabeledProgressIndicator(
                  value: bill.getPaymentProgress(),
                  label: 'Payment Progress (${bill.getPaidCount()}/${bill.userIds.length})',
                  progressColor: theme.colorScheme.secondary,
                )),
              ]),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
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
  final _descriptionController = TextEditingController(); // Added for description
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  BillType _selectedType = BillType.utility; // BillType from bill_model.dart
  List<String> _selectedUsers = [];
  String? _selectedApartmentId; // For rent bills

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateUsersForRentBill(AppStateProvider appState) {
    if (_selectedType == BillType.rent && _selectedApartmentId != null) {
      final apartment = appState.apartments.firstWhere((apt) => apt.id == _selectedApartmentId, orElse: () => null);
      if (apartment != null) {
        _selectedUsers = appState.users
            .where((user) => user.assignedBedId != null && apartment.rooms.any((room) => room.beds.any((bed) => bed.id == user.assignedBedId)))
            .map((user) => user.id)
            .toList();
      } else {
        _selectedUsers = [];
      }
    } else if (_selectedType != BillType.rent) {
      // Potentially clear or keep users based on desired UX for other types
    }
    setState(() {}); // Update UI for user selection
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create New Bill', style: theme.textTheme.headlineSmall),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Bill Name*', hintText: 'e.g. Electricity Bill - July',
                prefixIcon: Icon(Icons.description_rounded, color: theme.colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name for the bill' : null,
            ),
            const SizedBox(height: 16),
            TextFormField( // Description field
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)', hintText: 'e.g. Monthly common area electricity',
                prefixIcon: Icon(Icons.notes_rounded, color: theme.colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedType == BillType.rent) ...[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Apartment*',
                  prefixIcon: Icon(Icons.apartment_rounded, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedApartmentId,
                hint: const Text('Choose apartment for rent bill'),
                items: appState.apartments.map((Apartment apt) {
                  return DropdownMenuItem<String>(value: apt.id, child: Text(apt.name));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedApartmentId = newValue;
                    _updateUsersForRentBill(appState);
                  });
                },
                validator: (value) => (_selectedType == BillType.rent && value == null) ? 'Apartment is required for rent bills' : null,
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total Amount*', hintText: 'Total bill amount',
                prefixIcon: Icon(Icons.attach_money_rounded, color: theme.colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter the bill amount';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Due Date: ${DateFormat.yMMMd().format(_dueDate)}', style: theme.textTheme.titleMedium),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (pickedDate != null) setState(() => _dueDate = pickedDate);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), foregroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Bill Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BillType.values.map((type) { // Use BillType from bill_model.dart
                String label; IconData icon;
                 switch (type) {
                    case BillType.rent: label = 'Rent'; icon = Icons.home_rounded; break;
                    case BillType.utility: label = 'Utility'; icon = Icons.bolt_rounded; break;
                    case BillType.communityMeals: label = 'Meals'; icon = Icons.restaurant_rounded; break;
                    case BillType.drinkingWater: label = 'Water'; icon = Icons.water_drop_rounded; break;
                    case BillType.other: label = 'Other'; icon = Icons.receipt_rounded; break;
                    // Removed groceries as it's not in bill_model.BillType
                    default: label = 'Unknown'; icon = Icons.help_outline;
                  }
                return _BillTypeChip(
                  type: type, label: label, icon: icon,
                  isSelected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() {
                       _selectedType = type;
                       _updateUsersForRentBill(appState); // Update users if type changes to/from rent
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Select Users', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selected: ${_selectedUsers.length} users', style: theme.textTheme.bodyMedium),
                      if (_selectedType != BillType.rent) // Disable "Select All" for rent bills as users are auto-populated
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedUsers = appState.users.map((user) => user.id).toList()),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), foregroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                        subtitle: Text('Role: ${user.role}', style: theme.textTheme.bodySmall), // AppUser.role is String
                        value: isSelected,
                        onChanged: _selectedType == BillType.rent ? null : (value) { // Disable checkbox for rent bills
                          setState(() {
                            if (value == true) _selectedUsers.add(user.id);
                            else _selectedUsers.remove(user.id);
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                        checkColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save(); // Ensure all onSaved are called
                  if (_selectedType == BillType.rent && _selectedApartmentId == null) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an apartment for rent bills.')));
                     return;
                  }
                  if (_selectedUsers.isEmpty && _selectedType != BillType.rent ) { // For rent, users are auto-populated or can be empty if no one in apt
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one user for this bill.')));
                     return;
                  }

                  final newBill = Bill( // Bill from bill_model.dart
                    id: const Uuid().v4(),
                    name: _nameController.text.trim(), // Changed from title
                    description: _descriptionController.text.trim(), // Added
                    amount: double.parse(_amountController.text.trim()),
                    dueDate: _dueDate,
                    type: _selectedType,
                    userIds: _selectedUsers,
                    paymentStatus: {}, // Initial empty status
                    apartmentId: _selectedType == BillType.rent ? _selectedApartmentId : null, // Add apartmentId
                    incomePoolRewardOffset: 0.0, // Default value
                  );
                  appState.createBill(newBill);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Create Bill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillTypeChip extends StatelessWidget {
  final BillType type; // BillType from bill_model.dart
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
      selectedColor: theme.colorScheme.primary.withOpacity(0.2), // Updated for clarity
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
