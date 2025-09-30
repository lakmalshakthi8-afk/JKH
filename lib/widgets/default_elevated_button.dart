import 'package:flutter/material.dart';

class DefaultElevatedButton extends StatefulWidget {
  const DefaultElevatedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
  });
  final String title;
  final VoidCallback onPressed;
  final Icon? icon;
  @override
  State<DefaultElevatedButton> createState() => _DefaultElevatedButtonState();
}

class _DefaultElevatedButtonState extends State<DefaultElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.greenAccent,
          iconColor: Colors.white,
          side: BorderSide(
            color: Colors.white,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20.0,
            ),
          ),
        ),
        onPressed: widget.onPressed,
        icon: widget.icon,
        label: Text(
          widget.title,
        ));
  }
}
