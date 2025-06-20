import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FileExplorer(),
    );
  }
}

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  _FileExplorerState createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  List<FileSystemEntity> files = [];
  String folderPath = "";
  String? mp3FilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Permission denied");
      openAppSettings();
    }
  }

  Future<void> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        folderPath = selectedDirectory;
        files = Directory(folderPath).listSync();
      });
    }
  }

  Future<void> pickMP3File() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      setState(() {
        mp3FilePath = result.files.single.path;
      });
      print("Selected MP3 File: $mp3FilePath");
    }
  }

  Future<void> playMP3() async {
    if (mp3FilePath != null) {
      await _audioPlayer.play(DeviceFileSource(mp3FilePath!));
    } else {
      print("No file selected");
    }
  }

  Future<void> stopMP3() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("File Explorer & MP3 Player")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickFolder,
            child: Text("Select Folder"),
          ),
          SizedBox(height: 10),
          Text(folderPath, style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(files[index] is Directory
                      ? Icons.folder
                      : Icons.insert_drive_file),
                  title: Text(files[index].path.split('/').last),
                );
              },
            ),
          ),
          Divider(),
          Text("MP3 Player",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: pickMP3File,
            child: Text("Select MP3 File"),
          ),
          if (mp3FilePath != null)
            Text("Selected: ${mp3FilePath!.split('/').last}"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: playMP3,
                child: Text("Play"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: stopMP3,
                child: Text("Stop"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
