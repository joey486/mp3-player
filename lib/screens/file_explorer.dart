import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mp3player/screens/file_explorer_ui.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  FileExplorerState createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  List<FileSystemEntity> files = [];
  String folderPath = "";
  String? mp3FilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
    setupAudioPlayer();
  }

  Future<void> checkPermissions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? hasAskedBefore = prefs.getBool('permissions_asked');

    if (hasAskedBefore == null || !hasAskedBefore) {
      await prefs.setBool('permissions_asked', true);
    }

    setState(() {
      permissionsGranted = true;
    });
    debugPrint("✓ File access ready");
  }

  Future<void> pickFolder() async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          folderPath = selectedDirectory;
          files = Directory(folderPath).listSync().where((file) {
            return file.path.toLowerCase().endsWith('.mp3') ||
                file is Directory;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error selecting folder: $e");
      showPermissionDialog();
    }
  }

  Future<void> pickMP3File() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3'],
      );

      if (result != null) {
        setState(() {
          mp3FilePath = result.files.single.path;
        });
        debugPrint("♪ Selected MP3 File: $mp3FilePath");
      }
    } catch (e) {
      debugPrint("Error selecting MP3 file: $e");
      showPermissionDialog();
    }
  }

  Future<void> playMP3() async {
    if (mp3FilePath != null) {
      await _audioPlayer.play(DeviceFileSource(mp3FilePath!));
    } else {
      debugPrint("✗ No file selected");
    }
  }

  Future<void> pauseMP3() async => _audioPlayer.pause();
  Future<void> stopMP3() async {
    await _audioPlayer.stop();
    setState(() => currentPosition = Duration.zero);
  }

  Future<void> seekTo(Duration position) async => _audioPlayer.seek(position);

  void onFileSelect(FileSystemEntity file) {
    if (file is Directory) {
      setState(() {
        folderPath = file.path;
        files = Directory(folderPath).listSync().where((f) {
          return f.path.toLowerCase().endsWith('.mp3') || f is Directory;
        }).toList();
      });
    } else if (file.path.toLowerCase().endsWith('.mp3')) {
      setState(() => mp3FilePath = file.path);
    }
  }

  void setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen(
      (state) => setState(() => isPlaying = state == PlayerState.playing),
    );
    _audioPlayer.onPositionChanged.listen(
      (pos) => setState(() => currentPosition = pos),
    );
    _audioPlayer.onDurationChanged.listen(
      (dur) => setState(() => totalDuration = dur),
    );
  }

  void showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        title: const Text('File Access',
            style: TextStyle(color: Color(0xFFE6EDF3))),
        content: const Text(
          'This app uses file picker to access MP3 files. File access is handled automatically when you select files.',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF58A6FF))),
          ),
        ],
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildFileExplorerUI(this, context);
  }
}
