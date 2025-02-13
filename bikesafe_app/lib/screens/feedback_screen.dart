//bikesafe_app/lib/screens/feedback_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late String userId; // Store the userId here
  late String token;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the userId from arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    userId = args['userId'] as String;
    token = args['token'] as String; // Retrieve token
    print('UserId received in FeedbackScreen: $userId');
    print('Token received in FeedbackScreen: $token');  }

  void _submitFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feedback = _feedbackController.text.trim();

      if (feedback.isEmpty) {
        throw Exception('Feedback cannot be empty');
      }

      final isSuccess = await ApiService.submitFeedback(userId, feedback,token);
      if (isSuccess) {
        print('Feedback submitted successfully'); // Debugging print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully')),
        );
        _feedbackController.clear(); // Clear the input after success
      }
    } catch (e) {
      print('Error submitting feedback: $e'); // Debugging print
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                labelText: 'Your Feedback',
                errorText: _errorMessage,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submitFeedback,
                child: Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }
}