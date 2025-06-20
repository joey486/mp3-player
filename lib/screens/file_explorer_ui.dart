import 'dart:io';
import 'package:flutter/material.dart';
import 'file_explorer.dart';

Widget buildFileExplorerUI(FileExplorerState state, BuildContext context) {
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
        _buildDirectoryPicker(state),
        _buildFileList(state),
        _buildAudioPlayer(state),
      ],
    ),
  );
}

Widget _buildDirectoryPicker(FileExplorerState state) {
  return Container(
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
          onPressed: state.pickFolder,
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text("Browse Directory"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
          ),
        ),
        if (state.folderPath.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              "pwd: ${state.folderPath}",
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: Color(0xFF7D8590),
              ),
            ),
          ),
        ]
      ],
    ),
  );
}

Widget _buildFileList(FileExplorerState state) {
  return Expanded(
    flex: 2,
    child: Container(
      color: const Color(0xFF0D1117),
      child: state.files.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Color(0xFF30363D)),
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
              itemCount: state.files.length,
              itemBuilder: (context, index) {
                final file = state.files[index];
                final isDirectory = file is Directory;
                final fileName = file.path.split('/').last;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: state.mp3FilePath == file.path
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
                    onTap: () => state.onFileSelect(file),
                  ),
                );
              },
            ),
    ),
  );
}

Widget _buildAudioPlayer(FileExplorerState state) {
  return Container(
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
        if (state.mp3FilePath != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              "♪ ${state.mp3FilePath!.split('/').last}",
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(state.context).copyWith(
                  activeTrackColor: const Color(0xFF238636),
                  inactiveTrackColor: const Color(0xFF30363D),
                  thumbColor: const Color(0xFF238636),
                  overlayColor: const Color(0xFF238636).withAlpha(51),
                ),
                child: Slider(
                  value: state.currentPosition.inMilliseconds.toDouble(),
                  max: state.totalDuration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    state.seekTo(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.formatDuration(state.currentPosition),
                      style: const TextStyle(
                        color: Color(0xFF7D8590),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      state.formatDuration(state.totalDuration),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: state.pickMP3File,
              icon: const Icon(Icons.file_open, size: 18),
              label: const Text("Open"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0969DA),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: state.mp3FilePath != null
                  ? (state.isPlaying ? state.pauseMP3 : state.playMP3)
                  : null,
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 18,
              ),
              label: Text(state.isPlaying ? "Pause" : "Play"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: state.mp3FilePath != null ? state.stopMP3 : null,
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
  );
}
