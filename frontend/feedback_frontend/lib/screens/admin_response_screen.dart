import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class AdminResponseScreen extends StatefulWidget {
  const AdminResponseScreen({super.key});

  @override
  State<AdminResponseScreen> createState() => _AdminResponseScreenState();
}

class _AdminResponseScreenState extends State<AdminResponseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _feedbackIdController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool isLoading = false;
  List<dynamic> responses = [];
  String errorMessage = '';
  String successMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchResponses();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchResponses() async {
    final token = await getToken();
    final url = Uri.parse('${getBaseUrl()}/response/list/');

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          responses = data['data'];
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load responses.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createResponse() async {
    final token = await getToken();
    final url = Uri.parse('${getBaseUrl()}/response/create/');

    if (_feedbackIdController.text.isEmpty || _contentController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all fields.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'feedback': _feedbackIdController.text,
          'content': _contentController.text,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          successMessage = 'Response created successfully!';
          _feedbackIdController.clear();
          _contentController.clear();
        });
        fetchResponses();
      } else {
        setState(() {
          errorMessage = 'Failed to create response.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackIdController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'View Responses'),
                Tab(text: 'Create Response'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildViewResponsesTab(),
                  buildCreateResponseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildViewResponsesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (responses.isEmpty) {
      return const Center(child: Text('No responses available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        final item = responses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(item['content'] ?? ''),
            subtitle: Text('Feedback ID: ${item['feedback'] ?? ''}'),
          ),
        );
      },
    );
  }

  Widget buildCreateResponseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const FlutterLogo(size: 80),
          const SizedBox(height: 20),
          Text(
            'Create a Response',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 30),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child:
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ),
          if (successMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(successMessage,
                  style: const TextStyle(color: Colors.green)),
            ),
          TextField(
            controller: _feedbackIdController,
            decoration: const InputDecoration(
              labelText: 'Feedback ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.feedback),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Response Content',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : createResponse,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT'),
            ),
          ),
        ],
      ),
    );
  }
}
