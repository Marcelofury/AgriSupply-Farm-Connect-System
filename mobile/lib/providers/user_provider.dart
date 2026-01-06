import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

enum UsersStatus {
  initial,
  loading,
  loaded,
  error,
}

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UsersStatus _status = UsersStatus.initial;
  List<UserModel> _users = [];
  List<UserModel> _farmers = [];
  List<UserModel> _buyers = [];
  UserModel? _selectedUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Filters
  String? _selectedRole;
  String? _selectedRegion;
  bool? _verifiedOnly;
  bool? _premiumOnly;
  String _searchQuery = '';

  // Statistics
  int _totalUsers = 0;
  int _totalFarmers = 0;
  int _totalBuyers = 0;
  int _totalAdmins = 0;
  int _verifiedUsers = 0;
  int _premiumUsers = 0;

  // Getters
  UsersStatus get status => _status;
  List<UserModel> get users => _filterUsers(_users);
  List<UserModel> get farmers => _farmers;
  List<UserModel> get buyers => _buyers;
  UserModel? get selectedUser => _selectedUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get selectedRole => _selectedRole;
  String? get selectedRegion => _selectedRegion;
  bool? get verifiedOnly => _verifiedOnly;
  bool? get premiumOnly => _premiumOnly;
  String get searchQuery => _searchQuery;

  int get totalUsers => _totalUsers;
  int get totalFarmers => _totalFarmers;
  int get totalBuyers => _totalBuyers;
  int get totalAdmins => _totalAdmins;
  int get verifiedUsers => _verifiedUsers;
  int get premiumUsers => _premiumUsers;

  // Fetch all users (admin)
  Future<void> fetchAllUsers() async {
    _status = UsersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      _calculateStats();
      _status = UsersStatus.loaded;
    } catch (e) {
      _status = UsersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch farmers
  Future<void> fetchFarmers({String? region}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmers = await _userService.getFarmers(region: region);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Fetch buyers
  Future<void> fetchBuyers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _buyers = await _userService.getBuyers();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Get user by ID
  Future<void> fetchUserById(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await _userService.getUserById(userId);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Search users
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.searchUsers(query);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Verify user (admin)
  Future<bool> verifyUser(String userId) async {
    _errorMessage = null;

    try {
      await _userService.verifyUser(userId);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isVerified: true);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isVerified: true);
      }

      _verifiedUsers = _users.where((u) => u.isVerified).length;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Suspend user (admin)
  Future<bool> suspendUser(String userId, {String? reason}) async {
    _errorMessage = null;

    try {
      await _userService.suspendUser(userId, reason: reason);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isSuspended: true);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isSuspended: true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unsuspend user (admin)
  Future<bool> unsuspendUser(String userId) async {
    _errorMessage = null;

    try {
      await _userService.unsuspendUser(userId);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isSuspended: false);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isSuspended: false);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete user (admin)
  Future<bool> deleteUser(String userId) async {
    _errorMessage = null;

    try {
      await _userService.deleteUser(userId);

      _users.removeWhere((u) => u.id == userId);
      _farmers.removeWhere((u) => u.id == userId);
      _buyers.removeWhere((u) => u.id == userId);

      if (_selectedUser?.id == userId) {
        _selectedUser = null;
      }

      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update user role (admin)
  Future<bool> updateUserRole(String userId, String newRole) async {
    _errorMessage = null;

    try {
      await _userService.updateUserRole(userId, newRole);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(userType: newRole);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(userType: newRole);
      }

      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Upgrade user to premium
  Future<bool> upgradeToPremium(String userId) async {
    _errorMessage = null;

    try {
      await _userService.upgradeToPremium(userId);

      final index = _users.indexWhere((u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isPremium: true);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isPremium: true);
      }

      _premiumUsers = _users.where((u) => u.isPremium).length;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter users based on current filters
  List<UserModel> _filterUsers(List<UserModel> users) {
    var filtered = users;

    // Filter by role
    if (_selectedRole != null) {
      filtered = filtered.where((u) => u.role == _selectedRole).toList();
    }

    // Filter by region
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      filtered = filtered.where((u) => u.region == _selectedRegion).toList();
    }

    // Filter by verified status
    if (_verifiedOnly == true) {
      filtered = filtered.where((u) => u.isVerified).toList();
    }

    // Filter by premium status
    if (_premiumOnly == true) {
      filtered = filtered.where((u) => u.isPremium).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        return u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.phone?.toLowerCase().contains(query) ?? false) ||
            (u.farmName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  // Set filters
  void setRoleFilter(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setRegionFilter(String? region) {
    _selectedRegion = region;
    notifyListeners();
  }

  void setVerifiedFilter(bool? verified) {
    _verifiedOnly = verified;
    notifyListeners();
  }

  void setPremiumFilter(bool? premium) {
    _premiumOnly = premium;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedRole = null;
    _selectedRegion = null;
    _verifiedOnly = null;
    _premiumOnly = null;
    _searchQuery = '';
    notifyListeners();
  }

  void _calculateStats() {
    _totalUsers = _users.length;
    _totalFarmers = _users.where((u) => u.role == UserRole.farmer).length;
    _totalBuyers = _users.where((u) => u.role == UserRole.buyer).length;
    _totalAdmins = _users.where((u) => u.role == UserRole.admin).length;
    _verifiedUsers = _users.where((u) => u.isVerified).length;
    _premiumUsers = _users.where((u) => u.isPremium).length;
  }

  void setSelectedUser(UserModel? user) {
    _selectedUser = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get users by role
  List<UserModel> getUsersByRole(String role) {
    return _users.where((u) => u.role == role).toList();
  }

  // Get user statistics by region
  Map<String, int> getUsersByRegion() {
    final Map<String, int> regionCounts = {};
    
    for (final user in _users) {
      if (user.region != null) {
        regionCounts[user.region!] = (regionCounts[user.region!] ?? 0) + 1;
      }
    }
    
    return regionCounts;
  }
}
