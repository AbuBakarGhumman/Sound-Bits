import 'package:flutter/material.dart';
import '../../Constants/app_constants.dart';
import '../Components/splash_title.dart';

class MDrivePage extends StatelessWidget {
  const MDrivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> driveFiles = [
      {
        'name': 'Top Hits 2024.mp3',
        'size': '5.2 MB',
        'icon': Icons.music_note_rounded,
      },
      {
        'name': 'Chill Mix.mp3',
        'size': '3.8 MB',
        'icon': Icons.music_note_rounded,
      },
      {
        'name': 'Workout Energy.mp3',
        'size': '6.1 MB',
        'icon': Icons.music_note_rounded,
      },
      {
        'name': 'Relax Beats.mp3',
        'size': '4.5 MB',
        'icon': Icons.music_note_rounded,
      },
    ];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            /// ☁️ Header Row (Title + Sync Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SplashTitle("Drive", screenWidth * 0.07),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      // TODO: Handle cloud sync
                    },
                    child: Icon(
                      Icons.sync_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: screenWidth * 0.06,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// 📊 Drive Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Usage',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: screenWidth * 0.55, // 55% used storage
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8512B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Used: 2.7 GB',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        'Total: 5 GB',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🎶 Drive Files List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: driveFiles.length,
                itemBuilder: (context, index) {
                  final file = driveFiles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          file['icon'] as IconData,
                          size: 26,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      title: Text(
                        file['name'] as String,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        file['size'] as String,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                      trailing: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onTap: () {
                        // TODO: Open file or show options
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
