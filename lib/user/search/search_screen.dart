import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sports_c/user/search/location.dart';

const Color appPrimaryColor = Color(0xFF1994DD);
const Color appSecondaryColor = Color(0xFF22C493);

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class PlayerFilter {
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

  PlayerFilter({
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
  });
}

abstract class SearchEvent {}

class ApplyFilter extends SearchEvent {
  final PlayerFilter filter;
  ApplyFilter(this.filter);
}

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<String> results;
  SearchLoaded(this.results);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<ApplyFilter>((event, emit) async {
      emit(SearchLoading());
      await Future.delayed(const Duration(seconds: 1));

      // Sports list
      final sportsList = [
        '1. Cricket',
        '2. Basketball',
        '3. Volleyball',
        '4. Athletics',
      ];

      // Positions mapped by sport
      final positionMap = {
        'Cricket': ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'],
        'Basketball': ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
        'Volleyball': ['Setter', 'Outside Hitter', 'Middle Blocker', 'Opposite Hitter', 'Libero'],
        'Athletics': ['Sprinter', 'Long Distance Runner', 'High Jumper', 'Thrower'],
      };

      final positions = positionMap[event.filter.sport] ?? [];

      // Example player results
      final playerResults = [
        '${event.filter.searchText} - ${event.filter.sport} - ${event.filter.position} - ${event.filter.skillLevel} - ${event.filter.location}',
        'Player B - ${event.filter.sport} - ${event.filter.position}',
      ];

      // Combine sports, positions, and player results
      emit(SearchLoaded([
        ...sportsList,
        '--- Positions in ${event.filter.sport} ---',
        ...positions,
        ...playerResults
      ]));
    });
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
          title: const Text('Search Players'),
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
    'Cricket',
    'Basketball',
    'Volleyball',
    'Athletics',
  ];
  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced'];

  String selectedSport = 'Volleyball';
  String selectedPosition = '';
  double minAge = 10;
  double maxAge = 25;
  double minHeight = 140;
  double maxHeight = 200;
  double minWeight = 40;
  double maxWeight = 100;
  String selectedSkillLevel = 'Beginner';
  String locationInput = 'Tirunelveli, Tamil Nadu';
  String searchText = '';

  void _openFilterDialog({required String enteredText}) async {
    searchText = enteredText;

    final lowerText = enteredText.toLowerCase();
    for (final sport in sports) {
      if (lowerText.contains(sport.toLowerCase())) {
        selectedSport = sport;
        break;
      }
    }

    // Detect simple age/height/weight
    final ageMatch = RegExp(r'(\d{1,2})\s*(yo|years?)').firstMatch(lowerText);
    final heightMatch = RegExp(r'(\d{2,3})\s*cm').firstMatch(lowerText);
    final weightMatch = RegExp(r'(\d{2,3})\s*kg').firstMatch(lowerText);

    if (ageMatch != null) {
      double age = double.tryParse(ageMatch.group(1)!) ?? 10;
      minAge = (age - 2).clamp(5, 100);
      maxAge = (age + 2).clamp(5, 100);
    }
    if (heightMatch != null) {
      double height = double.tryParse(heightMatch.group(1)!) ?? 150;
      minHeight = (height - 10).clamp(100, 250);
      maxHeight = (height + 10).clamp(100, 250);
    }
    if (weightMatch != null) {
      double weight = double.tryParse(weightMatch.group(1)!) ?? 60;
      minWeight = (weight - 10).clamp(30, 200);
      maxWeight = (weight + 10).clamp(30, 200);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: FilterForm(
          sports: sports,
          skillLevels: skillLevels,
          selectedSport: selectedSport,
          selectedPosition: selectedPosition,
          minAge: minAge,
          maxAge: maxAge,
          minHeight: minHeight,
          maxHeight: maxHeight,
          minWeight: minWeight,
          maxWeight: maxWeight,
          selectedSkillLevel: selectedSkillLevel,
          locationInput: locationInput,
          searchText: searchText,
          onApply: (filter) {
            context.read<SearchBloc>().add(ApplyFilter(filter));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show sports list first
    final sportsListWithPositions = [
      '1. Cricket',
      '2. Basketball',
      '3. Volleyball',
      '4. Athletics',
    ];

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search players (e.g. Cricket Batsman 16yo 170cm)',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (text) {
              if (text.isNotEmpty) {
                _openFilterDialog(enteredText: text);
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              List<String> results = sportsListWithPositions;

              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchLoaded) {
                results = state.results;
              }

              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: appPrimaryColor,
                        child: const Icon(Icons.sports, color: Colors.white),
                      ),
                      title: Text(results[index]),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FilterForm extends StatefulWidget {
  final List<String> sports;
  final List<String> skillLevels;
  final String selectedSport;
  final String selectedPosition;
  final double minAge, maxAge, minHeight, maxHeight, minWeight, maxWeight;
  final String selectedSkillLevel;
  final String locationInput;
  final String searchText;
  final Function(PlayerFilter) onApply;

  const FilterForm({
    super.key,
    required this.sports,
    required this.skillLevels,
    required this.selectedSport,
    required this.selectedPosition,
    required this.minAge,
    required this.maxAge,
    required this.minHeight,
    required this.maxHeight,
    required this.minWeight,
    required this.maxWeight,
    required this.selectedSkillLevel,
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
  late TextEditingController locationCtrl;
  late TextEditingController minAgeCtrl;
  late TextEditingController maxAgeCtrl;
  late TextEditingController minHeightCtrl;
  late TextEditingController maxHeightCtrl;
  late TextEditingController minWeightCtrl;
  late TextEditingController maxWeightCtrl;
  LatLng? _selectedLocation;

  final _formKey = GlobalKey<FormState>();

  final Map<String, List<String>> positionMap = {
    'Cricket': ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'],
    'Basketball': ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'],
    'Volleyball': ['Setter', 'Outside Hitter', 'Middle Blocker', 'Opposite Hitter', 'Libero'],
    'Athletics': ['Sprinter', 'Long Distance Runner', 'High Jumper', 'Thrower'],
  };

  @override
  void initState() {
    super.initState();
    sport = widget.selectedSport;
    skillLevel = widget.selectedSkillLevel;
    position = widget.selectedPosition.isNotEmpty
        ? widget.selectedPosition
        : (positionMap[widget.selectedSport]?.first ?? '');
    locationCtrl = TextEditingController(text: widget.locationInput);
    minAgeCtrl = TextEditingController(text: widget.minAge.toStringAsFixed(0));
    maxAgeCtrl = TextEditingController(text: widget.maxAge.toStringAsFixed(0));
    minHeightCtrl = TextEditingController(text: widget.minHeight.toStringAsFixed(0));
    maxHeightCtrl = TextEditingController(text: widget.maxHeight.toStringAsFixed(0));
    minWeightCtrl = TextEditingController(text: widget.minWeight.toStringAsFixed(0));
    maxWeightCtrl = TextEditingController(text: widget.maxWeight.toStringAsFixed(0));
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

  @override
  Widget build(BuildContext context) {
    final positions = positionMap[sport] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Filter Players',
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
                  setState(() {
                    sport = value!;
                    position = positionMap[sport]?.first ?? '';
                  });
                },
                decoration: _inputDecoration('Sport'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: position,
                items: positions
                    .map((pos) => DropdownMenuItem(value: pos, child: Text(pos)))
                    .toList(),
                onChanged: (value) => setState(() => position = value!),
                decoration: _inputDecoration('Position'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: skillLevel,
                items: widget.skillLevels
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => skillLevel = value!),
                decoration: _inputDecoration('Skill Level'),
              ),
              const SizedBox(height: 12),
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
                      if (_formKey.currentState!.validate()) {
                        final filter = PlayerFilter(
                          sport: sport,
                          position: position,
                          minAge: double.parse(minAgeCtrl.text),
                          maxAge: double.parse(maxAgeCtrl.text),
                          minHeight: double.parse(minHeightCtrl.text),
                          maxHeight: double.parse(maxHeightCtrl.text),
                          minWeight: double.parse(minWeightCtrl.text),
                          maxWeight: double.parse(maxWeightCtrl.text),
                          location: locationCtrl.text,
                          skillLevel: skillLevel,
                          searchText: widget.searchText,
                          locationCoordinates: _selectedLocation,
                        );
                        widget.onApply(filter);
                      }
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
      ),
    );
  }
}
