import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_models.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

class ComplaintService {
  final AuthService _authService = AuthService();

  Future<Complaint> createComplaint(String description, {int? bookingId}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> body = {
      'description': description,
      'category': 'other', // API expects a category in ComplaintCreate. We provide a default one. Or maybe backend ignores it if AI classifies it? Wait, ComplaintCreate extends ComplaintBase which requires category. Let's send 'other' as default.
    };
    if (bookingId != null) {
      body['booking_id'] = bookingId;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/complaints/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Complaint.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create complaint: ${response.body}');
    }
  }

  Future<List<Complaint>> getCustomerComplaints() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/complaints/customer'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Complaint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load customer complaints');
    }
  }

  Future<List<Complaint>> getAdminComplaints() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/complaints/admin'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Complaint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load admin complaints');
    }
  }

  Future<Complaint> updateComplaintStatus(int complaintId, String status, {String? resolutionNotes}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> body = {'status': status};
    if (resolutionNotes != null) {
      body['resolution_notes'] = resolutionNotes;
    }

    final response = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/complaints/admin/$complaintId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Complaint.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update complaint status');
    }
  }
}
