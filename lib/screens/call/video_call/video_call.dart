import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String appId;
  final bool isVideoCall;
  final String userId;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.appId,
    required this.isVideoCall,
    required this.userId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _isLocalVideoEnabled = true;
  bool _isMuted = false;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isFrontCamera = true;
  String _remoteUserName = '';
  String _remoteUserPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _initAgoraEngine();
  }

  Future<void> _initAgoraEngine() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: widget.appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) async {
          setState(() {
            _remoteUid = remoteUid;
          });
          await _fetchRemoteUserData(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
            _remoteUserName = '';
            _remoteUserPhotoUrl = '';
          });
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    if (widget.isVideoCall) {
      await _engine.enableVideo();
    }
    await _engine.startPreview();

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _fetchRemoteUserData(int remoteUid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _remoteUserName = userData['username'];
          _remoteUserPhotoUrl = userData['profile_picture'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching remote user data: $e');
    }
  }

  @override
  void dispose() {
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

  void _toggleCamera() async {
    setState(() {
      _isLocalVideoEnabled = !_isLocalVideoEnabled;
    });
    await _engine.enableLocalVideo(_isLocalVideoEnabled);
  }

  void _switchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Vídeo remoto
          if (widget.isVideoCall)
            _remoteUid != null
                ? Positioned.fill(
                    child: AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection:
                            RtcConnection(channelId: widget.channelName),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Chamando...',
                      textAlign: TextAlign.center,
                    ),
                  ),
          // Vídeo local
          if (widget.isVideoCall)
            Positioned(
              bottom: 20,
              right: 20,
              child: SizedBox(
                width: 100,
                height: 150,
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator.adaptive(),
              ),
            ),
          // Exibir nome e foto do usuário remoto
          if (widget.isVideoCall && _remoteUid != null)
            Positioned(
              top: 30,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: _remoteUserPhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(_remoteUserPhotoUrl)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _remoteUserName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.mic),
              color: _isMuted ? Colors.red : Colors.white,
              onPressed: _toggleMute,
              tooltip: 'Mudo',
            ),
            if (widget.isVideoCall)
              IconButton(
                icon: const Icon(Icons.switch_camera),
                color: Colors.white,
                onPressed: _switchCamera,
                tooltip: 'Inverter Câmera',
              ),
            if (widget.isVideoCall)
              IconButton(
                icon: Icon(
                  _isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
                ),
                color: Colors.white,
                onPressed: _toggleCamera,
                tooltip: 'Ativar/Desativar Câmera',
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
