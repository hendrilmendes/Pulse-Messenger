import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, ValueNotifier<Duration>> _currentPositions = {};
  final Map<String, ValueNotifier<Duration>> _totalDurations = {};
  final Map<String, ValueNotifier<bool>> _isPlayings = {};

  ValueNotifier<Duration> getCurrentPositionNotifier(String audioUrl) {
    return _currentPositions[audioUrl] ??= ValueNotifier(Duration.zero);
  }

  ValueNotifier<Duration> getTotalDurationNotifier(String audioUrl) {
    return _totalDurations[audioUrl] ??= ValueNotifier(Duration.zero);
  }

  ValueNotifier<bool> getIsPlayingNotifier(String audioUrl) {
    return _isPlayings[audioUrl] ??= ValueNotifier(false);
  }

  Future<void> playAudio(String audioUrl) async {
    if (_players.containsKey(audioUrl)) {
      // Verifica se o player está ativo ou em um estado incorreto e reinicializa se necessário
      if (_players[audioUrl]!.state == PlayerState.completed ||
          _players[audioUrl]!.state == PlayerState.stopped) {
        await _players[audioUrl]!.dispose(); // Libera o player anterior
        _players.remove(audioUrl); // Remove o player anterior
      } else {
        await _players[audioUrl]!
            .resume(); // Retoma a reprodução se o player ainda estiver válido
        return;
      }
    }

    // Caso não haja um player válido, cria um novo
    try {
      final player = AudioPlayer();
      _players[audioUrl] = player;

      // Configurar o foco de áudio no Android
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      final positionNotifier = getCurrentPositionNotifier(audioUrl);
      final durationNotifier = getTotalDurationNotifier(audioUrl);
      final isPlayingNotifier = getIsPlayingNotifier(audioUrl);

      player.onDurationChanged.listen((duration) {
        durationNotifier.value = duration;
      });

      player.onPositionChanged.listen((position) {
        positionNotifier.value = position;
      });

      player.onPlayerStateChanged.listen((state) {
        isPlayingNotifier.value = state == PlayerState.playing;
      });

      player.onPlayerComplete.listen((_) {
        isPlayingNotifier.value = false;
        positionNotifier.value = Duration.zero;
      });

      await player.setSource(UrlSource(audioUrl));
      await player.resume();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
    }
  }

  Future<void> pauseAudio(String audioUrl) async {
    if (_players.containsKey(audioUrl)) {
      try {
        final player = _players[audioUrl];

        // Pausar o áudio diretamente
        await player!.pause();

        // Atualizar o estado do player
        getIsPlayingNotifier(audioUrl).value = false;

        if (kDebugMode) {
          print('Audio paused successfully.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error pausing audio: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('No player found for $audioUrl');
      }
    }
  }

  Future<void> seek(String audioUrl, Duration position) async {
    final player = _players[audioUrl];
    if (player != null) {
      try {
        await player.seek(position);
      } catch (e) {
        if (kDebugMode) {
          print('Error seeking audio: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('No audio player found for $audioUrl');
      }
    }
  }
}
