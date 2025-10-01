import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sports_c/user/search/location.dart';
import 'package:sports_c/user/chat/chat_page.dart';

const Color appPrimaryColor = Color(0xFF1994DD);
const Color appSecondaryColor = Color(0xFF22C493);

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class PlayerFilter {
  final String userType;
  final String sport;
  final String position;
  final double minAge;
  final double maxAge;
  final double minHeight;
  final double maxHeight;
  final double minWeight;
  final double maxWeight;
  final String location;
  final String skillLevel;
  final String searchText;
  final LatLng? locationCoordinates;
  final double? minFee;
  final double? maxFee;
  final String? shift;

  PlayerFilter({
    required this.userType,
    required this.sport,
    required this.position,
    required this.minAge,
    required this.maxAge,
    required this.minHeight,
    required this.maxHeight,
    required this.minWeight,
    required this.maxWeight,
    required this.location,
    required this.skillLevel,
    required this.searchText,
    this.locationCoordinates,
    this.minFee,
    this.maxFee,
    this.shift,
  });
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String userType;
  final String sport;
  final String position;
  final int age;
  final double height;
  final double weight;
  final String skillLevel;
  final String location;
  final String? profileImage;
  final double? coachingFee;
  final String? shift;
  final String? experience;
  final String? qualifications;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
    required this.sport,
    required this.position,
    required this.age,
    required this.height,
    required this.weight,
    required this.skillLevel,
    required this.location,
    this.profileImage,
    this.coachingFee,
    this.shift,
    this.experience,
    this.qualifications,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    print('User Data for ${doc.id}: $data');

    String userType = 'player';
    if (data['role'] != null) {
      final role = data['role'].toString().toLowerCase();
      userType = role.contains('coach') ? 'coach' : 'player';
    } else if (data['userType'] != null) {
      userType = data['userType'].toString().toLowerCase();
    }

    String fullName = 'Unknown User';
    if (data['first_name'] != null && data['last_name'] != null) {
      fullName = '${data['first_name']} ${data['last_name']}'.trim();
    } else if (data['first_name'] != null) {
      fullName = data['first_name'].toString();
    } else if (data['name'] != null) {
      fullName = data['name'].toString();
    } else if (data['email'] != null) {
      fullName = data['email'].toString().split('@').first;
    }

    String location = 'Unknown Location';
    if (data['location_address'] != null) {
      location = data['location_address'].toString();
    } else if (data['location'] != null) {
      location = data['location'].toString();
    } else if (data['city'] != null) {
      location = data['city'].toString();
    }

    return UserProfile(
      uid: doc.id,
      name: fullName,
      email: data['email']?.toString() ?? '',
      userType: userType,
      sport: data['sport']?.toString() ?? 'General',
      position: data['position']?.toString() ??
          (userType == 'coach' ? 'Coach' : 'Player'),
      age: _parseAge(data),
      height: _parseDouble(data['height']) ??
          (userType == 'player' ? 170.0 : 0.0),
      weight: _parseDouble(data['weight']) ??
          (userType == 'player' ? 65.0 : 0.0),
      skillLevel: data['skillLevel']?.toString() ??
          data['skill_level']?.toString() ?? 'Intermediate',
      location: location,
      profileImage: data['profileImage'] ??
          data['profile_image'] ??
          data['photoURL'],
      coachingFee: _parseDouble(data['coachingFee'] ??
          data['coaching_fee'] ??
          data['fee']),
      shift: data['shift']?.toString(),
      experience: data['experience']?.toString(),
      qualifications: data['qualifications']?.toString(),
    );
  }

  static int _parseAge(Map<String, dynamic> data) {
    if (data['age'] != null) {
      if (data['age'] is int) return data['age'];
      if (data['age'] is double) return data['age'].toInt();
      if (data['age'] is String) return int.tryParse(data['age']) ?? 20;
    }
    return 20;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

abstract class SearchEvent {}

class ApplyFilter extends SearchEvent {
  final PlayerFilter filter;
  ApplyFilter(this.filter);
}

class ClearSearch extends SearchEvent {}

class SetUserType extends SearchEvent {
  final String userType;
  SetUserType(this.userType);
}

class SearchWithUserType extends SearchEvent {
  final String userType;
  SearchWithUserType(this.userType);
}

class SearchWithText extends SearchEvent {
  final String searchText;
  final String userType;
  SearchWithText(this.searchText, this.userType);
}

abstract class SearchState {}

class SearchInitial extends SearchState {
  final String? selectedUserType;
  SearchInitial({this.selectedUserType});
}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<UserProfile> users;
  final String userType;
  final String searchText;
  SearchLoaded({
    required this.users,
    required this.userType,
    this.searchText = '',
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentUserType = 'player';

  SearchBloc() : super(SearchInitial()) {
    on<ApplyFilter>((event, emit) async {
      emit(SearchLoading());
      try {
        final users = await _searchUsersOptimized(event.filter);
        emit(SearchLoaded(
          users: users,
          userType: event.filter.userType,
          searchText: event.filter.searchText,
        ));
      } catch (e) {
        print('Search failed: $e');
        emit(SearchError('Failed to search users: $e'));
      }
    });

    on<ClearSearch>((event, emit) {
      emit(SearchInitial());
    });

    on<SetUserType>((event, emit) {
      _currentUserType = event.userType;
      emit(SearchInitial(selectedUserType: event.userType));
    });

    on<SearchWithUserType>((event, emit) async {
      emit(SearchLoading());
      try {
        final users = await _searchByUserType(event.userType);
        emit(SearchLoaded(
          users: users,
          userType: event.userType,
        ));
      } catch (e) {
        print('User type search failed: $e');
        emit(SearchError('Failed to load users: $e'));
      }
    });

    on<SearchWithText>((event, emit) async {
      emit(SearchLoading());
      try {
        final users = await _searchByGameName(event.searchText, event.userType);
        emit(SearchLoaded(
          users: users,
          userType: event.userType,
          searchText: event.searchText,
        ));
      } catch (e) {
        print('Text search failed: $e');
        emit(SearchError('Failed to search users: $e'));
      }
    });
  }

  Future<List<UserProfile>> _searchByUserType(String userType) async {
    try {
      Query query = _firestore.collection('users');

      if (userType == 'player') {
        query = query.where('role', whereIn: ['Player', 'player']);
      } else if (userType == 'coach') {
        query = query.where('role', whereIn: ['Coach', 'coach']);
      }

      query = query.limit(50);

      final querySnapshot = await query.get();
      print('Found ${querySnapshot.docs.length} ${userType}s');

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<UserProfile> users = [];
      for (var doc in querySnapshot.docs) {
        try {
          final user = UserProfile.fromFirestore(doc);
          users.add(user);
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }

      return users;
    } catch (e) {
      print('User type search error: $e');
      return [];
    }
  }

  // NEW: Search by game name - FIXED VERSION
  Future<List<UserProfile>> _searchByGameName(String gameName, String userType) async {
    try {
      if (gameName.isEmpty) {
        // If search is empty, return all users of the selected type
        return await _searchByUserType(userType);
      }

      Query query = _firestore.collection('users');

      // Filter by user type first
      if (userType == 'player') {
        query = query.where('role', whereIn: ['Player', 'player']);
      } else if (userType == 'coach') {
        query = query.where('role', whereIn: ['Coach', 'coach']);
      }

      // Search for the game name in the 'sport' field (case insensitive)
      final querySnapshot = await query.get();
      print('Found ${querySnapshot.docs.length} initial ${userType}s for search: $gameName');

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<UserProfile> users = [];
      final lowerGameName = gameName.toLowerCase().trim();

      for (var doc in querySnapshot.docs) {
        try {
          final user = UserProfile.fromFirestore(doc);

          // Check if the user's sport matches the search (case insensitive)
          if (user.sport.toLowerCase().contains(lowerGameName)) {
            users.add(user);
          }
          // Also check if search matches name or position
          else if (user.name.toLowerCase().contains(lowerGameName) ||
              user.position.toLowerCase().contains(lowerGameName)) {
            users.add(user);
          }
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }

      print('After filtering: ${users.length} ${userType}s match "$gameName"');
      return users;

    } catch (e) {
      print('Game name search error: $e');
      return [];
    }
  }

  Future<List<UserProfile>> _searchUsersOptimized(PlayerFilter filter) async {
    try {
      Query query = _firestore.collection('users');

      if (filter.userType == 'player') {
        query = query.where('role', whereIn: ['Player', 'player']);
      } else if (filter.userType == 'coach') {
        query = query.where('role', whereIn: ['Coach', 'coach']);
      }

      if (filter.sport.isNotEmpty && filter.sport != 'Any') {
        query = query.where('sport', isEqualTo: filter.sport);
      }

      query = query.limit(50);

      final querySnapshot = await query.get();
      print('Found ${querySnapshot.docs.length} initial documents');

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<UserProfile> users = [];
      for (var doc in querySnapshot.docs) {
        try {
          final user = UserProfile.fromFirestore(doc);
          if (_userMatchesFilter(user, filter)) {
            users.add(user);
          }
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }

      print('After local filtering: ${users.length} users');
      return users;

    } catch (e) {
      print('Optimized search error: $e');
      return await _simpleFallbackSearch(filter);
    }
  }

  bool _userMatchesFilter(UserProfile user, PlayerFilter filter) {
    if (user.userType != filter.userType) {
      return false;
    }

    if (filter.userType == 'player' &&
        filter.position.isNotEmpty &&
        filter.position != 'Any' &&
        user.position != filter.position) {
      return false;
    }

    if (user.age < filter.minAge || user.age > filter.maxAge) {
      return false;
    }

    if (filter.userType == 'player' &&
        (user.height < filter.minHeight || user.height > filter.maxHeight)) {
      return false;
    }

    if (filter.userType == 'player' &&
        (user.weight < filter.minWeight || user.weight > filter.maxWeight)) {
      return false;
    }

    if (filter.skillLevel.isNotEmpty &&
        filter.skillLevel != 'Any' &&
        user.skillLevel != filter.skillLevel) {
      return false;
    }

    if (filter.userType == 'coach' &&
        filter.minFee != null &&
        filter.maxFee != null &&
        (user.coachingFee == null ||
            user.coachingFee! < filter.minFee! ||
            user.coachingFee! > filter.maxFee!)) {
      return false;
    }

    if (filter.userType == 'coach' &&
        filter.shift != null &&
        filter.shift!.isNotEmpty &&
        filter.shift != 'Any' &&
        user.shift != filter.shift) {
      return false;
    }

    if (filter.searchText.isNotEmpty) {
      final lowerSearch = filter.searchText.toLowerCase();
      final matchesName = user.name.toLowerCase().contains(lowerSearch);
      final matchesSport = user.sport.toLowerCase().contains(lowerSearch);
      final matchesPosition = user.position.toLowerCase().contains(lowerSearch);

      if (!matchesName && !matchesSport && !matchesPosition) {
        return false;
      }
    }

    return true;
  }

  Future<List<UserProfile>> _simpleFallbackSearch(PlayerFilter filter) async {
    try {
      final querySnapshot = await _firestore.collection('users').limit(100).get();

      List<UserProfile> allUsers = [];
      for (var doc in querySnapshot.docs) {
        try {
          allUsers.add(UserProfile.fromFirestore(doc));
        } catch (e) {
          print('Error in fallback for user ${doc.id}: $e');
        }
      }

      return allUsers.where((user) => _userMatchesFilter(user, filter)).toList();
    } catch (e) {
      print('Fallback search failed: $e');
      return [];
    }
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Smart Search'),
          centerTitle: true,
          backgroundColor: appPrimaryColor,
        ),
        body: const SafeArea(child: MainSearchContainer()),
      ),
    );
  }
}

class MainSearchContainer extends StatefulWidget {
  const MainSearchContainer({super.key});

  @override
  State<MainSearchContainer> createState() => _MainSearchContainerState();
}

class _MainSearchContainerState extends State<MainSearchContainer> {
  final List<String> sports = [
    'Any',
    'Cricket',
    'Basketball',
    'Volleyball',
    'Athletics',
    'Football',
    'Tennis',
    'Badminton',
  ];

  final List<String> skillLevels = ['Any', 'Beginner', 'Intermediate', 'Advanced'];
  final List<String> shifts = ['Any', 'Morning', 'Afternoon', 'Evening', 'Weekend'];

  String selectedUserType = 'player';
  String selectedSport = 'Any';
  String selectedPosition = 'Any';
  double minAge = 18;
  double maxAge = 35;
  double minHeight = 160;
  double maxHeight = 190;
  double minWeight = 50;
  double maxWeight = 90;
  double minFee = 500;
  double maxFee = 2000;
  String selectedSkillLevel = 'Any';
  String selectedShift = 'Any';
  String locationInput = 'Tirunelveli, Tamil Nadu';
  String searchText = '';

  final TextEditingController _searchController = TextEditingController();

  void _showUserTypeSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What are you looking for?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    'Player',
                    'Find sports players',
                    Icons.sports,
                    'player',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildUserTypeCard(
                    'Coach',
                    'Find professional coaches',
                    Icons.sports_score,
                    'coach',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String title, String subtitle, IconData icon, String userType) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selectedUserType == userType ? appPrimaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedUserType = userType;
            selectedSport = 'Any';
            selectedPosition = 'Any';
          });
          context.read<SearchBloc>().add(SearchWithUserType(userType));
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: appPrimaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Simple text search function
  void _performTextSearch(String enteredText) {
    if (enteredText.isNotEmpty) {
      searchText = enteredText;
      // Use the new SearchWithText event with game name search
      context.read<SearchBloc>().add(SearchWithText(enteredText, selectedUserType));
    } else {
      // If search is cleared, show all users of selected type
      _performDefaultSearch();
    }
  }

  void _openFilterDialog({required String enteredText}) async {
    searchText = enteredText;

    final lowerText = enteredText.toLowerCase();

    for (final sport in sports) {
      if (sport != 'Any' && lowerText.contains(sport.toLowerCase())) {
        selectedSport = sport;
        break;
      }
    }

    if (lowerText.contains('coach') ||
        lowerText.contains('trainer') ||
        lowerText.contains('training') ||
        lowerText.contains('coaching')) {
      selectedUserType = 'coach';
    } else if (lowerText.contains('player') || lowerText.contains('athlete')) {
      selectedUserType = 'player';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: FilterForm(
          userType: selectedUserType,
          sports: sports,
          skillLevels: skillLevels,
          shifts: shifts,
          selectedSport: selectedSport,
          selectedPosition: selectedPosition,
          minAge: minAge,
          maxAge: maxAge,
          minHeight: minHeight,
          maxHeight: maxHeight,
          minWeight: minWeight,
          maxWeight: maxWeight,
          minFee: minFee,
          maxFee: maxFee,
          selectedSkillLevel: selectedSkillLevel,
          selectedShift: selectedShift,
          locationInput: locationInput,
          searchText: searchText,
          onApply: (filter) {
            setState(() {
              selectedUserType = filter.userType;
              selectedSport = filter.sport;
              selectedPosition = filter.position;
              selectedSkillLevel = filter.skillLevel;
              selectedShift = filter.shift ?? 'Any';
              locationInput = filter.location;
            });
            context.read<SearchBloc>().add(ApplyFilter(filter));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _navigateToChatScreen(UserProfile user) {
    print('Navigating to chat with: ${user.name} (${user.uid})');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullChatPage(
          otherUserId: user.uid,
          otherUserName: user.name,
          otherUserType: user.userType,
        ),
      ),
    );
  }

  void _performDefaultSearch() {
    context.read<SearchBloc>().add(SearchWithUserType(selectedUserType));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performDefaultSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by game name (e.g. "Cricket", "Basketball", "Football")',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _openFilterDialog(enteredText: _searchController.text);
                  } else {
                    _openFilterDialog(enteredText: '');
                  }
                },
              ),
            ),
            onSubmitted: (text) {
              _performTextSearch(text);
            },
            onChanged: (text) {
              // Optional: Implement real-time search as user types
              if (text.isEmpty) {
                _performDefaultSearch();
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchInitial && state.selectedUserType != null) {
              selectedUserType = state.selectedUserType!;
            }

            String resultsText = '';
            if (state is SearchLoaded) {
              if (state.searchText.isNotEmpty) {
                resultsText = '${state.users.length} ${state.userType == 'coach' ? 'coaches' : 'players'} found for "${state.searchText}"';
              } else {
                resultsText = 'Showing ${state.users.length} ${state.userType == 'coach' ? 'coaches' : 'players'}';
              }
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      resultsText.isNotEmpty ? resultsText : 'Search for ${selectedUserType == 'coach' ? 'Coaches' : 'Players'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: appPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showUserTypeSelection,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchInitial) {
                return _buildEmptyState();
              } else if (state is SearchLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Searching...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              } else if (state is SearchLoaded) {
                return _buildUserList(state.users, state.userType, state.searchText);
              } else if (state is SearchError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading users',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _performDefaultSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appPrimaryColor,
                        ),
                        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return _buildEmptyState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Search for Players or Coaches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Use the search bar above to find ${selectedUserType == 'coach' ? 'professional coaches' : 'talented players'} for your favorite sports',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _performDefaultSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: appPrimaryColor,
            ),
            child: const Text('Show All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserProfile> users, String userType, String searchText) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchText.isNotEmpty
                  ? 'No ${userType == 'coach' ? 'coaches' : 'players'} found for "$searchText"'
                  : 'No ${userType == 'coach' ? 'coaches' : 'players'} found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performDefaultSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: appPrimaryColor,
              ),
              child: Text('Show All ${userType == 'coach' ? 'Coaches' : 'Players'}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: appPrimaryColor,
              backgroundImage: user.profileImage != null
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: user.profileImage == null
                  ? Icon(
                user.userType == 'coach' ? Icons.sports_score : Icons.sports,
                color: Colors.white,
              )
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${user.sport} • ${user.position}'),
                if (user.userType == 'coach') ...[
                  if (user.coachingFee != null)
                    Text('Fee: ₹${user.coachingFee!.toStringAsFixed(0)}/month'),
                  if (user.shift != null) Text('Shift: ${user.shift}'),
                  if (user.experience != null) Text('Exp: ${user.experience}'),
                ] else ...[
                  Text('${user.age} yrs • ${user.height}cm • ${user.weight}kg'),
                  Text('${user.skillLevel} • ${user.location}'),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.message, color: appPrimaryColor),
              onPressed: () => _navigateToChatScreen(user),
              tooltip: 'Message ${user.name}',
            ),
          ),
        );
      },
    );
  }
}

// FilterForm class remains the same as in your original code
class FilterForm extends StatefulWidget {
  final String userType;
  final List<String> sports;
  final List<String> skillLevels;
  final List<String> shifts;
  final String selectedSport;
  final String selectedPosition;
  final double minAge, maxAge, minHeight, maxHeight, minWeight, maxWeight;
  final double minFee, maxFee;
  final String selectedSkillLevel;
  final String selectedShift;
  final String locationInput;
  final String searchText;
  final Function(PlayerFilter) onApply;

  const FilterForm({
    super.key,
    required this.userType,
    required this.sports,
    required this.skillLevels,
    required this.shifts,
    required this.selectedSport,
    required this.selectedPosition,
    required this.minAge,
    required this.maxAge,
    required this.minHeight,
    required this.maxHeight,
    required this.minWeight,
    required this.maxWeight,
    required this.minFee,
    required this.maxFee,
    required this.selectedSkillLevel,
    required this.selectedShift,
    required this.locationInput,
    required this.searchText,
    required this.onApply,
  });

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  late String sport;
  late String position;
  late String skillLevel;
  late String shift;
  late TextEditingController locationCtrl;
  late TextEditingController minAgeCtrl;
  late TextEditingController maxAgeCtrl;
  late TextEditingController minHeightCtrl;
  late TextEditingController maxHeightCtrl;
  late TextEditingController minWeightCtrl;
  late TextEditingController maxWeightCtrl;
  late TextEditingController minFeeCtrl;
  late TextEditingController maxFeeCtrl;
  LatLng? _selectedLocation;

  final Map<String, List<String>> positionMap = {
    'Any': ['Any'],
    'Cricket': ['Any', 'Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'],
    'Basketball': ['Any', 'Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
    'Volleyball': ['Any', 'Setter', 'Outside Hitter', 'Middle Blocker', 'Opposite Hitter', 'Libero'],
    'Athletics': ['Any', 'Sprinter', 'Long Distance Runner', 'High Jumper', 'Thrower'],
    'Football': ['Any', 'Goalkeeper', 'Defender', 'Midfielder', 'Forward'],
    'Tennis': ['Any', 'Singles', 'Doubles'],
    'Badminton': ['Any', 'Singles', 'Doubles'],
  };

  @override
  void initState() {
    super.initState();
    sport = widget.selectedSport;
    skillLevel = widget.selectedSkillLevel;
    shift = widget.selectedShift;

    final positions = positionMap[sport] ?? ['Any'];
    position = positions.contains(widget.selectedPosition) && widget.selectedPosition != 'Any'
        ? widget.selectedPosition
        : 'Any';

    locationCtrl = TextEditingController(text: widget.locationInput);
    minAgeCtrl = TextEditingController(text: widget.minAge.toStringAsFixed(0));
    maxAgeCtrl = TextEditingController(text: widget.maxAge.toStringAsFixed(0));
    minHeightCtrl = TextEditingController(text: widget.minHeight.toStringAsFixed(0));
    maxHeightCtrl = TextEditingController(text: widget.maxHeight.toStringAsFixed(0));
    minWeightCtrl = TextEditingController(text: widget.minWeight.toStringAsFixed(0));
    maxWeightCtrl = TextEditingController(text: widget.maxWeight.toStringAsFixed(0));
    minFeeCtrl = TextEditingController(text: widget.minFee.toStringAsFixed(0));
    maxFeeCtrl = TextEditingController(text: widget.maxFee.toStringAsFixed(0));

    _selectedLocation = null;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  List<String> getCurrentPositions() {
    return positionMap[sport] ?? ['Any'];
  }

  void _updatePositionForSport(String newSport) {
    final newPositions = positionMap[newSport] ?? ['Any'];
    if (!newPositions.contains(position)) {
      setState(() {
        position = 'Any';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = getCurrentPositions();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter ${widget.userType == 'coach' ? 'Coaches' : 'Players'}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: sport,
              items: widget.sports
                  .map((sport) => DropdownMenuItem(value: sport, child: Text(sport)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sport = value;
                    _updatePositionForSport(value);
                  });
                }
              },
              decoration: _inputDecoration('Sport'),
            ),
            const SizedBox(height: 12),

            if (widget.userType == 'player')
              DropdownButtonFormField<String>(
                value: positions.contains(position) ? position : 'Any',
                items: positions
                    .map((pos) => DropdownMenuItem(value: pos, child: Text(pos)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      position = value;
                    });
                  }
                },
                decoration: _inputDecoration('Position'),
              ),

            if (widget.userType == 'player') const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: skillLevel,
              items: widget.skillLevels
                  .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    skillLevel = value;
                  });
                }
              },
              decoration: _inputDecoration('Skill Level'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: minAgeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Min Age'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: maxAgeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Max Age'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.userType == 'player') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minHeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Min Height (cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: maxHeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Max Height (cm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minWeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Min Weight (kg)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: maxWeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Max Weight (kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (widget.userType == 'coach') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Min Fee (₹/month)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: maxFeeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Max Fee (₹/month)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: shift,
                items: widget.shifts
                    .map((shift) => DropdownMenuItem(value: shift, child: Text(shift)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      shift = value;
                    });
                  }
                },
                decoration: _inputDecoration('Preferred Shift'),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: locationCtrl,
              readOnly: true,
              decoration: _inputDecoration('Location').copyWith(
                suffixIcon: Icon(Icons.location_on, color: appSecondaryColor),
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationPickerScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    locationCtrl.text = result['address'];
                    _selectedLocation = result['location'];
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [appPrimaryColor, appSecondaryColor],
                  ),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    final filter = PlayerFilter(
                      userType: widget.userType,
                      sport: sport,
                      position: position,
                      minAge: double.tryParse(minAgeCtrl.text) ?? 18,
                      maxAge: double.tryParse(maxAgeCtrl.text) ?? 35,
                      minHeight: double.tryParse(minHeightCtrl.text) ?? 160,
                      maxHeight: double.tryParse(maxHeightCtrl.text) ?? 190,
                      minWeight: double.tryParse(minWeightCtrl.text) ?? 50,
                      maxWeight: double.tryParse(maxWeightCtrl.text) ?? 90,
                      location: locationCtrl.text,
                      skillLevel: skillLevel,
                      searchText: widget.searchText,
                      locationCoordinates: _selectedLocation,
                      minFee: widget.userType == 'coach' ? double.tryParse(minFeeCtrl.text) ?? 500 : null,
                      maxFee: widget.userType == 'coach' ? double.tryParse(maxFeeCtrl.text) ?? 2000 : null,
                      shift: widget.userType == 'coach' ? (shift != 'Any' ? shift : null) : null,
                    );
                    widget.onApply(filter);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}