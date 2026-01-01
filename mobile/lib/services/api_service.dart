import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;
  
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic PATCH request
  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Handle response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      final message = body?['message'] ?? body?['error'] ?? 'Unknown error';
      throw ApiException(message, statusCode: statusCode);
    }
  }

  // Upload file to Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).uploadBinary(
        path,
        fileBytes as dynamic,
        fileOptions: FileOptions(
          contentType: contentType ?? 'application/octet-stream',
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw ApiException('Failed to upload file: ${e.toString()}');
    }
  }

  // Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw ApiException('Failed to delete file: ${e.toString()}');
    }
  }

  // Supabase query helpers
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ApiException('Query failed: ${e.toString()}');
    }
  }

  // Insert data
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw ApiException('Insert failed: ${e.toString()}');
    }
  }

  // Update data
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw ApiException('Update failed: ${e.toString()}');
    }
  }

  // Delete data
  Future<void> deleteRecord(String table, String id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
    } catch (e) {
      throw ApiException('Delete failed: ${e.toString()}');
    }
  }

  // Get single record
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      throw ApiException('Get failed: ${e.toString()}');
    }
  }

  // Subscribe to realtime changes
  RealtimeChannel subscribe(
    String table, {
    required Function(Map<String, dynamic> payload) onInsert,
    Function(Map<String, dynamic> payload)? onUpdate,
    Function(Map<String, dynamic> payload)? onDelete,
  }) {
    return _supabase
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: (payload) => onUpdate?.call(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: (payload) => onDelete?.call(payload.oldRecord),
        )
        .subscribe();
  }

  // Unsubscribe from channel
  void unsubscribe(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }
}
