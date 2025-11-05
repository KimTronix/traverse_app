import '../services/supabase_service.dart';

class AttractionsService {
  static final AttractionsService _instance = AttractionsService._internal();
  factory AttractionsService() => _instance;
  AttractionsService._internal();

  static AttractionsService get instance => _instance;

  // Get all attractions (admin view)
  Future<List<Map<String, dynamic>>> getAllAttractions() async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch attractions: $e');
    }
  }

  // Get attractions by owner (business owner view)
  Future<List<Map<String, dynamic>>> getAttractionsByOwner(String ownerId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch owner attractions: $e');
    }
  }

  // Get attractions by category
  Future<List<Map<String, dynamic>>> getAttractionsByCategory(String category) async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch attractions by category: $e');
    }
  }

  // Search attractions
  Future<List<Map<String, dynamic>>> searchAttractions(String query) async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search attractions: $e');
    }
  }

  // Add new attraction
  Future<Map<String, dynamic>> addAttraction({
    required String name,
    required String category,
    required String description,
    required String location,
    String? ownerId,
    String? address,
    double? latitude,
    double? longitude,
    String? contactEmail,
    String? contactPhone,
    String? website,
    List<String>? images,
    Map<String, dynamic>? openingHours,
    double? entryFee,
    String? currency,
    String? priceRange,
    List<String>? amenities,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .insert({
            'name': name,
            'category': category,
            'description': description,
            'location': location,
            if (ownerId != null) 'owner_id': ownerId,
            if (address != null) 'address': address,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (contactEmail != null) 'contact_email': contactEmail,
            if (contactPhone != null) 'contact_phone': contactPhone,
            if (website != null) 'website': website,
            if (images != null) 'images': images,
            if (openingHours != null) 'opening_hours': openingHours,
            if (entryFee != null) 'entry_fee': entryFee,
            if (currency != null) 'currency': currency,
            if (priceRange != null) 'price_range': priceRange,
            if (amenities != null) 'amenities': amenities,
            // Don't set these - let database defaults handle them:
            // rating: 0.0 (DB DEFAULT)
            // review_count: 0 (DB DEFAULT)
            // status: 'pending' (DB DEFAULT)
            // created_at: NOW() (DB DEFAULT)
            // updated_at: NOW() (DB DEFAULT)
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add attraction: $e');
    }
  }

  // Update attraction
  Future<Map<String, dynamic>> updateAttraction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('attractions')
          .update(updates)  // Database trigger automatically sets updated_at
          .eq('id', id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update attraction: $e');
    }
  }

  // Delete attraction
  Future<void> deleteAttraction(String id) async {
    try {
      await SupabaseService.instance.client
          .from('attractions')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete attraction: $e');
    }
  }

  // Get attraction statistics
  Future<Map<String, dynamic>> getAttractionStatistics() async {
    try {
      final allAttractions = await getAllAttractions();
      
      final stats = <String, dynamic>{
        'total_attractions': allAttractions.length,
        'by_category': <String, int>{},
        'by_status': <String, int>{},
        'average_rating': 0.0,
        'total_reviews': 0,
      };
      
      // Calculate category distribution
      for (final attraction in allAttractions) {
        final category = attraction['category'] as String? ?? 'unknown';
        stats['by_category'][category] = (stats['by_category'][category] ?? 0) + 1;
        
        final status = attraction['status'] as String? ?? 'unknown';
        stats['by_status'][status] = (stats['by_status'][status] ?? 0) + 1;
      }
      
      // Calculate average rating and total reviews
      double totalRating = 0.0;
      int totalReviews = 0;
      int ratedAttractions = 0;
      
      for (final attraction in allAttractions) {
        final rating = attraction['rating'] as double? ?? 0.0;
        final reviewCount = attraction['review_count'] as int? ?? 0;
        
        if (rating > 0) {
          totalRating += rating;
          ratedAttractions++;
        }
        totalReviews += reviewCount;
      }
      
      stats['average_rating'] = ratedAttractions > 0 ? totalRating / ratedAttractions : 0.0;
      stats['total_reviews'] = totalReviews;
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get attraction statistics: $e');
    }
  }

  // Get available categories
  List<String> getAvailableCategories() {
    return [
      'food',
      'culture',
      'sites',
      'game_parks',
      'recreation',
      'nature',
      'shopping',
      'entertainment',
      'religious',
      'historical',
      'other',
    ];
  }

  // Get category display names
  Map<String, String> getCategoryDisplayNames() {
    return {
      'food': 'Food & Dining',
      'culture': 'Culture & Arts',
      'sites': 'Historical Sites',
      'game_parks': 'Game Parks & Wildlife',
      'recreation': 'Recreation & Sports',
      'nature': 'Nature & Parks',
      'shopping': 'Shopping',
      'entertainment': 'Entertainment',
      'religious': 'Religious Sites',
      'historical': 'Historical Landmarks',
      'other': 'Other Attractions',
    };
  }

  // Get status display names
  Map<String, String> getStatusDisplayNames() {
    return {
      'active': 'Active',
      'inactive': 'Inactive',
      'pending': 'Pending Review',
      'suspended': 'Suspended',
    };
  }

  // Get category colors
  Map<String, String> getCategoryColors() {
    return {
      'food': 'orange',
      'culture': 'purple',
      'sites': 'blue',
      'game_parks': 'green',
      'recreation': 'red',
      'nature': 'teal',
      'shopping': 'pink',
      'entertainment': 'indigo',
      'religious': 'amber',
      'historical': 'brown',
      'other': 'grey',
    };
  }
}