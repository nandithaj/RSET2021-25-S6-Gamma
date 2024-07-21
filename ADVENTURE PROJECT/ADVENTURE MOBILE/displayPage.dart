import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'screendata.dart'; // Import your ScreenIdProvider class

class DisplayAdImage extends StatefulWidget {
  const DisplayAdImage({Key? key}) : super(key: key);

  @override
  _DisplayAdImageState createState() => _DisplayAdImageState();
}

class _DisplayAdImageState extends State<DisplayAdImage> {
  String? _videoUrl;
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAd();
    // Start a timer to check for changes in the ad every minute
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchAd();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchAd() async {
    final screenData = Provider.of<ScreenIdProvider>(context, listen: false);
    final screenId = screenData.screenId;
    
    if (screenId == null) return; // Handle no screen ID

    final Uri url = Uri.parse('http://192.168.1.4:5000/get-ad/$screenId'); // Replace with your backend URL
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newVideoUrl = data['videoUrl'] as String?;
      
      setState(() {
        if (newVideoUrl != null && newVideoUrl != _videoUrl) {
          _videoUrl = newVideoUrl;
          _controller?.dispose(); // Dispose the existing controller if it exists
          _controller = VideoPlayerController.network('http://192.168.1.4:8080/$_videoUrl');
          _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
            _controller!.setLooping(true);
            _controller!.play();
            setState(() {}); // Ensure the first frame is shown
          }).catchError((error) {
            print('Error initializing video player: $error');
            setState(() {
              _controller = null;
              _initializeVideoPlayerFuture = null;
            });
          });
        } else if (newVideoUrl == null) {
          _videoUrl = null;
          _controller?.dispose();
          _controller = null;
          _initializeVideoPlayerFuture = null;
        }
      });
    } else {
      print('Failed to fetch ad: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color.fromARGB(255, 0, 0, 0),
      
      body: Center(
        child: _videoUrl == null
            ? Text('No video available')
            : _controller != null && _initializeVideoPlayerFuture != null
                ? FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (_controller != null && _controller!.value.isInitialized) {
                          return AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          );
                        } else {
                          return Text('Failed to initialize video player');
                        }
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  )
                : CircularProgressIndicator(),
      ),
      floatingActionButton: _controller != null && _controller!.value.isInitialized
          ? FloatingActionButton(
              onPressed: () {
                if (_controller != null) {
                  setState(() {
                    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                  });
                }
              },
              child: Icon(
                _controller != null && _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}