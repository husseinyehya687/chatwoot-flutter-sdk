
import 'dart:io';
import 'dart:typed_data';

import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  _showDialog(){
    ChatwootChatDialog.show(
      context,
      title: "Customer Support",
      inboxIdentifier: "your-api-inbox-identifier",
      userIdentityValidationKey: "your-hmac-user-validation-key",
      baseUrl: "https://app.chatwoot.com",
      user: ChatwootUser(
        identifier: "test@test.com",
        name: "Tester test",
        email: "test@test.com",
      ),
      primaryColor: const Color(0xff258596),
      onAttachmentPressed: _handleAttachmentPressed,
      openFile: _handleOpenFile,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chatwoot Example"),
        actions: [
          IconButton(onPressed: _showDialog, icon: Icon(Icons.copy))
        ],
      ),
      body: ChatwootChat(

        inboxIdentifier: "your-api-inbox-identifier",
        userIdentityValidationKey: "your-hmac-user-validation-key",
        baseUrl: "https://app.chatwoot.com",
        user: ChatwootUser(
          identifier: "test@test.com",
          name: "Tester test",
          email: "test@test.com",
        ),
        theme: ChatwootChatTheme(
          primaryColor: const Color(0xff258596)
        ),
        onAttachmentPressed: _handleAttachmentPressed,
        openFile: _handleOpenFile,
      ),
    );
  }

  Future<void> _handleOpenFile(String filePath) async{
    await OpenFilex.open(filePath);
  }

  Future<FileAttachment?> _handleAttachmentPressed() async{
    print('_handleAttachmentPressed in main_client called');
    return await _handleFileSelection();
  }


  Future<FileAttachment?> _handleFileSelection() async {
    try {
      print('Starting file picker...');
      
      // Try different file picker configurations as fallback
      FilePickerResult? result;
      
      // First attempt: Standard configuration
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false, // Use file path instead of loading data into memory
        withReadStream: false,
        allowCompression: true,
      );

      print('FilePicker result (first attempt): $result');
      
      // If first attempt failed, try with custom file types
      if (result == null) {
        print('First attempt failed, trying with custom types...');
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'gif', 'mp4', 'mp3', 'wav'],
          allowMultiple: false,
          withData: false,
          withReadStream: false,
        );
        print('FilePicker result (custom types): $result');
      }
      
      // If still null, try media only
      if (result == null) {
        print('Custom types failed, trying media only...');
        result = await FilePicker.platform.pickFiles(
          type: FileType.media,
          allowMultiple: false,
          withData: false,
          withReadStream: false,
        );
        print('FilePicker result (media only): $result');
      }
      
      if (result == null) {
        print('All file picker attempts failed - user canceled or no access');
        return null;
      }
      
      if (result.files.isEmpty) {
        print('No files selected');
        return null;
      }
      
      final file = result.files.first;
      print('Selected file: ${file.name}, size: ${file.size}, path: ${file.path}');
      print('File extension: ${file.extension}');
      print('File bytes available: ${file.bytes != null}');
      
      // Validate file
      if (file.name.isEmpty) {
        print('Error: File name is empty');
        return null;
      }
      
      // Try to get file bytes
      Uint8List? bytes;
      
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        // Use bytes directly if available
        print('Using file bytes directly (${file.bytes!.length} bytes)');
        bytes = file.bytes!;
      } else if (file.path != null && file.path!.isNotEmpty) {
        // Read from file path
        print('Reading file from path: ${file.path}');
        try {
          final fileObj = File(file.path!);
          if (await fileObj.exists()) {
            final fileBytes = await fileObj.readAsBytes();
            bytes = Uint8List.fromList(fileBytes);
            print('Read ${bytes.length} bytes from file');
          } else {
            print('Error: File does not exist at path: ${file.path}');
            return null;
          }
        } catch (pathError) {
          print('Error reading file from path: $pathError');
          return null;
        }
      } else {
        print('Error: Both bytes and path are null or empty');
        print('File bytes: ${file.bytes}');
        print('File path: ${file.path}');
        return null;
      }
      
      final attachment = FileAttachment(
        bytes: bytes, 
        name: file.name, 
        path: file.path ?? file.name
      );
      
      print('Successfully created FileAttachment: ${attachment.name} (${attachment.bytes.length} bytes)');
      return attachment;
      
    } catch (e) {
      print('Error picking file: $e');
      print('Stack trace: ${StackTrace.current}');
    }

    return null;
  }

}
