import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'UserData.dart';

class UploadAdPage extends StatefulWidget {
  const UploadAdPage({Key? key}) : super(key: key);

  @override
  _UploadAdPageState createState() => _UploadAdPageState();
}

class _UploadAdPageState extends State<UploadAdPage> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.image);
    if (result != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    } else {
      // Handle user cancellation or error
    }
  }

  Future<void> uploadImage(String userId) async {
    if (_imageFile == null) return; // Handle no image selected

    final Uri url = Uri.parse('http://127.0.0.1:5000/upload'); // Replace with your backend URL
    var request = http.MultipartRequest('POST', url);

    // Add image and user ID data
    final imageMultipartFile = await http.MultipartFile.fromPath('image', _imageFile!.path);
    request.files.add(imageMultipartFile);
    request.fields['advertiser_id'] = userId;

    final response = await request.send();

    if (response.statusCode == 200) {
      // Upload successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
      setState(() {
        _imageFile = null; // Clear image selection after successful upload
      });
    } else {
      // Upload failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed! (Status code: ${response.statusCode})'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Ad'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              Image.file(_imageFile!, width: 200.0, height: 200.0), // Display selected image (optional)
            ElevatedButton(
              onPressed: () async {
                await _pickImage(); // Pick the image first
                final userData = Provider.of<UserData>(context, listen: false);
                final userId = userData.userId;
                String userIdString = userId!.toString();
                await uploadImage(userIdString); // Upload the image with retrieved user ID
              },
              child: const Text('Select File'),
            ),
          ],
        ),
      ),
    );
  }
}
