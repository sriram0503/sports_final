import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sports_c/user/search/location.dart';
import 'package:sports_c/user/profile/other_user.dart';
import 'package:sports_c/user/notification/notification.dart';


const Color appPrimaryColor = Color(0xFF1994DD);
const Color appSecondaryColor = Color(0xFF22C493);

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class PlayerFilter {
  final String sport;
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
      emit(SearchLoaded([
        '${event.filter.searchText} - ${event.filter.sport} - ${event.filter.skillLevel} - ${event.filter.location}',
        'Player B - ${event.filter.sport}',
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
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none),
                  // Tiny badge (hard-coded 3 for now; replace with real count later)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Notifications',
            ),
          ],
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
    'Football',
    'Cricket',
    'Basketball',
    'Volleyball',
    'Hockey',
    'Badminton',
    'Tennis',
    'Athletics',
    'Boxing',
    'Wrestling'
  ];
  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced'];

  String selectedSport = 'Football';
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
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search players (e.g. Cricket 16yo 170cm)',
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
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchLoaded) {
                return ListView.builder(
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: ListTile(
                        onTap: () {
                          final raw = state.results[index];
                          final userName = raw.split('-').first.trim(); // example parse
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherUserProfilePage(
                                userName: userName,
                                isCoach: index % 2 == 0, // just example flag
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: appPrimaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(state.results[index]),
                        subtitle: const Text('Skill • Age • Height'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),

                    );
                  },
                );
              } else {
                return const Center(
                  child: Text(
                    'Use the search bar to filter players.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
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

  @override
  void initState() {
    super.initState();
    sport = widget.selectedSport;
    skillLevel = widget.selectedSkillLevel;
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

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Please enter age';
    final num = double.tryParse(value);
    if (num == null) return 'Enter valid number';
    if (num < 5 || num > 100) return 'Age must be 5-100';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter height';
    final num = double.tryParse(value);
    if (num == null) return 'Enter valid number';
    if (num < 100 || num > 250) return 'Height must be 100-250 cm';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter weight';
    final num = double.tryParse(value);
    if (num == null) return 'Enter valid number';
    if (num < 30 || num > 200) return 'Weight must be 30-200 kg';
    return null;
  }

  String? _validateRange(String? minValue, String? maxValue, String fieldName) {
    final min = double.tryParse(minValue ?? '');
    final max = double.tryParse(maxValue ?? '');
    if (min != null && max != null && min > max) {
      return 'Max $fieldName must be ≥ min';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                items: widget.sports.map((sport) => DropdownMenuItem(
                  value: sport,
                  child: Text(sport),
                )).toList(),
                onChanged: (value) => setState(() => sport = value!),
                decoration: _inputDecoration('Sport'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minAgeCtrl,
                      decoration: _inputDecoration('Min Age'),
                      keyboardType: TextInputType.number,
                      validator: _validateAge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: maxAgeCtrl,
                      decoration: _inputDecoration('Max Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final ageValidation = _validateAge(value);
                        if (ageValidation != null) return ageValidation;
                        return _validateRange(minAgeCtrl.text, value, 'age');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minHeightCtrl,
                      decoration: _inputDecoration('Min Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: _validateHeight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: maxHeightCtrl,
                      decoration: _inputDecoration('Max Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final heightValidation = _validateHeight(value);
                        if (heightValidation != null) return heightValidation;
                        return _validateRange(minHeightCtrl.text, value, 'height');
                      },
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
                      decoration: _inputDecoration('Min Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: _validateWeight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: maxWeightCtrl,
                      decoration: _inputDecoration('Max Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final weightValidation = _validateWeight(value);
                        if (weightValidation != null) return weightValidation;
                        return _validateRange(minWeightCtrl.text, value, 'weight');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: skillLevel,
                items: widget.skillLevels.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level),
                )).toList(),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a location';
                  }
                  return null;
                },
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