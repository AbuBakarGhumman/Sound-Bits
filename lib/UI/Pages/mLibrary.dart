import 'package:flutter/material.dart';
import '../../Constants/app_constants.dart';
import '../Components/album_item.dart';
import '../Components/folder_item.dart';
import '../Components/track_item.dart';
import '../Components/splash_title.dart';

class MLibraryPage extends StatefulWidget {
  final Map<String, dynamic>? currentlyPlayingSong;
  final bool isPlaying;
  final Function(Map<String, dynamic>) onTrackSelected;

  const MLibraryPage({
    super.key,
    required this.currentlyPlayingSong,
    required this.isPlaying,
    required this.onTrackSelected,
  });

  @override
  State<MLibraryPage> createState() => _MLibraryPageState();
}

class _MLibraryPageState extends State<MLibraryPage> {
  final ScrollController _scrollController = ScrollController();
  int selectedIndex = 1;

  final List<String> tabs = [
    'Favourites', 'Tracks', 'Albums', 'Artists', 'Folders',
  ];
  late final List<GlobalKey> _tabKeys;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(tabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerSelectedTab(selectedIndex);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollEnd() {
    final screenCenter = MediaQuery.of(context).size.width / 2;
    double minDistance = double.infinity;
    int closestTabIndex = selectedIndex;
    for (int i = 0; i < _tabKeys.length; i++) {
      final keyContext = _tabKeys[i].currentContext;
      if (keyContext != null) {
        final renderBox = keyContext.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final tabCenter = position.dx + renderBox.size.width / 2;
        final distance = (tabCenter - screenCenter).abs();
        if (distance < minDistance) {
          minDistance = distance;
          closestTabIndex = i;
        }
      }
    }
    if (selectedIndex != closestTabIndex) {
      setState(() {
        selectedIndex = closestTabIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerSelectedTab(closestTabIndex);
      });
    }
  }

  void _centerSelectedTab(int index) {
    _isAutoScrolling = true;
    final keyContext = _tabKeys[index].currentContext;
    if (keyContext == null) {
      _isAutoScrolling = false;
      return;
    }
    final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
    final itemWidth = renderBox.size.width;
    final itemPosition = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollOffset = _scrollController.offset;
    final targetOffset = itemPosition.dx - (screenWidth / 2) + (itemWidth / 2);
    final newScrollOffset = (scrollOffset + targetOffset)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      newScrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).whenComplete(() {
      _isAutoScrolling = false;
    });
  }

  Widget _buildContent(String sectionTitle, bool isDark) {
    switch (sectionTitle) {
      case 'Albums':
        return GridView.builder(
          key: const ValueKey('albums_grid'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
          itemCount: 20,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1 / 1.4,
          ),
          itemBuilder: (context, itemIndex) {
            return AlbumItem(
              albumTitle: 'Album Name ${itemIndex + 1}',
              artistName: 'Artist Name',
              isDark: isDark,
              onTap: () {},
            );
          },
        );
      case 'Folders':
        return ListView.builder(
          key: const ValueKey('folders_list'),
          padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
          itemCount: 20,
          itemBuilder: (context, itemIndex) {
            return FolderItem(
              folderName: 'Downloaded Music ${itemIndex + 1}',
              trackCount: (itemIndex + 3) * 5,
              isDark: isDark,
              onTap: () {},
            );
          },
        );
      case 'Tracks':
      case 'Favourites':
      case 'Artists':
      default:
        return ListView.builder(
          key: ValueKey('tracks_list_$sectionTitle'),
          padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
          itemCount: 20,
          itemBuilder: (context, itemIndex) {
            final songData = {
              'title': '$sectionTitle Song Title ${itemIndex + 1}',
              'artist': 'Artist Name',
            };
            final bool isSelected = widget.currentlyPlayingSong != null &&
                widget.currentlyPlayingSong!['title'] == songData['title'];
            return TrackItem(
              songTitle: songData['title']!,
              artistName: songData['artist']!,
              isDark: isDark,
              isSelected: isSelected,
              isPlaying: isSelected && widget.isPlaying,
              onTap: () {
                widget.onTrackSelected(songData);
              },
              onMoreTap: () {},
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SplashTitle("Library", screenWidth * 0.08),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {},
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: screenWidth * 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 45,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification && !_isAutoScrolling) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!_isAutoScrolling && mounted) _handleScrollEnd();
                  });
                }
                return true;
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth / 2 - 60),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return GestureDetector(
                    key: _tabKeys[index],
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                      _centerSelectedTab(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        child: Text(tabs[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Container(
                key: ValueKey<int>(selectedIndex),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  child: _buildContent(tabs[selectedIndex], isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}