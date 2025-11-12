import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../Constants/app_constants.dart';
import '../../Models/song_object.dart';
import '../../Services/music_service.dart';
import '../Components/album_item.dart';
import '../Components/folder_item.dart';
import '../Components/track_item.dart';
import '../Components/splash_title.dart';

class MLibraryPage extends StatefulWidget {
  final Song? currentlyPlayingSong;
  final bool isPlaying;
  final VoidCallback onGoHome;
  final Function(Song song, List<Song> allSongs, String folderName, int index)
  onPlaySong;

  const MLibraryPage({
    super.key,
    required this.currentlyPlayingSong,
    required this.isPlaying,
    required this.onGoHome,
    required this.onPlaySong,
  });

  @override
  State<MLibraryPage> createState() => _MLibraryPageState();
}

class _MLibraryPageState extends State<MLibraryPage> {
  final ScrollController _scrollController = ScrollController();
  int selectedIndex = 1;
  int previousIndex = 1;

  final MusicService _musicService = MusicService();

  late Future<Map<String, List<Song>>> _foldersFuture;
  late Future<List<Song>> _tracksFuture;
  late Future<Map<String, List<Song>>> _albumsFuture;

  bool _futuresInitialized = false;

  final List<String> tabs = [
    'Favourites',
    'Tracks',
    'Albums',
    'Artists',
    'Folders'
  ];

  late final List<GlobalKey> _tabKeys;
  bool _isAutoScrolling = false;

  Offset _dragStart = Offset.zero;
  Offset _dragUpdate = Offset.zero;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(tabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerSelectedTab(selectedIndex);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_futuresInitialized) {
      _foldersFuture = _musicService.fetchFolders();
      _tracksFuture = _musicService.fetchSongs();
      _albumsFuture = _musicService.fetchAlbums();
      _futuresInitialized = true;
    }
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
      setState(() => selectedIndex = closestTabIndex);
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
    final targetOffset =
        itemPosition.dx - (screenWidth / 2) + (itemWidth / 2);
    final newScrollOffset = (scrollOffset + targetOffset)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController
        .animateTo(
      newScrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .whenComplete(() => _isAutoScrolling = false);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragUpdate = details.globalPosition;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dx = _dragUpdate.dx - _dragStart.dx;
    if (dx.abs() > 50) {
      if (dx < 0 && selectedIndex < tabs.length - 1) {
        setState(() {
          previousIndex = selectedIndex;
          selectedIndex++;
        });
        _centerSelectedTab(selectedIndex);
      } else if (dx > 0 && selectedIndex > 0) {
        setState(() {
          previousIndex = selectedIndex;
          selectedIndex--;
        });
        _centerSelectedTab(selectedIndex);
      }
    }
  }

  Widget _buildContent(String sectionTitle, bool isDark) {
    switch (sectionTitle) {
      case 'Tracks':
        return FutureBuilder<List<Song>>(
          future: _tracksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No songs found on device."));
            }

            final songs = snapshot.data!;

            return ListView.builder(
              key: const ValueKey('tracks_list'),
              padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isSelected = widget.currentlyPlayingSong?.uri == song.uri;

                return TrackItem(
                  songTitle: song.title,
                  artistName:
                  (song.artist == "<unknown>" || song.artist.trim().isEmpty)
                      ? "Unknown"
                      : song.artist,
                  isDark: isDark,
                  isSelected: isSelected,
                  isPlaying: isSelected && widget.isPlaying,
                  onTap: () {
                    widget.onPlaySong(song, songs, 'All Tracks', index);
                  },
                  onMoreTap: () {},
                );
              },
            );
          },
        );

      case 'Albums':
        return FutureBuilder<Map<String, List<Song>>>(
          future: _albumsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No albums found."));
            }

            final albums = snapshot.data!;
            final albumNames = albums.keys.toList();

            return GridView.builder(
              key: const ValueKey('albums_grid'),
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 6,
                childAspectRatio: 0.67,
              ),
              itemCount: albumNames.length,
              itemBuilder: (context, index) {
                final albumName = albumNames[index];
                final songsInAlbum = albums[albumName]!;
                final firstSong = songsInAlbum.first;

                return AlbumItem(
                  albumTitle: albumName,
                  artistName: (firstSong.artist == "<unknown>" ||
                      firstSong.artist.trim().isEmpty)
                      ? "Unknown"
                      : firstSong.artist,
                  coverUrl: null,
                  isDark: isDark,
                  onTap: () {
                    widget.onPlaySong(
                      songsInAlbum.first,
                      songsInAlbum,
                      albumName,
                      0,
                    );
                  },
                );
              },
            );
          },
        );

      case 'Folders':
        return FutureBuilder<Map<String, List<Song>>>(
          future: _foldersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No music folders found."));
            }

            final folders = snapshot.data!;
            final folderPaths = folders.keys.toList();

            return ListView.builder(
              key: const ValueKey('folders_list'),
              padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
              itemCount: folderPaths.length,
              itemBuilder: (context, itemIndex) {
                final folderPath = folderPaths[itemIndex];
                final songsInFolder = folders[folderPath]!;

                return FolderItem(
                  folderName: p.basename(folderPath),
                  trackCount: songsInFolder.length,
                  isDark: isDark,
                  onTap: () {
                    if (songsInFolder.isNotEmpty) {
                      widget.onPlaySong(
                        songsInFolder.first,
                        songsInFolder,
                        p.basename(folderPath),
                        0,
                      );
                    }
                  },
                );
              },
            );
          },
        );

      default:
        return Center(child: Text("$sectionTitle will be implemented here."));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool slideFromRight = previousIndex > selectedIndex;

    return WillPopScope(
      onWillPop: () async {
        widget.onGoHome();
        return false;
      },
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
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
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      !_isAutoScrolling) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!_isAutoScrolling && mounted) _handleScrollEnd();
                    });
                  }
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding:
                  EdgeInsets.symmetric(horizontal: screenWidth / 2 - 60),
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedIndex;
                    return GestureDetector(
                      key: _tabKeys[index],
                      onTap: () {
                        setState(() {
                          previousIndex = selectedIndex;
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
                            fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark
                                ? Colors.white54
                                : Colors.black54),
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
              child: GestureDetector(
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: slideFromRight
                          ? const Offset(1.0, 0.0)
                          : const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ));
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(selectedIndex),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.grey[100],
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
            ),
          ],
        ),
      ),
    );
  }
}
