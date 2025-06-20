import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Terminal MP3 Player',
      theme: ThemeData(
        // Linux terminal-inspired dark theme
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFF0D1117),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          foregroundColor: Color(0xFF58A6FF),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF21262D),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF238636),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Color(0xFF58A6FF),
          textColor: Color(0xFFE6EDF3),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFFE6EDF3),
            fontFamily: 'Courier',
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFE6EDF3),
            fontFamily: 'Courier',
          ),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF58A6FF),
        ),
      ),
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hasAskedBefore = prefs.getBool('permissions_asked');

    if (hasAskedBefore == null || !hasAskedBefore) {
      // First time, mark as asked and grant permissions (handled by file_picker)
      await prefs.setBool('permissions_asked', true);
    }

    // For modern Android, file_picker handles permissions automatically
    setState(() {
      permissionsGranted = true;
    });
    print("✓ File access ready");
  }

  Future<void> requestPermissions() async {
    // Modern file_picker handles permissions automatically
    setState(() {
      permissionsGranted = true;
    });
    print("✓ File access ready");
  }

  void showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF21262D),
        title: Text('File Access', style: TextStyle(color: Color(0xFFE6EDF3))),
        content: Text(
          'This app uses file picker to access MP3 files. File access is handled automatically when you select files.',
          style: TextStyle(color: Color(0xFFE6EDF3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Color(0xFF58A6FF))),
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
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

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
      print("Error selecting folder: $e");
      showPermissionDialog();
    }
  }

  Future<void> pickMP3File() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3'],
      );

      if (result != null) {
        setState(() {
          mp3FilePath = result.files.single.path;
        });
        print("♪ Selected MP3 File: $mp3FilePath");
      }
    } catch (e) {
      print("Error selecting MP3 file: $e");
      showPermissionDialog();
    }
  }

  Future<void> playMP3() async {
    if (mp3FilePath != null) {
      await _audioPlayer.play(DeviceFileSource(mp3FilePath!));
    } else {
      print("✗ No file selected");
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
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
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
        title: Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFF58A6FF)),
            SizedBox(width: 8),
            Text("Terminal MP3 Player",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        backgroundColor: Color(0xFF161B22),
      ),
      body: Column(
        children: [
          // Header section with controls
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF21262D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_open, color: Color(0xFF58A6FF)),
                    SizedBox(width: 8),
                    Text("Directory Browser",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6EDF3),
                        )),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: pickFolder,
                  icon: Icon(Icons.folder_open, size: 18),
                  label: Text("Browse Directory"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF238636),
                  ),
                ),
                if (folderPath.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFF30363D)),
                    ),
                    child: Text(
                      "pwd: $folderPath",
                      style: TextStyle(
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
              color: Color(0xFF0D1117),
              child: files.isEmpty
                  ? Center(
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
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: mp3FilePath == file.path
                                ? Color(0xFF238636).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isDirectory ? Icons.folder : Icons.music_note,
                              color: isDirectory
                                  ? Color(0xFF58A6FF)
                                  : Color(0xFF7C3AED),
                            ),
                            title: Text(
                              fileName,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14,
                                color: Color(0xFFE6EDF3),
                              ),
                            ),
                            subtitle: isDirectory
                                ? Text("directory",
                                    style: TextStyle(
                                      color: Color(0xFF7D8590),
                                      fontSize: 12,
                                    ))
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF21262D),
              border: Border(
                top: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                SizedBox(height: 8),

                if (mp3FilePath != null) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFF30363D)),
                    ),
                    child: Text(
                      "♪ ${mp3FilePath!.split('/').last}",
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Progress bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Color(0xFF238636),
                          inactiveTrackColor: Color(0xFF30363D),
                          thumbColor: Color(0xFF238636),
                          overlayColor: Color(0xFF238636).withAlpha(32),
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
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(currentPosition),
                              style: TextStyle(
                                color: Color(0xFF7D8590),
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              formatDuration(totalDuration),
                              style: TextStyle(
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

                SizedBox(height: 16),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickMP3File,
                      icon: Icon(Icons.file_open, size: 18),
                      label: Text("Open"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0969DA),
                      ),
                    ),
                    SizedBox(width: 12),
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
                        backgroundColor: Color(0xFF238636),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: mp3FilePath != null ? stopMP3 : null,
                      icon: Icon(Icons.stop, size: 18),
                      label: Text("Stop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDA3633),
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
