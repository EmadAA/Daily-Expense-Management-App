import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../services/currency_rate_service.dart';
import '../services/storage_service.dart';

class IncomeFormScreen extends ConsumerStatefulWidget {
  final IncomeModel? income;
  const IncomeFormScreen({super.key, this.income});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  static const _green = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFEAF3DE);
  static const _greenMid = Color(0xFF5DCAA5);

  String _currency = 'BDT';
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sectorCtrl;
  late final TextEditingController _detailsCtrl;
  late final TextEditingController _amountCtrl;
  late DateTime _selectedDate;
  bool _isLoading = false;
  File? _pickedImage;
  String? _existingReceiptUrl;
  bool _uploadingImage = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    _currency = widget.income?.currency ?? 'BDT';
    _sectorCtrl = TextEditingController(text: widget.income?.sector ?? '');
    _detailsCtrl = TextEditingController(text: widget.income?.details ?? '');
    _existingReceiptUrl = widget.income?.receiptUrl;
    _amountCtrl = TextEditingController(
        text: widget.income != null ? widget.income!.amount.toString() : '');
    _selectedDate = widget.income?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _detailsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    String? receiptUrl = _existingReceiptUrl;
    if (_pickedImage != null) {
      setState(() => _uploadingImage = true);
      receiptUrl = await StorageService().imageToBase64(_pickedImage!);
      setState(() => _uploadingImage = false);
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final income = IncomeModel(
          id: widget.income!.id,
          sector: _sectorCtrl.text.trim(),
          details: _detailsCtrl.text.trim(),
          amount: double.parse(_amountCtrl.text.trim()),
          date: _selectedDate,
          currency: _currency,
          receiptUrl: receiptUrl,
          sourceType: widget.income!.sourceType,
          sourceId: widget.income!.sourceId,
        );
        await ref.read(incomeProvider.notifier).update(income);
        if (mounted) {
          await _showSuccessDialog('Updated!', 'Income updated successfully.');
          if (mounted) Navigator.pop(context);
        }
      } else {
        await ref.read(incomeProvider.notifier).add(IncomeModel(
              id: '',
              sector: _sectorCtrl.text.trim(),
              details: _detailsCtrl.text.trim(),
              amount: double.parse(_amountCtrl.text.trim()),
              date: _selectedDate,
              currency: _currency,
              receiptUrl: receiptUrl,
            ));
        if (mounted) {
          await _showSuccessDialog('Saved!', 'Income saved successfully.');
          if (mounted) {
            setState(() {
              _sectorCtrl.clear();
              _detailsCtrl.clear();
              _amountCtrl.clear();
              _selectedDate = DateTime.now();
              _pickedImage = null;
              _existingReceiptUrl = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: _green, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEditing ? 'OK' : 'Add More'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final bgColor = isDark ? const Color(0xFF0D1F18) : const Color(0xFFF4FBF7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Income' : 'Add Income',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header banner ─────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, _greenMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Edit income entry'
                                : 'New income entry',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fill in the details below',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Details ──────────────────
              _sectionLabel('Details', Icons.info_outline),
              const SizedBox(height: 12),

              // Sector
              _buildField(
                child: TextFormField(
                  controller: _sectorCtrl,
                  decoration: _fieldDecoration(
                    label: 'Sector name',
                    hint: 'e.g. Salary, Freelance, Business',
                    icon: Icons.label_outline,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter a sector' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Details
              _buildField(
                child: TextFormField(
                  controller: _detailsCtrl,
                  maxLines: 1,
                  decoration: _fieldDecoration(
                    label: 'Details',
                    hint: 'e.g. Monthly salary from ABC company',
                    icon: Icons.edit_note_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Amount ───────────────────
              _sectionLabel('Amount & Date', Icons.payments_outlined),
              const SizedBox(height: 12),

              // Amount + Currency row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildField(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: _fieldDecoration(
                          label: 'Amount',
                          hint: '0.00',
                          icon: Icons.attach_money_outlined,
                          prefix: Text(
                            CurrencyRateService.symbolFor(_currency),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _green),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter amount';
                          if (double.tryParse(v) == null) return 'Invalid';
                          if (v.contains('-')) return 'No negative';
                          if (double.parse(v) <= 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildField(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: _fieldDecoration(
                          label: 'Currency',
                          icon: Icons.currency_exchange,
                        ),
                        isDense: true,
                        isExpanded: true,
                        iconSize: 20,
                        items: CurrencyRateService.supported
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              _buildField(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      label: 'Date',
                      icon: Icons.calendar_today_outlined,
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Receipt ──────────────────
              _sectionLabel('Receipt Photo', Icons.receipt_long_outlined),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : _greenLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _green.withOpacity(0.3),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_pickedImage!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : _existingReceiptUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                  base64Decode(_existingReceiptUrl!),
                                  fit: BoxFit.cover,
                                  width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _green.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined,
                                      color: _green, size: 24),
                                ),
                                const SizedBox(height: 8),
                                Text('Tap to add receipt photo',
                                    style: TextStyle(
                                        color: _green.withOpacity(0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('Optional',
                                    style: TextStyle(
                                        color: _green.withOpacity(0.5),
                                        fontSize: 11)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button ───────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || _uploadingImage) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading || _uploadingImage
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                            Text(
                              _uploadingImage
                                  ? 'Uploading photo...'
                                  : 'Saving...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'Update Income' : 'Save Income',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
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

  // ── Helpers ──────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _green),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _green,
                letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: prefix,
            )
          : Icon(icon, color: _green, size: 20),
      labelStyle: TextStyle(color: _green.withOpacity(0.8), fontSize: 13),
      floatingLabelStyle:
          const TextStyle(color: _green, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      isDense: true,
    );
  }
}
