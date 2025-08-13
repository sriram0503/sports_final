import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sports_c/user/search/location.dart';

/// ------------------- MODEL -------------------
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
  });
}

/// ------------------- BLOC -------------------
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

/// ------------------- MAIN CONTAINER -------------------
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SearchPage(),
  ));
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
          backgroundColor: Colors.deepPurple,
        ),
        body: const SafeArea(child: MainSearchContainer()),
      ),
    );
  }
}

/// ------------------- MAIN SEARCH CONTAINER -------------------
class MainSearchContainer extends StatefulWidget {
  const MainSearchContainer({super.key});

  @override
  State<MainSearchContainer> createState() => _MainSearchContainerState();
}

class _MainSearchContainerState extends State<MainSearchContainer> {
  final List<String> sports = [
    'Football', 'Cricket', 'Basketball', 'Volleyball',
    'Hockey', 'Badminton', 'Tennis', 'Athletics', 'Boxing', 'Wrestling'
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
  String locationInput = '';
  String searchText = '';

  void _openFilterSheet({required String enteredText}) async {
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
      minAge = (age - 2).clamp(0, 100);
      maxAge = (age + 2).clamp(0, 100);
    }
    if (heightMatch != null) {
      double height = double.tryParse(heightMatch.group(1)!) ?? 150;
      minHeight = (height - 10).clamp(0, 300);
      maxHeight = (height + 10).clamp(0, 300);
    }
    if (weightMatch != null) {
      double weight = double.tryParse(weightMatch.group(1)!) ?? 60;
      minWeight = (weight - 10).clamp(0, 300);
      maxWeight = (weight + 10).clamp(0, 300);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                _openFilterSheet(enteredText: text);
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
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, color: Colors.white),
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

/// ------------------- FILTER FORM WIDGET -------------------
class FilterForm extends StatelessWidget {
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sportCtrl = ValueNotifier(selectedSport);
    final skillCtrl = ValueNotifier(selectedSkillLevel);
    final locationCtrl = TextEditingController(text: locationInput);
    final minAgeCtrl = TextEditingController(text: minAge.toStringAsFixed(0));
    final maxAgeCtrl = TextEditingController(text: maxAge.toStringAsFixed(0));
    final minHeightCtrl = TextEditingController(text: minHeight.toStringAsFixed(0));
    final maxHeightCtrl = TextEditingController(text: maxHeight.toStringAsFixed(0));
    final minWeightCtrl = TextEditingController(text: minWeight.toStringAsFixed(0));
    final maxWeightCtrl = TextEditingController(text: maxWeight.toStringAsFixed(0));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Card(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  items: sports.map((sport) => DropdownMenuItem(
                    value: sport, child: Text(sport),
                  )).toList(),
                  onChanged: (value) => sportCtrl.value = value!,
                  decoration: _inputDecoration('Sport'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: minAgeCtrl, decoration: _inputDecoration('Min Age'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: maxAgeCtrl, decoration: _inputDecoration('Max Age'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: minHeightCtrl, decoration: _inputDecoration('Min Height (cm)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: maxHeightCtrl, decoration: _inputDecoration('Max Height (cm)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: minWeightCtrl, decoration: _inputDecoration('Min Weight (kg)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: maxWeightCtrl, decoration: _inputDecoration('Max Weight (kg)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSkillLevel,
                  items: skillLevels.map((level) => DropdownMenuItem(
                    value: level, child: Text(level),
                  )).toList(),
                  onChanged: (value) => skillCtrl.value = value!,
                  decoration: _inputDecoration('Skill Level'),
                ),
                const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                readOnly: true,
                decoration: _inputDecoration('Location').copyWith(
                  suffixIcon: const Icon(Icons.location_on, color: Colors.deepPurple),
                ),
                onTap: () async {
                  final pickedAddress = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerPage()),
                  );
                  if (pickedAddress != null) {
                    locationCtrl.text = pickedAddress;
                  }
                },
              ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final filter = PlayerFilter(
                      sport: sportCtrl.value,
                      minAge: double.tryParse(minAgeCtrl.text) ?? 10,
                      maxAge: double.tryParse(maxAgeCtrl.text) ?? 25,
                      minHeight: double.tryParse(minHeightCtrl.text) ?? 140,
                      maxHeight: double.tryParse(maxHeightCtrl.text) ?? 200,
                      minWeight: double.tryParse(minWeightCtrl.text) ?? 40,
                      maxWeight: double.tryParse(maxWeightCtrl.text) ?? 100,
                      location: locationCtrl.text,
                      skillLevel: skillCtrl.value,
                      searchText: searchText,
                    );
                    onApply(filter);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
