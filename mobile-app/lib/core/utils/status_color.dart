import 'package:flutter/material.dart';

Color statusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  final value = status.toLowerCase();
  if (value.contains('critical') || value.contains('offline') || value.contains('fail') || value.contains('emergency')) {
    return scheme.error;
  }
  if (value.contains('warning') || value.contains('low') || value.contains('stopped')) {
    return Colors.orange.shade700;
  }
  if (value.contains('unavailable')) {
    return Colors.grey;
  }
  return Colors.green.shade700;
}
