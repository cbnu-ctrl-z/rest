import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceCallService {
  static final VoiceCallService _instance = VoiceCallService._internal();
  factory VoiceCallService() => _instance;
  VoiceCallService._internal();

  late RtcEngine _engine;
  bool _isInitialized = false;
  bool _isInCall = false;
  bool _isLocalMuted = false;
  bool _isSpeakerOn = false;
  String? _channelName;
  int? _localUid;
  int? _remoteUid;
  
  // Agora App ID (환경변수에서 가져오기)
  final String appId = String.fromEnvironment('AGORA_APP_ID') ?? 
                       dotenv.env['AGORA_APP_ID'] ?? 
                       'YOUR_AGORA_APP_ID_HERE';

  // 콜백 함수들
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserOffline;
  Function(bool muted)? onRemoteAudioStateChanged;
  Function(RtcConnection connection, RtcStats stats)? onRtcStats;
  Function(String errorMsg)? onError;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    try {
      // 권한 요청
      await _requestPermissions();

      // Agora 엔진 생성
      _engine = createAgoraRtcEngine();
      
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 이벤트 핸들러 설정
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("로컬 사용자 ${connection.localUid} 채널 참여 성공");
            _localUid = connection.localUid;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("원격 사용자 $remoteUid 참여");
            _remoteUid = remoteUid;
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("원격 사용자 $remoteUid 나감");
            _remoteUid = null;
            onUserOffline?.call(remoteUid);
          },
          onRtcStats: (RtcConnection connection, RtcStats stats) {
            onRtcStats?.call(connection, stats);
          },
          onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid,
              RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
            if (state == RemoteAudioState.remoteAudioStateStopped) {
              onRemoteAudioStateChanged?.call(true);
            } else if (state == RemoteAudioState.remoteAudioStateStarting) {
              onRemoteAudioStateChanged?.call(false);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora 에러: $err - $msg');
            onError?.call(msg);
          },
        ),
      );

      _isInitialized = true;
      debugPrint("Agora 초기화 완료");
    } catch (e) {
      debugPrint("Agora 초기화 실패: $e");
      onError?.call("초기화 실패: $e");
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  Future<void> joinChannel(String channelName, String? token) async {
    if (!_isInitialized) {
      await initAgora();
    }

    try {
      _channelName = channelName;
      
      // 오디오 설정
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableAudio();
      
      // 채널 참여 (토큰이 null이면 토큰 없이 참여)
      await _engine.joinChannel(
        token: token ?? "",  // null이면 빈 문자열 사용
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      _isInCall = true;
      debugPrint("채널 참여: $channelName (토큰: ${token != null ? '있음' : '없음'})");
    } catch (e) {
      debugPrint("채널 참여 실패: $e");
      onError?.call("채널 참여 실패: $e");
    }
  }

  Future<void> leaveChannel() async {
    try {
      if (_isInCall) {
        await _engine.leaveChannel();
        _isInCall = false;
        _channelName = null;
        _remoteUid = null;
        debugPrint("채널 나가기 완료");
      }
    } catch (e) {
      debugPrint("채널 나가기 실패: $e");
      onError?.call("채널 나가기 실패: $e");
    }
  }

  Future<void> toggleMute() async {
    try {
      // 현재 음소거 상태 확인 및 토글
      await _engine.muteLocalAudioStream(_isLocalMuted);
      _isLocalMuted = !_isLocalMuted;
      debugPrint("마이크 ${_isLocalMuted ? '음소거' : '음소거 해제'}");
    } catch (e) {
      debugPrint("음소거 토글 실패: $e");
    }
  }

  Future<void> switchSpeakerphone() async {
    try {
      // 현재 스피커폰 상태 토글
      _isSpeakerOn = !_isSpeakerOn;
      await _engine.setEnableSpeakerphone(_isSpeakerOn);
      debugPrint("스피커폰 ${_isSpeakerOn ? '켜짐' : '꺼짐'}");
    } catch (e) {
      debugPrint("스피커폰 전환 실패: $e");
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await leaveChannel();
      await _engine.release();
      _isInitialized = false;
      _isLocalMuted = false;
      _isSpeakerOn = false;
      debugPrint("Agora 엔진 해제 완료");
    }
  }

  bool get isInCall => _isInCall;
  bool get isLocalMuted => _isLocalMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get channelName => _channelName;
  int? get remoteUid => _remoteUid;
}