import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class FeedbackSubmissionScreen extends StatefulWidget {
  const FeedbackSubmissionScreen({super.key});

  @override
  State<FeedbackSubmissionScreen> createState() =>
      _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final TextEditingController feedbackController = TextEditingController();
  double starRating = 0;
  String selectedCategory = "Complaint";
  bool isRecording = false;
  bool showNotification = false;
  bool isSubmitting = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String _speechError = '';
  List<PlatformFile> attachedFiles = [];

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  String get apiUrl => "${getBaseUrl()}/feedback/create/";

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) => _initSpeech());
  }

  Future<void> _checkPermissions() async {
    try {
      // Check microphone permission
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
        if (micStatus != PermissionStatus.granted) {
          if (mounted) {
            setState(() {
              _speechAvailable = false;
              _speechError = 'Microphone permission denied';
            });
          }
          return;
        }
      }
      // Check storage permissions
      if (Platform.isAndroid) {
        // For Android 10+, we need to request storage permission
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        // For Android 13+, we need to request media permissions
        if (await _isAndroid13OrHigher()) {
          var photosStatus = await Permission.photos.status;
          if (!photosStatus.isGranted) {
            photosStatus = await Permission.photos.request();
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, we need photo library permission
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechError = 'Permission check failed: ${e.toString()}';
        });
      }
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        final versionString = Platform.operatingSystemVersion;
        final versionMatch = RegExp(r'\d+').firstMatch(versionString);
        if (versionMatch != null && versionMatch.group(0) != null) {
          final version = int.tryParse(versionMatch.group(0)!) ?? 0;
          return version >= 13;
        }
      } catch (e) {
        debugPrint('Error checking Android version: $e');
      }
    }
    return false;
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (String status) {
          if (mounted) {
            setState(() {
              if (status == 'notListening') {
                isRecording = false;
              }
              _speechError = status == 'done' ? '' : _speechError;
            });
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              isRecording = false;
              _speechError = 'Error: ${errorNotification.errorMsg}';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
          _speechError = available ? '' : 'Speech recognition unavailable';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _speechError = 'Failed to initialize speech recognition';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showSnackBar(_speechError);
      return;
    }

    setState(() {
      isRecording = true;
      _speechError = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted && result.finalResult) {
            setState(() {
              feedbackController.text = result.recognizedWords;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isRecording = false;
          _speechError = 'Failed to start listening';
        });
        _showSnackBar(_speechError);
      }
    }
  }

  void _stopListening() {
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
      if (mounted) {
        setState(() => isRecording = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isRecording = false;
          _speechError = 'Error stopping speech recognition';
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      // Check storage permission again before picking files
      if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
          if (await Permission.storage.isDenied) {
            _showSnackBar('Storage permission required to attach files');
            return;
          }
        }
      } else if (Platform.isIOS) {
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
          if (await Permission.photos.isDenied) {
            _showSnackBar('Photo library access required to attach files');
            return;
          }
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'mp4',
          'mp3',
          'wav',
          'pdf',
          'doc',
          'docx'
        ],
        allowMultiple: true,
      );

      if (result != null && mounted) {
        setState(() => attachedFiles.addAll(result.files));
        _showSnackBar('${result.files.length} file(s) attached');
      }
    } catch (e) {
      _showSnackBar('Error picking files: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    if (mounted) {
      setState(() => attachedFiles.removeAt(index));
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      _showSnackBar('Error accessing authentication token');
      return null;
    }
  }

  Future<void> _submitFeedback() async {
    if (isSubmitting) return;

    final token = await _getToken();
    if (token == null) {
      _showSnackBar('You need to login first');
      return;
    }

    String feedback = feedbackController.text.trim();
    if (feedback.isEmpty) {
      _showSnackBar('Please provide feedback text');
      return;
    }

    if (starRating == 0) {
      _showSnackBar('Please provide a rating');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['feedback_text'] = feedback;
      request.fields['rating'] = starRating.toString();
      request.fields['category'] = selectedCategory;

      for (var file in attachedFiles) {
        String fileName = file.name;
        String extension = path.extension(fileName).toLowerCase();
        String contentType = _getContentType(extension);
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments',
              file.bytes!,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        } else if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments',
              file.path!,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        }
      }

      var response = await http.Response.fromStream(await request.send());
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        _showSnackBar(responseData['message']?.toString() ??
            'Feedback submitted successfully');
        if (mounted) {
          setState(() {
            feedbackController.clear();
            starRating = 0;
            selectedCategory = "Complaint";
            attachedFiles.clear();
            showNotification = true;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => showNotification = false);
          });
        }
      } else {
        _showSnackBar(
            responseData['error']?.toString() ?? 'Failed to submit feedback');
      }
    } catch (error) {
      _showSnackBar('Error: Could not submit feedback - ${error.toString()}');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Rate Your Experience:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                  5,
                  (index) => IconButton(
                        icon: Icon(
                          Icons.star,
                          color:
                              index < starRating ? Colors.amber : Colors.grey,
                          size: 40,
                        ),
                        onPressed: () => setState(() => starRating = index + 1),
                      )),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Tooltip(
                  message:
                      _speechError.isNotEmpty ? _speechError : 'Voice input',
                  child: IconButton(
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    color: isRecording
                        ? Colors.red
                        : _speechAvailable
                            ? Colors.blue
                            : Colors.grey,
                    iconSize: 40,
                    onPressed: _speechAvailable
                        ? () =>
                            isRecording ? _stopListening() : _startListening()
                        : null,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  iconSize: 40,
                  onPressed: _pickFiles,
                ),
              ],
            ),
            if (attachedFiles.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Attached Files:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: attachedFiles.length > 2 ? 120 : 60,
                child: ListView.builder(
                  itemCount: attachedFiles.length,
                  itemBuilder: (context, index) {
                    final file = attachedFiles[index];
                    return ListTile(
                      leading: Icon(_getFileIcon(file)),
                      title: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeFile(index),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Feedback Category:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ['Complaint', 'Suggestion', 'Praise']
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isSubmitting ? null : _submitFeedback,
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'SUBMIT FEEDBACK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (showNotification)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Thank you! Your feedback has been submitted.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image;
    if (ext == 'mp4') return Icons.videocam;
    if (['mp3', 'wav'].contains(ext)) return Icons.audiotrack;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  @override
  void dispose() {
    feedbackController.dispose();
    _speech.cancel();
    super.dispose();
  }
}
