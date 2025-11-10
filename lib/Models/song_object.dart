class Song {
  final String title;       // Song name
  final String artist;      // Artist name
  final String uri;         // Full file path (used for playback)
  final String? album;      // Optional album name
  final String? thumbnail;  // Optional album art (can be file path or base64)

  const Song({
    required this.title,
    required this.artist,
    required this.uri,
    this.album,
    this.thumbnail,
  });

  // Convert to Map (for local storage or JSON)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'uri': uri,
      'album': album,
      'thumbnail': thumbnail,
    };
  }

  // Create Song from Map
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      uri: map['uri'] ?? '',
      album: map['album'],
      thumbnail: map['thumbnail'],
    );
  }

  // Equality override for easy comparison (e.g., in favorites, queues)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Song &&
              runtimeType == other.runtimeType &&
              uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}
