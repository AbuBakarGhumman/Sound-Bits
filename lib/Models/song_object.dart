import 'package:on_audio_query/on_audio_query.dart';

class SongObject {
  final int id;
  final String title;
  final String? artist;
  final String? uri;
  final String? data;

  const SongObject({
    required this.id,
    required this.title,
    this.artist,
    this.uri,
    this.data,
  });

  // Convert from SongModel (used when fetching from device)
  factory SongObject.fromSongModel(SongModel song) {
    return SongObject(
      id: song.id,
      title: song.title,
      artist: song.artist,
      uri: song.uri,
      data: song.data,
    );
  }

  // NEW: Convert from a Map (e.g., when loading from SharedPreferences)
  // This factory is what solves the "'fromJson' isn't defined" error.
  factory SongObject.fromJson(Map<String, dynamic> json) {
    return SongObject(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      uri: json['uri'],
      data: json['data'],
    );
  }

  // NEW: Convert to a Map (e.g., when saving to SharedPreferences)
  // This method is what solves the "'toJson' isn't defined" error.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'uri': uri,
      'data': data,
    };
  }
}