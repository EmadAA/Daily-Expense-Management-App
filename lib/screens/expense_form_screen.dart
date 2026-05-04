import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../services/currency_rate_service.dart';
import '../services/storage_service.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense; // null = add mode, non-null = edit mode

  const ExpenseFormScreen({super.key, this.expense});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
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
  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _currency = widget.expense?.currency ?? 'BDT';
    _sectorCtrl = TextEditingController(text: widget.expense?.sector ?? '');
    _detailsCtrl = TextEditingController(text: widget.expense?.details ?? '');
    _existingReceiptUrl = widget.expense?.receiptUrl;
    _amountCtrl = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toString() : '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
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
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
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
        final expense = ExpenseModel(
          id: widget.expense!.id,
          sector: _sectorCtrl.text.trim(),
          details: _detailsCtrl.text.trim(),
          amount: double.parse(_amountCtrl.text.trim()),
          date: _selectedDate,
          currency: _currency,
          receiptUrl: receiptUrl,
        );
        await ref.read(expenseProvider.notifier).update(expense);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              icon: const Icon(Icons.check_circle,
                  color: Color(0xFF1D9E75), size: 48),
              title: const Text('Updated!'),
              content: const Text('Expense has been updated successfully.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.pop(context);
        }
      } else {
        await ref.read(expenseProvider.notifier).add(
              ExpenseModel(
                id: '',
                sector: _sectorCtrl.text.trim(),
                details: _detailsCtrl.text.trim(),
                amount: double.parse(_amountCtrl.text.trim()),
                date: _selectedDate,
                currency: _currency,
              ),
            );
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              icon: const Icon(Icons.check_circle,
                  color: Color(0xFF1D9E75), size: 48),
              title: const Text('Saved!'),
              content: const Text('Expense has been saved successfully.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
          // Clear fields after saving
          if (mounted) {
            setState(() {
              _sectorCtrl.clear();
              _detailsCtrl.clear();
              _amountCtrl.clear();
              _selectedDate = DateTime.now();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sector
              TextFormField(
                controller: _sectorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sector name',
                  hintText: 'e.g. Food, Transport, Utilities',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a sector' : null,
              ),
              const SizedBox(height: 16),

              // Details
              TextFormField(
                controller: _detailsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'e.g. Lunch at restaurant',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (৳)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Text(
                      '৳',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter amount';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  if (v.contains('-')) return 'Amount cannot be negative';
                  if (double.parse(v) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 16),
// Receipt photo
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_pickedImage!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : _existingReceiptUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: // NEW
                                  Image.memory(
                                      base64Decode(_existingReceiptUrl!),
                                      fit: BoxFit.cover,
                                      width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 8),
                                Text('Add receipt photo (optional)',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                        fontSize: 13)),
                              ],
                            ),
                ),
              ),
// Currency selector
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                items: CurrencyRateService.supported
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child:
                              Text('$c  ${CurrencyRateService.symbolFor(c)}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),

              // Save button
              ElevatedButton(
                onPressed: (_isLoading || _uploadingImage) ? null : _save,
                child: _isLoading || _uploadingImage
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text(_uploadingImage
                              ? 'Uploading photo...'
                              : 'Saving...'),
                        ],
                      )
                    : Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
