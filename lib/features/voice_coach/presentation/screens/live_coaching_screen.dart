import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import '../../application/providers.dart';
import '../../data/models/coach_models.dart';
import '../../../tactical_board/presentation/screens/tactical_board_screen.dart';
import '../../../tutorials/presentation/screens/tutorials_page.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';
import '../widgets/scouting_overlay.dart';

final _liveVideoUiStateProvider = StateProvider.autoDispose<_LiveVideoUiState>((
  ref,
) {
  return const _LiveVideoUiState();
});

enum _LiveCoachMenuAction {
  resetChat,
  tacticalBoard,
  history,
  tutorials,
  settings,
}

class LiveCoachingScreen extends ConsumerStatefulWidget {
  const LiveCoachingScreen({super.key});

  @override
  ConsumerState<LiveCoachingScreen> createState() => _LiveCoachingScreenState();
}

class _LiveCoachingScreenState extends ConsumerState<LiveCoachingScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _questionController;
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  CameraController? _cameraController;
  VideoPlayerController? _scoutingVideoController;
  Timer? _autoScoutTimer;
  String? _scoutingVideoPath;
  String _scoutingVideoLabel = 'No Video Uploaded';
  String? _detectedReplayAction;
  List<ScoutingEvent> _scoutingEvents = const [];
  bool _isAnalyzingReplayFrame = false;
  bool _isLoadingScoutingVideo = false;
  String? _scoutingVideoError;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.92,
      upperBound: 1.08,
      value: 1,
    );
  }

  @override
  void dispose() {
    _autoScoutTimer?.cancel();
    final cameraController = _cameraController;
    _cameraController = null;
    final scoutingVideoController = _scoutingVideoController;
    _scoutingVideoController = null;
    unawaited(cameraController?.dispose() ?? Future<void>.value());
    unawaited(scoutingVideoController?.dispose() ?? Future<void>.value());
    _questionController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactTopBar = MediaQuery.sizeOf(context).width < 420;
    final session = ref.watch(matchSessionProvider);
    final messages = ref.watch(chatMessagesProvider);
    final alerts = ref.watch(alertsProvider);
    final followups = ref.watch(followupSuggestionsProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isListening = ref.watch(isListeningProvider);
    final transcript = ref.watch(liveTranscriptProvider);
    final settings = ref.watch(settingsProvider);
    final liveVideoUiState = ref.watch(_liveVideoUiStateProvider);

    if (session == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    if (isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isListening && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.matchName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (compactTopBar)
            PopupMenuButton<_LiveCoachMenuAction>(
              tooltip: 'More',
              onSelected: _handleMenuAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _LiveCoachMenuAction.resetChat,
                  child: Text('Reset Chat'),
                ),
                PopupMenuItem(
                  value: _LiveCoachMenuAction.tacticalBoard,
                  child: Text('Tactical Board'),
                ),
                PopupMenuItem(
                  value: _LiveCoachMenuAction.history,
                  child: Text('History'),
                ),
                PopupMenuItem(
                  value: _LiveCoachMenuAction.tutorials,
                  child: Text('Tutorials'),
                ),
                PopupMenuItem(
                  value: _LiveCoachMenuAction.settings,
                  child: Text('Settings'),
                ),
              ],
            )
          else ...[
            IconButton(
              tooltip: 'Reset chat',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: _confirmResetChat,
            ),
            IconButton(
              tooltip: 'Tactical board',
              icon: const Icon(Icons.dashboard_customize_rounded),
              onPressed: _openTacticalBoard,
            ),
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history_rounded),
              onPressed: _openHistory,
            ),
            IconButton(
              tooltip: 'Tutorials',
              icon: const Icon(Icons.ondemand_video_rounded),
              onPressed: _openTutorials,
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openSettings,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 760;

                  return Column(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            isCompact ? 8 : 12,
                          ),
                          child: Column(
                            children: [
                              _HeaderRow(
                                currentSet: session.currentSet,
                                onSetDown: () => ref
                                    .read(coachControllerProvider)
                                    .updateSet(-1),
                                onSetUp: () => ref
                                    .read(coachControllerProvider)
                                    .updateSet(1),
                              ),
                              SizedBox(height: isCompact ? 12 : 16),
                              _LiveVideoScoutCard(
                                controller: _cameraController,
                                isCameraReady: liveVideoUiState.isCameraReady,
                                isStartingCamera:
                                    liveVideoUiState.isStartingCamera,
                                isAnalyzingFrame:
                                    liveVideoUiState.isAnalyzingFrame,
                                isAutoScoutEnabled:
                                    liveVideoUiState.isAutoScoutEnabled,
                                cameraError: liveVideoUiState.cameraError,
                                canSwitchCamera:
                                    liveVideoUiState.availableCameras.length >
                                    1,
                                onToggleVideo: _toggleLiveVideo,
                                onScoutFrame: _captureScoutFrame,
                                onToggleAutoScout: _toggleAutoScout,
                                onSwitchCamera: _switchCamera,
                                compact: isCompact,
                              ),
                              SizedBox(height: isCompact ? 12 : 16),
                              _ReplayScoutCard(
                                controller: _scoutingVideoController,
                                isLoading: _isLoadingScoutingVideo,
                                isAnalyzingFrame: _isAnalyzingReplayFrame,
                                errorMessage: _scoutingVideoError,
                                videoLabel: _scoutingVideoLabel,
                                hasUploadedVideo: _scoutingVideoPath != null,
                                detectedAction: _detectedReplayAction,
                                activeRotation: session.currentRotation.clamp(
                                  1,
                                  6,
                                ),
                                initialEvents: _scoutingEvents,
                                onRecordEvent: (event) {
                                  setState(() {
                                    _scoutingEvents = [
                                      event,
                                      ..._scoutingEvents,
                                    ];
                                  });
                                },
                                onTogglePlayback: _toggleReplayPlayback,
                                onSeekBack: () =>
                                    _seekReplayBy(const Duration(seconds: -5)),
                                onSeekForward: () =>
                                    _seekReplayBy(const Duration(seconds: 5)),
                                onReloadClip: _reloadScoutingVideo,
                                onUploadVideo: _pickScoutingVideo,
                                onScoutCurrentFrame: _captureReplayScoutFrame,
                              ),
                              SizedBox(height: isCompact ? 12 : 16),
                              _ScoreboardCard(session: session),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: messages.isEmpty
                            ? _EmptyChat(
                                autoSpeak: settings.autoSpeak,
                                isListening: isListening,
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  12,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  return _MessageBubble(
                                    message: message,
                                    onPlay: message.role == 'ai'
                                        ? () => ref
                                              .read(coachControllerProvider)
                                              .replayMessage(message)
                                        : null,
                                  );
                                },
                              ),
                      ),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              avatar: const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              label: const Text('Thinking...'),
                            ),
                          ),
                        ),
                      if (transcript.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              transcript,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final followup = followups[index];
                            return ActionChip(
                              label: Text(followup),
                              onPressed: () => ref
                                  .read(coachControllerProvider)
                                  .askQuestion(followup),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemCount: followups.length,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          isCompact ? 12 : 16,
                        ),
                        child: _InputBar(
                          controller: _questionController,
                          isListening: isListening,
                          pulseController: _pulseController,
                          onSend: _handleSend,
                          onMicTap: () {
                            if (isListening) {
                              ref.read(coachControllerProvider).stopListening();
                            } else {
                              ref
                                  .read(coachControllerProvider)
                                  .startListening();
                            }
                          },
                          onTimeout: () => ref
                              .read(coachControllerProvider)
                              .requestTimeout(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (alerts.isNotEmpty)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Column(
                children: alerts
                    .map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertBanner(
                          alert: alert,
                          onDismiss: () => ref
                              .read(coachControllerProvider)
                              .dismissAlert(alert.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _questionController.clear();
    ref.read(coachControllerProvider).askQuestion(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _toggleLiveVideo() async {
    if (_cameraController != null && _liveVideoUiState.isCameraReady) {
      await _stopLiveVideo();
      return;
    }
    await _startLiveVideo();
  }

  Future<void> _startLiveVideo({CameraDescription? preferredCamera}) async {
    if (_liveVideoUiState.isStartingCamera) {
      return;
    }

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (!mounted) {
        return;
      }
      _setLiveVideoUiState(
        _liveVideoUiState.copyWith(
          cameraError: 'Camera permission is required for live video scouting.',
        ),
      );
      return;
    }

    _setLiveVideoUiState(
      _liveVideoUiState.copyWith(isStartingCamera: true, cameraError: null),
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera available on this device.');
      }

      final selectedCamera =
          preferredCamera ??
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      final nextController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await nextController.initialize();
      await nextController.setFlashMode(FlashMode.off);
      await nextController.setFocusMode(FocusMode.auto);
      await nextController.setExposureMode(ExposureMode.auto);

      final previousController = _cameraController;
      if (!mounted) {
        await nextController.dispose();
        await previousController?.dispose();
        return;
      }

      _cameraController = nextController;
      _setLiveVideoUiState(
        _liveVideoUiState.copyWith(
          availableCameras: cameras,
          isCameraReady: true,
          isStartingCamera: false,
          cameraError: null,
        ),
      );

      await previousController?.dispose();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _setLiveVideoUiState(
        _liveVideoUiState.copyWith(
          isCameraReady: false,
          isStartingCamera: false,
          cameraError:
              'Live video scouting is unavailable right now on this device.',
        ),
      );
    }
  }

  Future<void> _stopLiveVideo() async {
    _autoScoutTimer?.cancel();
    _autoScoutTimer = null;
    final currentController = _cameraController;
    _cameraController = null;
    _setLiveVideoUiState(
      _liveVideoUiState.copyWith(
        isCameraReady: false,
        isAutoScoutEnabled: false,
        isAnalyzingFrame: false,
        cameraError: null,
      ),
    );
    await currentController?.dispose();
  }

  Future<void> _switchCamera() async {
    if (_liveVideoUiState.availableCameras.length < 2) {
      return;
    }

    final currentDescription = _cameraController?.description;
    final currentIndex = _liveVideoUiState.availableCameras.indexWhere(
      (camera) => camera.name == currentDescription?.name,
    );
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _liveVideoUiState.availableCameras.length;
    await _startLiveVideo(
      preferredCamera: _liveVideoUiState.availableCameras[nextIndex],
    );
  }

  Future<void> _captureScoutFrame() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _liveVideoUiState.isAnalyzingFrame) {
      return;
    }

    _setLiveVideoUiState(_liveVideoUiState.copyWith(isAnalyzingFrame: true));

    try {
      final frame = await controller.takePicture();
      final bytes = await frame.readAsBytes();
      await ref
          .read(coachControllerProvider)
          .analyzeVideoFrame(bytes, sourceLabel: 'live camera frame');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not capture the live frame. Try again in a moment.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        _setLiveVideoUiState(
          _liveVideoUiState.copyWith(isAnalyzingFrame: false),
        );
      }
    }
  }

  Future<void> _toggleAutoScout() async {
    if (_liveVideoUiState.isAutoScoutEnabled) {
      _autoScoutTimer?.cancel();
      _autoScoutTimer = null;
      if (mounted) {
        _setLiveVideoUiState(
          _liveVideoUiState.copyWith(isAutoScoutEnabled: false),
        );
      }
      return;
    }

    if (_cameraController == null || !_liveVideoUiState.isCameraReady) {
      await _startLiveVideo();
    }

    if (_cameraController == null || !_liveVideoUiState.isCameraReady) {
      return;
    }

    if (mounted) {
      _setLiveVideoUiState(
        _liveVideoUiState.copyWith(isAutoScoutEnabled: true),
      );
    }

    await _captureScoutFrame();
    _autoScoutTimer?.cancel();
    _autoScoutTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_liveVideoUiState.isAnalyzingFrame && mounted) {
        unawaited(_captureScoutFrame());
      }
    });
  }

  _LiveVideoUiState get _liveVideoUiState =>
      ref.read(_liveVideoUiStateProvider);

  void _setLiveVideoUiState(_LiveVideoUiState nextState) {
    ref.read(_liveVideoUiStateProvider.notifier).state = nextState;
  }

  Future<void> _loadScoutingVideo({String? path, String? label}) async {
    if (mounted) {
      setState(() {
        _isLoadingScoutingVideo = true;
        _scoutingVideoError = null;
        _detectedReplayAction = null;
      });
    }

    if (path == null) {
      final previousController = _scoutingVideoController;
      _scoutingVideoController = null;
      await previousController?.dispose();
      if (mounted) {
        setState(() {
          _scoutingVideoPath = null;
          _scoutingVideoLabel = 'No Video Uploaded';
          _isLoadingScoutingVideo = false;
          _scoutingVideoError = null;
        });
      }
      return;
    }

    final controller = VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
      await controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final previousController = _scoutingVideoController;
      setState(() {
        _scoutingVideoController = controller;
        _scoutingVideoPath = path;
        _scoutingVideoLabel = label ?? 'Match Video';
        _isLoadingScoutingVideo = false;
      });
      await previousController?.dispose();
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingScoutingVideo = false;
        _scoutingVideoError =
            'That video could not be loaded. Try another clip.';
      });
    }
  }

  Future<void> _reloadScoutingVideo() async {
    if (_scoutingVideoPath == null) {
      return;
    }
    await _scoutingVideoController?.pause();
    await _loadScoutingVideo(
      path: _scoutingVideoPath,
      label: _scoutingVideoLabel,
    );
  }

  Future<void> _pickScoutingVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || !mounted) {
      return;
    }

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That video could not be opened on this device.'),
        ),
      );
      return;
    }

    await _loadScoutingVideo(path: path, label: file.name);
  }

  Future<void> _toggleReplayPlayback() async {
    final controller = _scoutingVideoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _seekReplayBy(Duration delta) async {
    final controller = _scoutingVideoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final next = controller.value.position + delta;
    final maxPosition = controller.value.duration;
    final safePosition = next < Duration.zero
        ? Duration.zero
        : next > maxPosition
        ? maxPosition
        : next;

    await controller.seekTo(safePosition);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _captureReplayScoutFrame() async {
    final controller = _scoutingVideoController;
    final videoPath = _scoutingVideoPath;
    if (_isAnalyzingReplayFrame) {
      return;
    }
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload a match video first so I can scout replay frames.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzingReplayFrame = true;
    });

    try {
      final frameBytes = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        timeMs: controller.value.position.inMilliseconds,
        quality: 85,
        maxWidth: 1280,
      );
      if (frameBytes == null || frameBytes.isEmpty) {
        throw StateError('No thumbnail bytes were generated.');
      }

      final response = await ref
          .read(coachControllerProvider)
          .analyzeVideoFrame(frameBytes, sourceLabel: 'uploaded replay frame');
      if (mounted) {
        setState(() {
          _detectedReplayAction = _extractDetectedAction(response?.text);
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'I could not scout that replay frame. Try another moment in the video.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingReplayFrame = false;
        });
      }
    }
  }

  String? _extractDetectedAction(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'ACTION:\s*([^\n\r]+)',
      caseSensitive: false,
    ).firstMatch(text);
    final action = match?.group(1)?.trim();
    if (action == null || action.isEmpty) {
      return null;
    }
    if (action.toLowerCase() == 'unknown') {
      return null;
    }
    return action;
  }

  void _openTacticalBoard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TacticalBoardScreen()));
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SessionHistoryScreen()));
  }

  void _openTutorials() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TutorialsPage()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _handleMenuAction(_LiveCoachMenuAction action) {
    switch (action) {
      case _LiveCoachMenuAction.resetChat:
        _confirmResetChat();
      case _LiveCoachMenuAction.tacticalBoard:
        _openTacticalBoard();
      case _LiveCoachMenuAction.history:
        _openHistory();
      case _LiveCoachMenuAction.tutorials:
        _openTutorials();
      case _LiveCoachMenuAction.settings:
        _openSettings();
    }
  }

  Future<void> _confirmResetChat() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset chat?'),
          content: const Text(
            'This clears the current coach conversation and follow-up chips for this match.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !mounted) {
      return;
    }

    await ref.read(coachControllerProvider).resetChat();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat reset.')));
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.currentSet,
    required this.onSetDown,
    required this.onSetUp,
  });

  final int currentSet;
  final VoidCallback onSetDown;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Volleyball AI Coach',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onSetDown,
                child: const Icon(Icons.remove, size: 18),
              ),
              const SizedBox(width: 8),
              Text('Set $currentSet', style: theme.textTheme.labelLarge),
              const SizedBox(width: 8),
              InkWell(onTap: onSetUp, child: const Icon(Icons.add, size: 18)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreboardCard extends ConsumerWidget {
  const _ScoreboardCard({required this.session});

  final MatchSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ScoreTeam(
                    label: session.homeTeam.toUpperCase(),
                    score: session.scoreHome,
                    alignEnd: false,
                    onMinus: () =>
                        ref.read(coachControllerProvider).removePoint('home'),
                    onPlus: () =>
                        ref.read(coachControllerProvider).addPoint('home'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    ':',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Expanded(
                  child: _ScoreTeam(
                    label: session.awayTeam.toUpperCase(),
                    score: session.scoreAway,
                    alignEnd: true,
                    onMinus: () =>
                        ref.read(coachControllerProvider).removePoint('away'),
                    onPlus: () =>
                        ref.read(coachControllerProvider).addPoint('away'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () =>
                      ref.read(coachControllerProvider).updateRotation(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Container(
                  width: 82,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    '${session.currentRotation}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(coachControllerProvider).updateRotation(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Text(
              'Rotation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTeam extends StatelessWidget {
  const _ScoreTeam({
    required this.label,
    required this.score,
    required this.alignEnd,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int score;
  final bool alignEnd;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            _TinyScoreButton(icon: Icons.remove_rounded, onTap: onMinus),
            const SizedBox(width: 8),
            _TinyScoreButton(icon: Icons.add_rounded, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _TinyScoreButton extends StatelessWidget {
  const _TinyScoreButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _LiveVideoScoutCard extends StatelessWidget {
  const _LiveVideoScoutCard({
    required this.controller,
    required this.isCameraReady,
    required this.isStartingCamera,
    required this.isAnalyzingFrame,
    required this.isAutoScoutEnabled,
    required this.cameraError,
    required this.canSwitchCamera,
    required this.onToggleVideo,
    required this.onScoutFrame,
    required this.onToggleAutoScout,
    required this.onSwitchCamera,
    required this.compact,
  });

  final CameraController? controller;
  final bool isCameraReady;
  final bool isStartingCamera;
  final bool isAnalyzingFrame;
  final bool isAutoScoutEnabled;
  final String? cameraError;
  final bool canSwitchCamera;
  final VoidCallback onToggleVideo;
  final VoidCallback onScoutFrame;
  final VoidCallback onToggleAutoScout;
  final VoidCallback onSwitchCamera;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Live Video Scout', style: theme.textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCameraReady
                        ? const Color(0xFF14532D)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCameraReady ? 'LIVE' : 'OFF',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isCameraReady
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Capture live court frames and turn them into instant scouting cues for the coaching thread.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: compact ? 164 : 220,
                width: double.infinity,
                child:
                    controller != null &&
                        controller!.value.isInitialized &&
                        isCameraReady
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _CameraPreviewSurface(controller: controller!),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Row(
                              children: [
                                _VideoOverlayChip(
                                  label: 'Live Court',
                                  color: const Color(0xFF16A34A),
                                ),
                                if (isAutoScoutEnabled) ...[
                                  const SizedBox(width: 8),
                                  _VideoOverlayChip(
                                    label: 'Auto Scout',
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isAnalyzingFrame)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.42),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Analyzing live frame...',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surfaceContainerHighest,
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isStartingCamera
                                      ? 'Starting live camera...'
                                      : cameraError ??
                                            'Start live video to scout spacing, blocking shape, and transition posture.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: isStartingCamera ? null : onToggleVideo,
                  icon: Icon(
                    isCameraReady
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                  ),
                  label: Text(isCameraReady ? 'Stop Video' : 'Start Video'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isCameraReady && !isAnalyzingFrame
                      ? onScoutFrame
                      : null,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: Text(isAnalyzingFrame ? 'Scouting...' : 'Scout Frame'),
                ),
                OutlinedButton.icon(
                  onPressed: isCameraReady ? onToggleAutoScout : null,
                  icon: Icon(
                    isAutoScoutEnabled
                        ? Icons.pause_circle_rounded
                        : Icons.radar_rounded,
                  ),
                  label: Text(isAutoScoutEnabled ? 'Stop Auto' : 'Auto Scout'),
                ),
                if (canSwitchCamera)
                  OutlinedButton.icon(
                    onPressed: isCameraReady && !isStartingCamera
                        ? onSwitchCamera
                        : null,
                    icon: const Icon(Icons.flip_camera_ios_rounded),
                    label: const Text('Switch Lens'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayScoutCard extends StatelessWidget {
  const _ReplayScoutCard({
    required this.controller,
    required this.isLoading,
    required this.isAnalyzingFrame,
    required this.errorMessage,
    required this.videoLabel,
    required this.hasUploadedVideo,
    required this.detectedAction,
    required this.activeRotation,
    required this.initialEvents,
    required this.onRecordEvent,
    required this.onTogglePlayback,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onReloadClip,
    required this.onUploadVideo,
    required this.onScoutCurrentFrame,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final bool isAnalyzingFrame;
  final String? errorMessage;
  final String videoLabel;
  final bool hasUploadedVideo;
  final String? detectedAction;
  final int activeRotation;
  final List<ScoutingEvent> initialEvents;
  final ValueChanged<ScoutingEvent> onRecordEvent;
  final VoidCallback onTogglePlayback;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onReloadClip;
  final VoidCallback onUploadVideo;
  final VoidCallback onScoutCurrentFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoController = controller;
    final isReady =
        videoController != null && videoController.value.isInitialized;
    final aspectRatio = isReady && videoController.value.aspectRatio > 0
        ? videoController.value.aspectRatio
        : 16 / 9;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Replay Scout + Chat',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scout the replay, log events, and keep the coaching conversation on this same page.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ReplaySourcePill(
                  label: hasUploadedVideo
                      ? 'Uploaded: $videoLabel'
                      : videoLabel,
                ),
                FilledButton.tonalIcon(
                  onPressed: isLoading ? null : onReloadClip,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reload Clip'),
                ),
                OutlinedButton.icon(
                  onPressed: onUploadVideo,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    hasUploadedVideo ? 'Replace Video' : 'Upload Video',
                  ),
                ),
              ],
            ),
            if ((detectedAction ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _ReplaySourcePill(label: 'Detected: $detectedAction'),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surfaceContainerHighest,
                        theme.colorScheme.primary.withValues(alpha: 0.14),
                      ],
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : isReady
                      ? VideoPlayer(videoController)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage ??
                                      'Upload a volleyball match video to scout the replay inside the app.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: onUploadVideo,
                                  icon: const Icon(Icons.upload_rounded),
                                  label: const Text('Upload Video To Scout'),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (isReady) ...[
              const SizedBox(height: 12),
              VideoProgressIndicator(
                videoController,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.24,
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onTogglePlayback,
                    icon: Icon(
                      videoController.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      videoController.value.isPlaying ? 'Pause' : 'Play',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSeekBack,
                    icon: const Icon(Icons.replay_5_rounded),
                    label: const Text('Back 5s'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSeekForward,
                    icon: const Icon(Icons.forward_5_rounded),
                    label: const Text('Forward 5s'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: hasUploadedVideo && !isAnalyzingFrame
                        ? onScoutCurrentFrame
                        : null,
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: Text(
                      isAnalyzingFrame
                          ? 'Scouting Frame...'
                          : 'Scout This Frame',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ScoutingOverlay(
                controller: videoController,
                activeRotation: activeRotation,
                initialEvents: initialEvents,
                suggestedActionLabel: detectedAction,
                onRecordEvent: onRecordEvent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewSurface extends StatelessWidget {
  const _CameraPreviewSurface({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _VideoOverlayChip extends StatelessWidget {
  const _VideoOverlayChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ReplaySourcePill extends StatelessWidget {
  const _ReplaySourcePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.autoSpeak, required this.isListening});

  final bool autoSpeak;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.mic_rounded : Icons.record_voice_over_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isListening
                  ? 'Listening for the next question...'
                  : 'Ask your first live coaching question or start live video scouting.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              autoSpeak
                  ? 'Responses and high-priority alerts will speak automatically.'
                  : 'Auto-speak is off, so you can tap play on AI messages when needed.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onPlay});

  final ChatMessage message;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCoach = message.role == 'coach';
    final bubbleColor = isCoach
        ? theme.colorScheme.primary.withValues(alpha: 0.92)
        : theme.brightness == Brightness.dark
        ? const Color(0xFF0D1823)
        : Colors.white;
    final textColor = isCoach ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isCoach ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCoach
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: isCoach
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isCoach)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeBadge(mode: message.mode),
                    const SizedBox(width: 8),
                    _ConfidenceDot(confidence: message.confidence ?? 0),
                  ],
                ),
              if (!isCoach) const SizedBox(height: 10),
              Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
              ),
              if (!isCoach && onPlay != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: onPlay,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text('Play', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (emoji, label, color) = switch (mode) {
      'timeout' => ('🔴', 'TIMEOUT', const Color(0xFFEF4444)),
      'debrief' => ('📊', 'DEBRIEF', const Color(0xFF2563EB)),
      'drill' => ('🏋️', 'DRILL', const Color(0xFFF97316)),
      _ => ('🟢', 'LIVE', const Color(0xFF22C55E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$emoji $label',
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  const _ConfidenceDot({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final color = confidence > 0.7
        ? const Color(0xFF22C55E)
        : confidence > 0.4
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return Container(
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isListening,
    required this.pulseController,
    required this.onSend,
    required this.onMicTap,
    required this.onTimeout,
  });

  final TextEditingController controller;
  final bool isListening;
  final AnimationController pulseController;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback onTimeout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: 'Type a question...',
              suffixIcon: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ScaleTransition(
          scale: pulseController,
          child: InkWell(
            onTap: onMicTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: isListening
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onTimeout,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'TO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.onDismiss});

  final CoachingAlert alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (alert.priority) {
      AlertPriority.critical => (const Color(0xFF7F1D1D), Colors.white),
      AlertPriority.high => (const Color(0xFF9A3412), Colors.white),
      AlertPriority.medium => (const Color(0xFF1D4ED8), Colors.white),
      AlertPriority.low => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurface,
      ),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alert.priority.name.toUpperCase()}: ${alert.title}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveVideoUiState {
  const _LiveVideoUiState({
    this.availableCameras = const [],
    this.cameraError,
    this.isCameraReady = false,
    this.isStartingCamera = false,
    this.isAnalyzingFrame = false,
    this.isAutoScoutEnabled = false,
  });

  final List<CameraDescription> availableCameras;
  final String? cameraError;
  final bool isCameraReady;
  final bool isStartingCamera;
  final bool isAnalyzingFrame;
  final bool isAutoScoutEnabled;

  _LiveVideoUiState copyWith({
    List<CameraDescription>? availableCameras,
    Object? cameraError = _liveVideoUiErrorSentinel,
    bool? isCameraReady,
    bool? isStartingCamera,
    bool? isAnalyzingFrame,
    bool? isAutoScoutEnabled,
  }) {
    return _LiveVideoUiState(
      availableCameras: availableCameras ?? this.availableCameras,
      cameraError: identical(cameraError, _liveVideoUiErrorSentinel)
          ? this.cameraError
          : cameraError as String?,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isStartingCamera: isStartingCamera ?? this.isStartingCamera,
      isAnalyzingFrame: isAnalyzingFrame ?? this.isAnalyzingFrame,
      isAutoScoutEnabled: isAutoScoutEnabled ?? this.isAutoScoutEnabled,
    );
  }
}

const _liveVideoUiErrorSentinel = Object();
