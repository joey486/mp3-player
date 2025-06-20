import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Terminal MP3 Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          foregroundColor: Color(0xFF58A6FF),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF21262D),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF58A6FF),
          textColor: Color(0xFFE6EDF3),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFFE6EDF3),
            fontFamily: 'Courier',
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFE6EDF3),
            fontFamily: 'Courier',
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF58A6FF),
        ),
      ),
      home: const FileExplorer(),
    );
  }
}

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
      // First time, mark as asked and grant permissions (handled by file_picker)
      await prefs.setBool('permissions_asked', true);
    }

    setState(() {
      permissionsGranted = true;
    });
    debugPrint("✓ File access ready");
  }

  Future<void> requestPermissions() async {
    setState(() {
      permissionsGranted = true;
    });
    debugPrint("✓ File access ready");
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

  void setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
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

  Future<void> pauseMP3() async {
    await _audioPlayer.pause();
  }

  Future<void> stopMP3() async {
    await _audioPlayer.stop();
    setState(() {
      currentPosition = Duration.zero;
    });
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void onFileSelect(FileSystemEntity file) {
    if (file is Directory) {
      setState(() {
        folderPath = file.path;
        files = Directory(folderPath).listSync().where((f) {
          return f.path.toLowerCase().endsWith('.mp3') || f is Directory;
        }).toList();
      });
    } else if (file.path.toLowerCase().endsWith('.mp3')) {
      setState(() {
        mp3FilePath = file.path;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFF58A6FF)),
            SizedBox(width: 8),
            Text(
              "Terminal MP3 Player",
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: Column(
        children: [
          // Header section with controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF21262D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_open, color: Color(0xFF58A6FF)),
                    SizedBox(width: 8),
                    Text(
                      "Directory Browser",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6EDF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: pickFolder,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text("Browse Directory"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                  ),
                ),
                if (folderPath.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Text(
                      "pwd: $folderPath",
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF7D8590),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // File list
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0D1117),
              child: files.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 64, color: Color(0xFF30363D)),
                          SizedBox(height: 16),
                          Text(
                            "No directory selected",
                            style: TextStyle(
                              color: Color(0xFF7D8590),
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final isDirectory = file is Directory;
                        final fileName = file.path.split('/').last;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: mp3FilePath == file.path
                                ? const Color(0xFF238636).withAlpha(51)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isDirectory ? Icons.folder : Icons.music_note,
                              color: isDirectory
                                  ? const Color(0xFF58A6FF)
                                  : const Color(0xFF7C3AED),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14,
                                color: Color(0xFFE6EDF3),
                              ),
                            ),
                            subtitle: isDirectory
                                ? const Text(
                                    "directory",
                                    style: TextStyle(
                                      color: Color(0xFF7D8590),
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            onTap: () => onFileSelect(file),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // MP3 Player section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF21262D),
              border: Border(
                top: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text(
                      "Audio Player",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6EDF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (mp3FilePath != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Text(
                      "♪ ${mp3FilePath!.split('/').last}",
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF238636),
                          inactiveTrackColor: const Color(0xFF30363D),
                          thumbColor: const Color(0xFF238636),
                          overlayColor: const Color(0xFF238636).withAlpha(51),
                        ),
                        child: Slider(
                          value: currentPosition.inMilliseconds.toDouble(),
                          max: totalDuration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            seekTo(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(currentPosition),
                              style: const TextStyle(
                                color: Color(0xFF7D8590),
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              formatDuration(totalDuration),
                              style: const TextStyle(
                                color: Color(0xFF7D8590),
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickMP3File,
                      icon: const Icon(Icons.file_open, size: 18),
                      label: const Text("Open"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0969DA),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: mp3FilePath != null
                          ? (isPlaying ? pauseMP3 : playMP3)
                          : null,
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(isPlaying ? "Pause" : "Play"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF238636),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: mp3FilePath != null ? stopMP3 : null,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text("Stop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDA3633),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
