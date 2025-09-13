
import 'dart:io';
import 'dart:typed_data';

import 'package:chatwoot_sdk/chatwoot_sdk.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
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
    
    final result = await _handleFileSelection();
    print('File selection result: $result');
    
    // Show result to user for debugging
    if (result != null) {
      print('Successfully selected file: ${result.name}, size: ${result.bytes.length}');
    } else {
      print('No file selected or selection failed');
    }
    
    return result;
  }


  Future<FileAttachment?> _handleFileSelection() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          return FileAttachment(
            bytes: Uint8List.fromList(bytes), 
            name: file.name, 
            path: file.path!
          );
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }

    return null;
  }

}
