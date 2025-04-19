import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_box/widgets/input_field.dart';

class AddBoxForm extends StatefulWidget {
  final String userId; // Pass userId from the calling screen

  const AddBoxForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddBoxForm> createState() => _AddBoxFormState();
}

class _AddBoxFormState extends State<AddBoxForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitBox() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {

    print("Box added");

    if (mounted) {
      // Directly pop without delay
      // Navigator.of(context).pop(newBox);
    }
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}'))
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(backgroundColor: Colors.white,title: Text(
                'Add a box!',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Popins',
                ),
              ),),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              SizedBox(height: 16),
              CustomTextField(
                labelText: "Name",
                controller: _nameController,
               
              ),
              SizedBox(height: 16),
              CustomTextField(
                labelText: "Description",
                controller: _descriptionController,
               
              ),
              SizedBox(height:16),
              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                  children: [
                                    const TextSpan(text: "Or Use "),
                                    TextSpan(
                                      text: "QR Code!",
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()..onTap = () {},
                                    ),
                                  ],
                                ),
                              ),
              Spacer(),
              Container(
                margin: EdgeInsets.only(bottom: 16),
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBox,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        )
                      : Text(
                          "Add",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
