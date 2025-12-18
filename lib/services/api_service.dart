import 'dart:convert';

import 'package:http/http.dart' as http;

/// Simple REST API service using JSONPlaceholder.
class ApiService {
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<Map<String, dynamic>>> fetchSamplePosts() async {
    final uri = Uri.parse('$_baseUrl/posts?_limit=10');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}


