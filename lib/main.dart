import 'package:flutter/material.dart';
import 'package:mp3player/screens/file_explorer.dart';
import 'package:mp3player/theme/app_theme.dart';

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
      theme: buildAppTheme(),
      home: const FileExplorer(),
    );
  }
}
