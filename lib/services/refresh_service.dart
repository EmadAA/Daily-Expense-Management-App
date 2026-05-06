import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/savings_goal_provider.dart';

void refreshAll(WidgetRef ref) {
  ref.invalidate(incomeProvider);
  ref.invalidate(accountProvider);
  ref.invalidate(expenseProvider);
  ref.invalidate(loanProvider);
  ref.invalidate(savingsGoalProvider);
  ref.invalidate(budgetProvider);
  ref.invalidate(recurringProvider);
  ref.invalidate(profileProvider);
}
