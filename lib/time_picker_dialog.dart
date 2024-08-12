import 'package:flutter/material.dart';

Future<TimeOfDay?> showTimePickerDialog(BuildContext context) async {
  final TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },
  );

  return selectedTime;
}