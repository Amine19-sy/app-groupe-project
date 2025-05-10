import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? labelText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isCodeInput;
  final int? maxLines;
  // New callbacks
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const CustomTextField({
    Key? key,
    this.labelText,
    this.controller,
    this.isPassword = false,
    this.isCodeInput = false,
    this.maxLines,
    this.onChanged,
    this.onTap,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: widget.maxLines ?? 1,
      controller: widget.controller,
      focusNode: _focusNode,
      cursorColor: Colors.blue,
      obscureText: widget.isPassword ? _isObscured : false,
      keyboardType:
          widget.isCodeInput ? TextInputType.number : TextInputType.text,
      inputFormatters: widget.isCodeInput
          ? [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ]
          : null,
      textAlign: widget.isCodeInput ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: widget.isCodeInput ? 24 : 16,
        fontWeight: widget.isCodeInput ? FontWeight.bold : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        floatingLabelStyle: TextStyle(
          color: _isFocused ? Colors.blue : Colors.grey,
          fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _isFocused ? Colors.blue : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: widget.isPassword
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                child: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: _isFocused ? Colors.blue : Colors.grey,
                ),
              )
            : null,
      ),
      onTap: widget.onTap,
      onChanged: (value) {
        // Forward to external callback
        if (widget.onChanged != null) widget.onChanged!(value);
        // Existing code-input logic
        if (widget.isCodeInput && value.length == 1) {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }
}
