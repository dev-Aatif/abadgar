import 'package:flutter/material.dart';

class SharedAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String prefix;
  final String hint;
  final bool autofocus;

  const SharedAmountField({
    super.key,
    required this.controller,
    this.prefix = 'PKR',
    this.hint = '0.00',
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(prefix, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class SharedSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const SharedSaveButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
