import 'dart:io';
import 'package:flutter/material.dart';
import 'file_explorer.dart';

Widget buildFileExplorerUI(FileExplorerState state, BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0F1115),
    appBar: AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 2,
      title: const Row(
        children: [
          Icon(Icons.terminal, color: Color(0xFF58A6FF)),
          SizedBox(width: 8),
          Text(
            "Terminal MP3 Player",
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              color: Color(0xFFE6EDF3),
              fontSize: 18,
            ),
          ),
        ],
      ),
    ),
    body: Column(
      children: [
        _buildDirectoryPicker(state),
        _buildAudioPlayer(state),
        _buildFileList(state),
      ],
    ),
  );
}

Widget _buildDirectoryPicker(FileExplorerState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Color(0xFF1C2128),
      border: Border(
        bottom: BorderSide(color: Color(0xFF30363D)),
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
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: state.pickFolder,
              icon: const Icon(Icons.folder, size: 18),
              label: const Text("Browse"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        if (state.folderPath.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              border: Border.all(color: const Color(0xFF30363D)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "📁 ${state.folderPath}",
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: Color(0xFF8B949E),
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
                  Icon(Icons.folder_off, size: 64, color: Color(0xFF30363D)),
                  SizedBox(height: 16),
                  Text(
                    "No directory selected",
                    style: TextStyle(
                      color: Color(0xFF7D8590),
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
            //
          : ListView.separated(
              itemCount: state.files.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Color(0xFF21262D)),
              itemBuilder: (context, index) {
                final file = state.files[index];
                final isDirectory = file is Directory;
                final fileName = file.path.split('/').last;
                final isSelected = state.mp3FilePath == file.path;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  tileColor: isSelected
                      ? const Color(0xFF238636).withOpacity(0.1)
                      : Colors.transparent,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onTap: () => state.onFileSelect(file),
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
      color: Color(0xFF1C2128),
      border: Border(
        top: BorderSide(color: Color(0xFF30363D)),
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
        const SizedBox(height: 10),
        if (state.mp3FilePath != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              "🎵 ${state.mp3FilePath!.split('/').last}",
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(state.context).copyWith(
              activeTrackColor: const Color(0xFF238636),
              inactiveTrackColor: const Color(0xFF30363D),
              thumbColor: const Color(0xFF238636),
              overlayColor: const Color(0xFF238636).withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: state.currentPosition.inMilliseconds.toDouble(),
              max: state.totalDuration.inMilliseconds.toDouble(),
              onChanged: (value) {
                state.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Row(
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
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlButton(
              label: "Open",
              icon: Icons.file_open,
              onPressed: state.pickMP3File,
              color: const Color(0xFF0969DA),
            ),
            const SizedBox(width: 12),
            _controlButton(
              label: state.isPlaying ? "Pause" : "Play",
              icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
              onPressed: state.mp3FilePath != null
                  ? (state.isPlaying ? state.pauseMP3 : state.playMP3)
                  : null,
              color: const Color(0xFF238636),
            ),
            const SizedBox(width: 12),
            _controlButton(
              label: "Stop",
              icon: Icons.stop,
              onPressed: state.mp3FilePath != null ? state.stopMP3 : null,
              color: const Color(0xFFDA3633),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _controlButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  required Color color,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFF2D333B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
