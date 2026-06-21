// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'current_month_summary_card.dart';

class CollapsibleMonthlySummary extends StatefulWidget {
  final bool balanceVisible;

  const CollapsibleMonthlySummary({
    super.key,
    required this.balanceVisible,
  });

  @override
  State<CollapsibleMonthlySummary> createState() => _CollapsibleMonthlySummaryState();
}

class _CollapsibleMonthlySummaryState extends State<CollapsibleMonthlySummary>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('showMonthlySummary');
    if (saved != null && mounted) {
      setState(() {
        _isExpanded = saved;
        if (_isExpanded) {
          _expandCtrl.value = 1.0;
        }
      });
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showMonthlySummary', _isExpanded);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandCtrl.forward();
      } else {
        _expandCtrl.reverse();
      }
      _savePreference();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isExpanded
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _isExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _isExpanded
                        ? 'Hide Monthly Summary'
                        : 'Show Monthly Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _isExpanded
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _isExpanded
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Collapsible Content
        AnimatedBuilder(
          animation: _expandAnim,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                heightFactor: _expandAnim.value,
                child: child,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: CurrentMonthSummaryCard(),
          ),
        ),
      ],
    );
  }
}