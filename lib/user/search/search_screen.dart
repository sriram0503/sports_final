import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sports_c/user/search/location.dart';

/// ------------------- APP COLORS -------------------
const Color appPrimaryColor = Color(0xFF1994DD);
const Color appSecondaryColor = Color(0xFF22C493);

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
          backgroundColor: appPrimaryColor,
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
  String locationInput = '';
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

/// ------------------- FILTER FORM WIDGET -------------------
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Filter Players',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appPrimaryColor),
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
              value: skillLevel,
              items: widget.skillLevels.map((level) => DropdownMenuItem(
                value: level,
                child: Text(level),
              )).toList(),
              onChanged: (value) => setState(() => skillLevel = value!),
              decoration: _inputDecoration('Skill Level'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              readOnly: true,
              decoration: _inputDecoration('Location').copyWith(
                suffixIcon: Icon(Icons.location_on, color: appSecondaryColor),
              ),
              onTap: () async {
                final pickedAddress = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                );
                if (pickedAddress != null) {
                  setState(() {
                    locationCtrl.text = pickedAddress;
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
                      sport: sport,
                      minAge: double.tryParse(minAgeCtrl.text) ?? 10,
                      maxAge: double.tryParse(maxAgeCtrl.text) ?? 25,
                      minHeight: double.tryParse(minHeightCtrl.text) ?? 140,
                      maxHeight: double.tryParse(maxHeightCtrl.text) ?? 200,
                      minWeight: double.tryParse(minWeightCtrl.text) ?? 40,
                      maxWeight: double.tryParse(maxWeightCtrl.text) ?? 100,
                      location: locationCtrl.text,
                      skillLevel: skillLevel,
                      searchText: widget.searchText,
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
