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
  bool _showOnlyAvailable = true;

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

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      default:
        return 'الأحد';
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  Future<Map<String, String>> _resolvePatientProfile(User user) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = user.uid;
    final DocumentReference<Map<String, dynamic>> patientRef = firestore
        .collection('patients')
        .doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await patientRef
        .get();

    if (snapshot.exists) {
      final Map<String, dynamic> data = snapshot.data() ?? {};
      return {
        'id': uid,
        'name': (data['name'] ?? 'مريض').toString(),
        'phone': (data['phone'] ?? 'غير متوفر').toString(),
      };
    }

    final String fallbackName = (user.email ?? 'مريض').split('@').first;
    await patientRef.set({
      'uid': uid,
      'name': fallbackName,
      'email': user.email ?? '',
      'phone': 'غير متوفر',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return {'id': uid, 'name': fallbackName, 'phone': 'غير متوفر'};
  }

  Future<void> _pickOtherDate() async {
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: todayDateOnly,
      lastDate: todayDateOnly.add(const Duration(days: 90)),
      helpText: 'اختر تاريخ الحجز',
    );

    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedTime = null;
    });
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

    Map<String, String> patientProfile;
    try {
      patientProfile = await _resolvePatientProfile(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحميل بيانات المريض')));
      return;
    }

    final String patientId = patientProfile['id'] ?? user.uid;
    final String patientName = patientProfile['name'] ?? 'مريض';
    final String patientPhone = patientProfile['phone'] ?? 'غير متوفر';

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
          'patientId': patientId,
          'patientName': patientName,
          'patientPhone': patientPhone,
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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    final String selectedDateKey = _dateKey(_selectedDate);
    final List<DateTime> quickDates = List<DateTime>.generate(
      7,
      (index) => todayDateOnly.add(Duration(days: index)),
    );

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
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: quickDates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final DateTime date = quickDates[index];
                              final bool selected = _isSameDate(
                                date,
                                _selectedDate,
                              );
                              return ChoiceChip(
                                selected: selected,
                                label: Text(
                                  '${_weekdayLabel(date)}\n${date.day}/${date.month}',
                                  textAlign: TextAlign.center,
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedDate = date;
                                    _selectedTime = null;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _pickOtherDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('اختيار تاريخ آخر'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'أوقات ${_formatDate(_selectedDate)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('المتاحة فقط'),
                      selected: _showOnlyAvailable,
                      onSelected: (value) {
                        setState(() {
                          _showOnlyAvailable = value;
                        });
                      },
                    ),
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

                      final List<String> visibleSlots = slots.where((slot) {
                        if (!_showOnlyAvailable) return true;
                        final bool isBooked = bookedTimes.contains(slot);
                        final bool isPast = _isPastSlot(_selectedDate, slot);
                        return !isBooked && !isPast;
                      }).toList();

                      if (visibleSlots.isEmpty) {
                        return const Center(
                          child: Text('لا توجد أوقات متاحة في هذا اليوم'),
                        );
                      }

                      return ListView.separated(
                        itemCount: visibleSlots.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final String slot = visibleSlots[index];
                          final bool isBooked = bookedTimes.contains(slot);
                          final bool isPast = _isPastSlot(_selectedDate, slot);
                          final bool isUnavailable = isBooked || isPast;
                          final bool isSelected = _selectedTime == slot;

                          final ColorScheme colors = Theme.of(
                            context,
                          ).colorScheme;
                          final Color borderColor = isSelected
                              ? colors.primary
                              : isUnavailable
                              ? Colors.grey.shade300
                              : colors.outlineVariant;
                          final Color tileColor = isSelected
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.white;
                          final String statusText = isBooked
                              ? 'محجوز'
                              : isPast
                              ? 'انتهى'
                              : 'متاح';
                          final IconData statusIcon = isBooked
                              ? Icons.block_outlined
                              : isPast
                              ? Icons.history_toggle_off
                              : isSelected
                              ? Icons.check_circle
                              : Icons.schedule;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: isUnavailable
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTime = slot;
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: isUnavailable
                                        ? Colors.grey
                                        : isSelected
                                        ? colors.primary
                                        : colors.secondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isUnavailable
                                            ? Colors.grey
                                            : colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isUnavailable
                                          ? Colors.grey
                                          : isSelected
                                          ? colors.primary
                                          : colors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _selectedTime == null
                        ? 'اختر وقتًا مناسبًا للمتابعة'
                        : 'الوقت المحدد: $_selectedTime',
                    key: ValueKey<String>(_selectedTime ?? 'empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTime == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _isBooking
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _selectedTime == null
                            ? null
                            : () => _bookAppointment(
                                workingHoursStart: workingHoursStart,
                                workingHoursEnd: workingHoursEnd,
                                slotDurationMinutes: slotDurationMinutes,
                              ),
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
