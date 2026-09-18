import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controllers/locations_controller.dart';

class LocationFormDialog extends StatefulWidget {
  const LocationFormDialog({super.key, this.existing});

  final WorkLocation? existing;

  @override
  State<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _latController =
      TextEditingController(text: widget.existing?.latitude.toString() ?? '');
  late final _lngController =
      TextEditingController(text: widget.existing?.longitude.toString() ?? '');
  late final _radiusController =
      TextEditingController(text: (widget.existing?.radiusMeters ?? 150).toString());

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final latitude = double.parse(_latController.text);
    final controller = Get.find<LocationsController>();
    final location = WorkLocation(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      latitude: latitude,
      longitude: double.parse(_lngController.text),
      radiusMeters: double.parse(_radiusController.text),
      isActive: widget.existing?.isActive ?? true,
      cosLatitude: WorkLocation.computeCosLatitude(latitude),
    );

    if (_isEditing) {
      await controller.updateLocation(location);
    } else {
      await controller.createLocation(location);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditing ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
              color: const Color(0xFF0284C7),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(_isEditing ? 'Edit Location' : 'New Location'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.my_location_rounded),
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null)
                          ? 'Enter valid lat'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.my_location_rounded),
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null)
                          ? 'Enter valid lng'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _radiusController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Geofence radius (meters)',
                  prefixIcon: Icon(Icons.radar_rounded),
                ),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Enter a number' : null,
              ),
            ],
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
              : const Text('Save Location'),
        ),
      ],
    );
  }
}
