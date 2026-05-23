import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  bool get isInitialized => _client != null;
  String? get userId => _client?.auth.currentUser?.id;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase has not been initialized. Please check your env.json file and ensure SUPABASE_URL and SUPABASE_ANON_KEY are provided.');
    }
    return _client!;
  }

  Future<void> initialize() async {
    try {
      final String response = await rootBundle.loadString('env.json');
      final data = await json.decode(response);
      
      final String url = data['SUPABASE_URL'] ?? '';
      final String anonKey = data['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) {
        debugPrint('Supabase URL or Anon Key is missing in env.json');
        return;
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  // Auth methods
  Future<AuthResponse> signIn(String email, String password) async {
    if (!isInitialized) throw Exception('Supabase not initialized');
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    if (!isInitialized) throw Exception('Supabase not initialized');
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Profile methods
  Future<void> createProfile(String userId, String storeName, String ownerName) async {
    if (!isInitialized) return;
    await client.from('profiles').upsert({
      'id': userId,
      'store_name': storeName,
      'owner_name': ownerName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (!isInitialized || userId == null) return null;
    return await client.from('profiles').select().eq('id', userId!).maybeSingle();
  }

  Future<void> updateProfile(String storeName, String ownerName) async {
    if (!isInitialized || userId == null) return;
    await client.from('profiles').upsert({
      'id': userId!,
      'store_name': storeName,
      'owner_name': ownerName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getProductCount() async {
    if (!isInitialized || userId == null) return 0;
    final response = await client.from('products').select().eq('user_id', userId!);
    return response.length;
  }

  // Database methods
  Future<List<Map<String, dynamic>>> getProducts() async {
    if (!isInitialized) return [];
    
    try {
      final currentUserId = userId;
      debugPrint('Fetching products for User ID: $currentUserId');
      
      var query = client.from('products').select();
      
      // If we have a userId, we filter. If not, RLS will handle it anyway.
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      }
      
      final response = await query;
      debugPrint('Fetched ${response.length} products from Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Exception in getProducts: $e');
      rethrow;
    }
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    if (!isInitialized) return;
    
    try {
      final data = Map<String, dynamic>.from(product);
      final currentUserId = userId;
      
      if (currentUserId != null) {
        data['user_id'] = currentUserId;
      }
      
      debugPrint('Adding product for User ID: $currentUserId - Data: $data');
      await client.from('products').insert(data);
      debugPrint('Product added successfully to Supabase');
    } catch (e) {
      debugPrint('Exception in addProduct: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> product) async {
    if (!isInitialized) return;
    var query = client.from('products').update(product).eq('id', id);
    if (userId != null) {
      query = query.eq('user_id', userId!);
    }
    await query;
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    if (!isInitialized) return null;
    
    var query = client.from('products').select();
    if (userId != null) {
      query = query.eq('user_id', userId!);
    }
    
    final response = await query.eq('barcode', barcode).maybeSingle();
    return response;
  }

  Future<void> deleteProduct(int id) async {
    if (!isInitialized) return;
    var query = client.from('products').delete().eq('id', id);
    if (userId != null) {
      query = query.eq('user_id', userId!);
    }
    await query;
  }
}
