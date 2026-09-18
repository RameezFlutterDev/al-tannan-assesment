import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controllers/employees_controller.dart';

/// Pass [existing] to edit, or leave null to create a new employee.
class EmployeeFormDialog extends StatefulWidget {
  const EmployeeFormDialog({super.key, this.existing});

  final Employee? existing;

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _emailController =
      TextEditingController(text: widget.existing?.email ?? '');
  final _passwordController = TextEditingController();
  late final _codeController =
      TextEditingController(text: widget.existing?.employeeCode ?? '');

  late UserRole _role = widget.existing?.role ?? UserRole.employee;
  late String? _shiftId = widget.existing?.currentShiftId;
  late String? _locationId = widget.existing?.currentLocationId;

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final controller = Get.find<EmployeesController>();
    String? error;
    if (_isEditing) {
      error = await controller.updateEmployee(widget.existing!.copyWith(
        name: _nameController.text.trim(),
        employeeCode: _codeController.text.trim(),
        role: _role,
        currentShiftId: _shiftId,
        currentLocationId: _locationId,
      ));
    } else {
      error = await controller.createEmployee(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        employeeCode: _codeController.text.trim(),
        role: _role,
        shiftId: _shiftId,
        locationId: _locationId,
      );
    }

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeesController>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              color: const Color(0xFF4F46E5),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(_isEditing ? 'Edit Employee' : 'New Employee'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Employee code',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.wireValue)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _shiftId,
                  decoration: const InputDecoration(
                    labelText: 'Shift',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  // Only active shifts are offered for a NEW assignment —
                  // except the one already assigned (if any), which stays
                  // visible (marked inactive) so editing this employee's
                  // other fields doesn't silently wipe a still-recorded
                  // assignment just because that shift was later retired.
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Not assigned')),
                    ...controller.shifts
                        .where((s) => s.isActive || s.id == _shiftId)
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.isActive ? s.name : '${s.name} (Inactive)'),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _shiftId = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _locationId,
                  decoration: const InputDecoration(
                    labelText: 'Work location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Not assigned')),
                    ...controller.locations
                        .where((l) => l.isActive || l.id == _locationId)
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.isActive ? l.name : '${l.name} (Inactive)'),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _locationId = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Employee'),
        ),
      ],
    );
  }
}
