import 'package:flutter/material.dart';

class OutputFileNameField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final String hintText;

  const OutputFileNameField({
    super.key,
    required this.controller,
    required this.accentColor,
    this.hintText = 'e.g. MyDocument',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: 'Enter output File Name',
          labelStyle: TextStyle(color: accentColor.withValues(alpha: 0.7)),
          floatingLabelStyle: TextStyle(color: accentColor),
          prefixIcon: Icon(Icons.edit_note_rounded, color: accentColor),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '.pdf',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(),
          filled: true,
          fillColor: isDark ? Colors.black : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
