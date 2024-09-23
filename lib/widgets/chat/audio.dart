import 'package:flutter/material.dart';
import 'package:social/providers/manager_audio.dart';

class AudioCard extends StatelessWidget {
  final String audioUrl;
  final VoidCallback onPlayPausePressed;
  final ValueChanged<double> onSliderChanged;

  const AudioCard({
    super.key,
    required this.audioUrl,
    required this.onPlayPausePressed,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentPositionNotifier =
        AudioManager().getCurrentPositionNotifier(audioUrl);
    final totalDurationNotifier =
        AudioManager().getTotalDurationNotifier(audioUrl);
    final isPlayingNotifier = AudioManager().getIsPlayingNotifier(audioUrl);

    return ValueListenableBuilder<Duration>(
      valueListenable: currentPositionNotifier,
      builder: (context, currentPosition, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: totalDurationNotifier,
          builder: (context, totalDuration, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: isPlayingNotifier,
              builder: (context, isPlaying, _) {
                final double maxDuration = totalDuration.inSeconds.toDouble();
                final double currentPositionValue =
                    currentPosition.inSeconds.toDouble();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Play/Pause Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withOpacity(0.2),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 24,
                            ),
                            onPressed: onPlayPausePressed,
                            color: Colors.blueAccent,
                            splashRadius: 20,
                          ),
                        ),

                        const SizedBox(width: 16),
                        // Slider and Time Display
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Slider
                              SizedBox(
                                height: 24,
                                width: double.infinity,
                                child: Theme(
                                  data: ThemeData(
                                    sliderTheme: SliderThemeData(
                                      trackShape: CustomTrackShape(),
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                      activeTrackColor: Colors.blueAccent,
                                      inactiveTrackColor:
                                          Colors.blueAccent.withOpacity(0.3),
                                      thumbColor: Colors.blueAccent,
                                      overlayColor:
                                          Colors.blueAccent.withOpacity(0.2),
                                      valueIndicatorColor: Colors.blueAccent,
                                      valueIndicatorTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    splashColor: Colors.transparent,
                                  ),
                                  child: Slider(
                                    value: currentPositionValue,
                                    max: maxDuration > 0
                                        ? maxDuration
                                        : 1, // Evitar max = 0
                                    min: 0,
                                    onChanged: onSliderChanged,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Time Display
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(currentPosition),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(totalDuration),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

/// Custom track shape for the slider to match the design
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
