import 'package:volume_controller/volume_controller.dart';

class VolumeControllerService {
  static final VolumeController _controller = VolumeController();

  /// Initializes the volume controller
  static void init() {
    _controller.showSystemUI = true;
  }

  /// Opens the system volume panel by triggering a tiny volume change
  static Future<void> openSystemVolumePanel() async {
    double currentVolume = await _controller.getVolume();
     _controller.setVolume(currentVolume + 0.01);
    await Future.delayed(const Duration(milliseconds: 100));
    _controller.setVolume(currentVolume);
  }
}
