import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../controllers/reports_controller.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text('${_fmt(controller.from)} → ${_fmt(controller.to)}'),
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
              initialDateRange: DateTimeRange(start: controller.from, end: controller.to),
            );
            if (range != null) controller.setDateRange(range.start, range.end);
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ReportFilterDimension>(
              value: controller.dimension,
              items: const [
                DropdownMenuItem(value: ReportFilterDimension.none, child: Text('No filter')),
                DropdownMenuItem(value: ReportFilterDimension.employee, child: Text('By employee')),
                DropdownMenuItem(value: ReportFilterDimension.location, child: Text('By location')),
                DropdownMenuItem(value: ReportFilterDimension.shift, child: Text('By shift')),
                DropdownMenuItem(value: ReportFilterDimension.status, child: Text('By status')),
              ],
              onChanged: (v) => controller.setDimension(v!),
            ),
          ),
        ),
        if (controller.dimension == ReportFilterDimension.employee)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text('Select employee'),
                value: controller.selectedEmployeeId,
                items: controller.employees
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                    .toList(),
                onChanged: controller.setFilterValue,
              ),
            ),
          ),
        if (controller.dimension == ReportFilterDimension.location)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text('Select location'),
                value: controller.selectedLocationId,
                items: controller.locations
                    .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
                    .toList(),
                onChanged: controller.setFilterValue,
              ),
            ),
          ),
        if (controller.dimension == ReportFilterDimension.shift)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text('Select shift'),
                value: controller.selectedShiftId,
                items: controller.shifts
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: controller.setFilterValue,
              ),
            ),
          ),
        if (controller.dimension == ReportFilterDimension.status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text('Select status'),
                value: controller.selectedStatus?.wireValue,
                items: AttendanceStatus.values
                    .map((s) => DropdownMenuItem(value: s.wireValue, child: Text(s.wireValue)))
                    .toList(),
                onChanged: controller.setFilterValue,
              ),
            ),
          ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
