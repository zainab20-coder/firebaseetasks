import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentBookingPage extends StatefulWidget {
  final String doctorId;

  const AppointmentBookingPage({super.key, required this.doctorId});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isBooking = false;

  String _dateKey(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  int _toMinutes(String hhmm) {
    final List<String> parts = hhmm.split(':');
    if (parts.length != 2) {
      throw const FormatException('INVALID_TIME');
    }
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('INVALID_TIME');
    }
    return hour * 60 + minute;
  }

  String _minutesToTime(int totalMinutes) {
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  List<String> _generateSlots({
    required String start,
    required String end,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0) return const <String>[];

    final int startMinutes = _toMinutes(start);
    final int endMinutes = _toMinutes(end);
    if (endMinutes <= startMinutes) return const <String>[];

    final List<String> slots = <String>[];
    for (
      int minutes = startMinutes;
      minutes + durationMinutes <= endMinutes;
      minutes += durationMinutes
    ) {
      slots.add(_minutesToTime(minutes));
    }
    return slots;
  }

  DateTime _combineDateAndTime(DateTime date, String hhmm) {
    final int minutes = _toMinutes(hhmm);
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isPastSlot(DateTime date, String hhmm) {
    final DateTime slotDateTime = _combineDateAndTime(date, hhmm);
    return slotDateTime.isBefore(DateTime.now());
  }

  int _readDuration(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 30;
  }

  Future<void> _bookAppointment({
    required String workingHoursStart,
    required String workingHoursEnd,
    required int slotDurationMinutes,
  }) async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار وقت الموعد')));
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    final DateTime normalizedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final DateTime appointmentDateTime = _combineDateAndTime(
      normalizedDate,
      _selectedTime!,
    );
    if (appointmentDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حجز وقت في الماضي')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final String dateKey = _dateKey(normalizedDate);
    final String appointmentId =
        '${widget.doctorId}_${dateKey}_${_selectedTime!.replaceAll(':', '')}';
    final DocumentReference<Map<String, dynamic>> appointmentRef =
        FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId);
    final DocumentReference<Map<String, dynamic>> doctorRef = FirebaseFirestore
        .instance
        .collection('doctors')
        .doc(widget.doctorId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> doctorSnapshot =
            await transaction.get(doctorRef);
        if (!doctorSnapshot.exists) {
          throw StateError('DOCTOR_NOT_FOUND');
        }

        final Map<String, dynamic> doctorData = doctorSnapshot.data()!;
        final String dbStart =
            (doctorData['workingHoursStart'] ?? workingHoursStart).toString();
        final String dbEnd = (doctorData['workingHoursEnd'] ?? workingHoursEnd)
            .toString();
        final int dbDuration = _readDuration(
          doctorData['slotDurationMinutes'] ?? slotDurationMinutes,
        );

        final List<String> allowedSlots = _generateSlots(
          start: dbStart,
          end: dbEnd,
          durationMinutes: dbDuration,
        );
        if (!allowedSlots.contains(_selectedTime)) {
          throw StateError('OUTSIDE_WORKING_HOURS');
        }

        final DocumentSnapshot<Map<String, dynamic>> existing =
            await transaction.get(appointmentRef);
        if (existing.exists) {
          throw StateError('BOOKED');
        }

        transaction.set(appointmentRef, {
          'doctorId': widget.doctorId,
          'patientId': user.uid,
          'date': Timestamp.fromDate(appointmentDateTime),
          'dateKey': dateKey,
          'time': _selectedTime,
          'status': 'upcoming',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حجز الموعد بنجاح')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final String error = e.toString();
      String message = 'تعذر إتمام الحجز، حاول مرة أخرى';

      if (error.contains('BOOKED')) {
        message = 'هذا الوقت محجوز بالفعل، اختر وقتًا آخر';
      } else if (error.contains('OUTSIDE_WORKING_HOURS')) {
        message = 'هذا الوقت خارج ساعات عمل الطبيب';
      } else if (error.contains('DOCTOR_NOT_FOUND')) {
        message = 'بيانات الطبيب غير متاحة';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool outlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    final String selectedDateKey = _dateKey(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('حجز موعد')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .snapshots(),
        builder: (context, doctorSnapshot) {
          if (!doctorSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!doctorSnapshot.data!.exists) {
            return const Center(child: Text('بيانات الطبيب غير متاحة'));
          }

          final Map<String, dynamic> doctor = doctorSnapshot.data!.data()!;
          final String doctorName = (doctor['name'] ?? 'طبيب').toString();
          final String workingHoursStart =
              (doctor['workingHoursStart'] ?? '09:00').toString();
          final String workingHoursEnd = (doctor['workingHoursEnd'] ?? '17:00')
              .toString();
          final int slotDurationMinutes = _readDuration(
            doctor['slotDurationMinutes'],
          );

          final List<String> slots = _generateSlots(
            start: workingHoursStart,
            end: workingHoursEnd,
            durationMinutes: slotDurationMinutes,
          );
          if (slots.isEmpty) {
            return const Center(
              child: Text('لا توجد ساعات عمل صالحة لهذا الطبيب'),
            );
          }

          final bool hasSelection = _selectedTime != null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'د. $doctorName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ساعات العمل: $workingHoursStart - $workingHoursEnd',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: todayDateOnly,
                          lastDate: todayDateOnly.add(const Duration(days: 90)),
                          onDateChanged: (DateTime newDate) {
                            setState(() {
                              _selectedDate = newDate;
                              _selectedTime = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اختر وقت الحجز ليوم ${_formatDate(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'محدد',
                    ),
                    _buildLegendItem(
                      color: Colors.green,
                      label: 'متاح',
                      outlined: true,
                    ),
                    _buildLegendItem(color: Colors.grey, label: 'غير متاح'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('doctorId', isEqualTo: widget.doctorId)
                        .where('dateKey', isEqualTo: selectedDateKey)
                        .snapshots(),
                    builder: (context, appointmentsSnapshot) {
                      if (!appointmentsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final Set<String> bookedTimes = appointmentsSnapshot
                          .data!
                          .docs
                          .map((doc) => (doc.data()['time'] ?? '').toString())
                          .where((time) => time.isNotEmpty)
                          .toSet();

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.2,
                            ),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final String slot = slots[index];
                          final bool isBooked = bookedTimes.contains(slot);
                          final bool isPast = _isPastSlot(_selectedDate, slot);
                          final bool isUnavailable = isBooked || isPast;
                          final bool isSelected = _selectedTime == slot;

                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            onSelected: isUnavailable
                                ? null
                                : (_) {
                                    setState(() {
                                      _selectedTime = slot;
                                    });
                                  },
                            labelStyle: TextStyle(
                              color: isUnavailable
                                  ? Colors.grey
                                  : isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color: isUnavailable
                                  ? Colors.grey.shade400
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSelection
                      ? 'الوقت المحدد: $_selectedTime'
                      : 'لم يتم اختيار وقت بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasSelection
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _isBooking
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: hasSelection
                            ? () => _bookAppointment(
                                workingHoursStart: workingHoursStart,
                                workingHoursEnd: workingHoursEnd,
                                slotDurationMinutes: slotDurationMinutes,
                              )
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('تأكيد الحجز'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
