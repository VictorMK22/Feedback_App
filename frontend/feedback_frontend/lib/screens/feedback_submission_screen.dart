import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Renamed import to avoid ambiguity
import 'package:feedback_frontend/screens/auth/login_screen.dart'
    as auth_screens;

class FeedbackSubmissionScreen extends StatefulWidget {
  const FeedbackSubmissionScreen({super.key});

  @override
  State<FeedbackSubmissionScreen> createState() =>
      _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final TextEditingController feedbackController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  double starRating = 0;
  String selectedCategory = "Complaint";
  bool isRecording = false;
  bool showNotification = false;
  bool isSubmitting = false;
  bool _speechAvailable = false;
  String _speechError = '';
  List<PlatformFile> attachedFiles = [];

  String get apiUrl => '${_getBaseUrl()}/feedback/create/';

  String _getBaseUrl() {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://localhost:8000';
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        setState(() => _speechError = 'Microphone permission denied');
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => setState(() => _speechError = error.errorMsg),
      );

      setState(() {
        _speechAvailable = available;
        _speechError = available ? '' : 'Speech recognition not available';
      });
    } catch (e) {
      setState(() {
        _speechAvailable = false;
        _speechError = 'Failed to initialize speech: ${e.toString()}';
      });
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
          if (result.finalResult && mounted) {
            setState(() => feedbackController.text = result.recognizedWords);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isRecording = false;
          _speechError = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      setState(() => isRecording = false);
    } catch (e) {
      setState(() {
        isRecording = false;
        _speechError = 'Error stopping: ${e.toString()}';
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackBar('Storage permission required');
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          _showSnackBar('Photo library access required');
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
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

  Future<void> _submitFeedback() async {
    if (isSubmitting) return;

    final token = await _getToken();
    if (token == null) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => auth_screens.LoginScreen()),
      );
      return;
    }

    final feedback = feedbackController.text.trim();
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
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['feedback_text'] = feedback
        ..fields['rating'] = starRating.toString()
        ..fields['category'] = selectedCategory;

      for (final file in attachedFiles) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'attachments',
            file.bytes!,
            filename: file.name,
            contentType:
                MediaType.parse(_getContentType(path.extension(file.name))),
          ));
        } else if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'attachments',
            file.path!,
            filename: file.name,
            contentType:
                MediaType.parse(_getContentType(path.extension(file.name))),
          ));
        }
      }

      final response = await http.Response.fromStream(await request.send());
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        _showSuccessNotification();
        _resetForm();
      } else {
        _showSnackBar(responseData['error']?.toString() ?? 'Submission failed');
      }
    } catch (error) {
      _showSnackBar('Error: ${error.toString()}');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showSuccessNotification() {
    setState(() => showNotification = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showNotification = false);
    });
  }

  void _resetForm() {
    feedbackController.clear();
    setState(() {
      starRating = 0;
      selectedCategory = "Complaint";
      attachedFiles.clear();
    });
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
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

  IconData _getFileIcon(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image;
    if (ext == 'mp4') return Icons.videocam;
    if (['mp3', 'wav'].contains(ext)) return Icons.audiotrack;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      _showSnackBar('Error accessing token');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    feedbackController.dispose();
    _speech.cancel();
    super.dispose();
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
                IconButton(
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  color: isRecording
                      ? Colors.red
                      : _speechAvailable
                          ? Colors.blue
                          : Colors.grey,
                  iconSize: 40,
                  onPressed: _speechAvailable
                      ? () => isRecording ? _stopListening() : _startListening()
                      : () {
                          _initSpeech();
                          _showSnackBar('Initializing speech...');
                        },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  iconSize: 40,
                  onPressed: _pickFiles,
                ),
              ],
            ),
            if (_speechError.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _speechError,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (attachedFiles.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Attached Files:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: attachedFiles.length > 2 ? 120 : 60,
                child: ListView.builder(
                  itemCount: attachedFiles.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(_getFileIcon(attachedFiles[index])),
                    title: Text(
                      attachedFiles[index].name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => attachedFiles.removeAt(index)),
                    ),
                  ),
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
            if (showNotification) ...[
              const SizedBox(height: 20),
              Container(
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
            ],
          ],
        ),
      ),
    );
  }
}
