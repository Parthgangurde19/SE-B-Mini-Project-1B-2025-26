import 'dart:convert';

import 'package:http/http.dart' as http;

class HackathonApiService {
  static const String _baseUrl = 'https://codeclub-api.vercel.app';
  static const String _endpoint = '/api/hackathon';

  static Future<String> askQuestion(String question) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'question': question}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['answer'] != null) {
          return data['answer'] as String;
        }
        throw Exception('Invalid response format.');
      }

      if (response.statusCode == 400) {
        throw Exception('Please enter a valid question.');
      }
      if (response.statusCode == 429) {
        throw Exception('Too many requests. Please wait a moment.');
      }
      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      throw Exception('Unexpected error: ${response.statusCode}');
    } on http.ClientException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Something went wrong. Please try again.');
    }
  }

  static Future<bool> isApiAlive() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_endpoint'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
