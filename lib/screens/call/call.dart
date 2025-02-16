import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String appId;
  final String userId;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.appId,
    required this.userId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  bool _isMuted = false;
  int? _remoteUid;
  Timer? _timer;
  int _elapsedTime = 0;

  String? _remoteUserName;
  String? _remoteUserPhotoUrl;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _initAgoraEngine();
  }

  Future<void> _initAgoraEngine() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: widget.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
        },
        onUserJoined: (
          RtcConnection connection,
          int remoteUid,
          int elapsed,
        ) async {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
          _startTimer();

          // Fetch remote user info from Firebase
          var userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .get();
          if (userDoc.exists) {
            var userData = userDoc.data()!;
            if (mounted) {
              setState(() {
                _remoteUserName = userData['username'];
                _remoteUserPhotoUrl = userData['profile_picture'];
              });
            }
          }
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          debugPrint("Remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
          _stopTimer();
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint("Token will expire: $token");
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio();

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  String _formatElapsedTime(int elapsedTime) {
    int minutes = elapsedTime ~/ 60;
    int seconds = elapsedTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chamada de Voz',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child:
            _remoteUid != null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _remoteUserPhotoUrl != null
                              ? CachedNetworkImageProvider(_remoteUserPhotoUrl!)
                              : const NetworkImage(
                                'https://www.example.com/default_profile.jpg',
                              ),
                      backgroundColor: Colors.grey[800],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _remoteUserName ?? 'Nome do Usuário',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Duração: ${_formatElapsedTime(_elapsedTime)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                )
                : const Text('Chamando...', style: TextStyle(fontSize: 18)),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              color: Colors.white,
              onPressed: _toggleMute,
            ),
            IconButton(
              icon: const Icon(Icons.call_end),
              color: Colors.red,
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: 'Encerrar Chamada',
            ),
          ],
        ),
      ),
    );
  }
}
