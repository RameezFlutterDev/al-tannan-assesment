import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/reports_controller.dart';
import 'attendance_day_detail_dialog.dart';
import 'filter_bar.dart';
import 'status_chip.dart';

class DailyReportTab extends StatefulWidget {
  const DailyReportTab({super.key});

  @override
  State<DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<DailyReportTab> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReportsController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: FilterBar(controller: controller),
                ),
              ),
            ),
            Expanded(
              child: controller.isLoadingRows
                  ? const Center(child: CircularProgressIndicator())
                  : controller.rowsError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626), size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'Could not load the report:\n${controller.rowsError}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : controller.rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_busy_rounded,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No attendance records found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Try selecting a different date range or filter',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            // Vertical scroll (default, outer) handles many
                            // rows; horizontal scroll (inner) handles many
                            // columns — that nesting order matters, the
                            // reverse gives the inner view unbounded width
                            // and crashes. The explicit controller + visible
                            // Scrollbar thumb is what actually fixes the
                            // "cut off on the right" complaint: without it
                            // the extra columns were reachable by scroll
                            // gesture but gave no visual sign they existed.
                            child: SingleChildScrollView(
                              child: Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor:
                                        WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                      fontSize: 13,
                                    ),
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 52,
                                    columns: const [
                                      DataColumn(label: Text('Employee')),
                                      DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Check In')),
                                      DataColumn(label: Text('Break Out')),
                                      DataColumn(label: Text('Break In')),
                                      DataColumn(label: Text('Check Out')),
                                      DataColumn(label: Text('Late (m)')),
                                      DataColumn(label: Text('Break (m)')),
                                      DataColumn(label: Text('Gross (m)')),
                                      DataColumn(label: Text('Net (m)')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Detail')),
                                    ],
                                    rows: controller.rows.map((day) {
                                      final employee = controller.employeeById(day.employeeId);
                                      final firstBreak =
                                          day.breaks.isNotEmpty ? day.breaks.first : null;
                                      return DataRow(cells: [
                                        DataCell(Text(
                                          employee?.name ?? day.employeeId,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        )),
                                        DataCell(Text(_formatDate(day.date))),
                                        DataCell(Text(_formatTime(day.checkIn?.time))),
                                        DataCell(Text(_formatTime(firstBreak?.breakOut.time))),
                                        DataCell(Text(_formatTime(firstBreak?.breakIn?.time))),
                                        DataCell(Text(_formatTime(day.checkOut?.time))),
                                        DataCell(Text('${day.lateMinutes}')),
                                        DataCell(Text('${day.breakDurationMinutes}')),
                                        DataCell(Text('${day.grossPresenceMinutes ?? '-'}')),
                                        DataCell(Text('${day.netWorkMinutes ?? '-'}')),
                                        DataCell(AttendanceStatusChip(status: day.status)),
                                        DataCell(IconButton(
                                          icon: const Icon(Icons.info_outline_rounded,
                                              color: Color(0xFF4F46E5)),
                                          tooltip: 'View coordinates & integrity',
                                          onPressed: () => showDialog(
                                            context: context,
                                            builder: (_) => AttendanceDayDetailDialog(
                                              eventsStream: controller.eventsFor(day),
                                            ),
                                          ),
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
