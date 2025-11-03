import '../services/supabase_service.dart';

class ServiceProviderService {
  static final ServiceProviderService _instance = ServiceProviderService._internal();
  factory ServiceProviderService() => _instance;
  ServiceProviderService._internal();

  static ServiceProviderService get instance => _instance;

  // Get all service providers
  Future<List<Map<String, dynamic>>> getAllServiceProviders() async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch service providers: $e');
    }
  }

  // Get service providers by category
  Future<List<Map<String, dynamic>>> getServiceProvidersByCategory(String category) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .select('*')
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch service providers by category: $e');
    }
  }

  // Search service providers
  Future<List<Map<String, dynamic>>> searchServiceProviders(String query) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search service providers: $e');
    }
  }

  // Add new service provider
  Future<Map<String, dynamic>> addServiceProvider({
    required String name,
    required String category,
    required String description,
    required String location,
    required String contactEmail,
    required String contactPhone,
    String? website,
    List<String>? services,
    Map<String, dynamic>? pricing,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .insert({
            'name': name,
            'category': category,
            'description': description,
            'location': location,
            'contact_email': contactEmail,
            'contact_phone': contactPhone,
            'website': website,
            'services': services,
            'pricing': pricing,
            'status': 'pending',
            'rating': 0.0,
            'review_count': 0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to add service provider: $e');
    }
  }

  // Update service provider
  Future<Map<String, dynamic>> updateServiceProvider(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to update service provider: $e');
    }
  }

  // Delete service provider
  Future<void> deleteServiceProvider(String id) async {
    try {
      await SupabaseService.instance.client
          .from('service_providers')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete service provider: $e');
    }
  }

  // Approve service provider
  Future<Map<String, dynamic>> approveServiceProvider(String id) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to approve service provider: $e');
    }
  }

  // Reject service provider
  Future<Map<String, dynamic>> rejectServiceProvider(String id, String reason) async {
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'rejected_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to reject service provider: $e');
    }
  }

  // Get service provider statistics
  Future<Map<String, dynamic>> getServiceProviderStats() async {
    try {
      final totalResponse = await SupabaseService.instance.client
          .from('service_providers')
          .select('id')
          .count();
      
      final approvedResponse = await SupabaseService.instance.client
          .from('service_providers')
          .select('id')
          .eq('status', 'approved')
          .count();
      
      final pendingResponse = await SupabaseService.instance.client
          .from('service_providers')
          .select('id')
          .eq('status', 'pending')
          .count();
      
      final rejectedResponse = await SupabaseService.instance.client
          .from('service_providers')
          .select('id')
          .eq('status', 'rejected')
          .count();
      
      return {
        'total': totalResponse.count,
        'approved': approvedResponse.count,
        'pending': pendingResponse.count,
        'rejected': rejectedResponse.count,
      };
    } catch (e) {
      throw Exception('Failed to get service provider statistics: $e');
    }
  }

  // Get available categories
  List<String> getAvailableCategories() {
    return [
      'transport',
      'hotels',
      'tours',
      'restaurants',
      'car_rental',
      'activities',
      'guides',
      'other',
    ];
  }

  // Get category display names
  Map<String, String> getCategoryDisplayNames() {
    return {
      'transport': 'Transportation',
      'hotels': 'Hotels & Accommodation',
      'tours': 'Tours & Experiences',
      'restaurants': 'Restaurants & Dining',
      'car_rental': 'Car Rental',
      'activities': 'Activities & Recreation',
      'guides': 'Tour Guides',
      'other': 'Other Services',
    };
  }

  // Get status display names
  Map<String, String> getStatusDisplayNames() {
    return {
      'pending': 'Pending Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'suspended': 'Suspended',
    };
  }

  // Get status colors
  Map<String, String> getStatusColors() {
    return {
      'pending': 'orange',
      'approved': 'green',
      'rejected': 'red',
      'suspended': 'grey',
    };
  }
}