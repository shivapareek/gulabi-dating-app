import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../data/jaipur_areas.dart';
import '../data/repo.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Profile setup wizard. Also used to edit the profile (editing: true).
class OnboardingScreen extends StatefulWidget {
  final bool editing;
  const OnboardingScreen({super.key, this.editing = false});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _step = 0;
  bool _saving = false;
  bool _uploading = false;
  late UserProfile p;
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _job = TextEditingController();
  final _edu = TextEditingController();
  final Map<String, TextEditingController> _promptCtl = {};

  static const _stepCount = 9;

  @override
  void initState() {
    super.initState();
    p = app.me ?? UserProfile(uid: Repo.instance.uid ?? 'me');
    _name.text = p.name;
    _bio.text = p.bio;
    _job.text = p.job;
    _edu.text = p.education;
    p.prompts.forEach((k, v) => _promptCtl[k] = TextEditingController(text: v));
  }

  String? _problem() {
    switch (_step) {
      case 0:
        return _name.text.trim().length < 2 ? 'Please enter your name' : null;
      case 1:
        if (p.dob == null) return 'Please pick your birthday';
        if (p.age < 18) return 'You must be 18 or older to use Gulabi';
        return null;
      case 2:
        return p.interestedIn.isEmpty ? 'Choose who you want to meet' : null;
      case 4:
        return p.photos.length < 2 ? 'Add at least 2 photos' : null;
      case 6:
        return p.interests.length < 3 ? 'Pick at least 3 interests' : null;
    }
    return null;
  }

  Future<void> _next() async {
    final problem = _problem();
    if (problem != null) {
      toast(context, problem);
      return;
    }
    FocusScope.of(context).unfocus();
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      _pc.animateToPage(_step,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    } else {
      await _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step--);
    _pc.animateToPage(_step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    p
      ..name = _name.text.trim()
      ..bio = _bio.text.trim()
      ..job = _job.text.trim()
      ..education = _edu.text.trim()
      ..prompts = {
        for (final e in _promptCtl.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim()
      };
    try {
      await app.saveMe(p);
      if (!mounted) return;
      if (widget.editing) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context)
            .pushAndRemoveUntil(fadeRoute(const HomeShell()), (_) => false);
      }
    } catch (e) {
      if (mounted) toast(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1440);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final url = await Repo.instance.uploadImage(x.path, 'photos');
      setState(() => p.photos.add(url));
    } catch (e) {
      if (mounted) toast(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _takeSelfie() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1080);
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final url = await Repo.instance.uploadImage(x.path, 'verification');
      setState(() {
        p.selfie = url;
        if (Repo.instance.isDemo) {
          p.verificationStatus = 'approved';
          p.verified = true;
        } else {
          p.verificationStatus = 'pending';
        }
      });
    } catch (e) {
      if (mounted) toast(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _nameStep(),
      _dobStep(),
      _genderStep(),
      _areaStep(),
      _photoStep(),
      _aboutStep(),
      _interestStep(),
      _promptStep(),
      _verifyStep(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(children: [
              IconButton(
                  onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (_step + 1) / _stepCount),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      color: Brand.pink,
                      backgroundColor: Brand.pink.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _pc,
              physics: const NeverScrollableScrollPhysics(),
              children: pages
                  .map((w) => SingleChildScrollView(
                      padding: const EdgeInsets.all(24), child: w))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: GradientButton(
              _step == _stepCount - 1
                  ? (widget.editing ? 'Save profile' : 'Start matching')
                  : 'Continue',
              loading: _saving || _uploading,
              onTap: _next,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _title(String t, [String? sub]) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub, style: TextStyle(color: Theme.of(context).hintColor)),
          ],
          const SizedBox(height: 28),
        ],
      );

  Widget _nameStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('My first name is', 'This is how it will appear on your profile.'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 22),
          decoration: const InputDecoration(hintText: 'First name'),
        ),
      ]);

  Widget _dobStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('My birthday is', 'Your age is shown, your birthday is not. Gulabi is 18+ only.'),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: p.dob ?? DateTime(now.year - 24),
              firstDate: DateTime(now.year - 80),
              lastDate: now,
            );
            if (d != null) setState(() => p.dob = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.cake_rounded)),
            child: Text(
              p.dob == null ? 'Pick date' : DateFormat('d MMMM y').format(p.dob!),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        if (p.dob != null) ...[
          const SizedBox(height: 16),
          Text('Age ${p.age}',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: p.age < 18 ? Colors.red : Brand.pink)),
        ],
      ]);

  Widget _choice(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            gradient: selected ? Brand.gradient : null,
            border: Border.all(
                color: selected ? Colors.transparent : Brand.pink.withOpacity(0.3),
                width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
              child: Row(children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : null)),
                ),
                if (selected) const Icon(Icons.check_rounded, color: Colors.white),
              ]),
            ),
          ),
        ),
      );

  Widget _genderStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('I am a'),
        for (final g in ['Woman', 'Man', 'Other'])
          _choice(g, p.gender == g, () => setState(() => p.gender = g)),
        const SizedBox(height: 20),
        Text('Show me', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final g in ['Man', 'Woman', 'Other'])
          _choice(g == 'Man' ? 'Men' : g == 'Woman' ? 'Women' : 'Everyone else',
              p.interestedIn.contains(g), () {
            setState(() => p.interestedIn.contains(g)
                ? p.interestedIn.remove(g)
                : p.interestedIn.add(g));
          }),
      ]);

  Widget _areaStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('Where in Jaipur?', 'Used to show distance. Your exact location is never shared.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: jaipurAreas.keys
              .map((a) => ChoiceChip(
                    label: Text(a),
                    selected: p.area == a,
                    selectedColor: Brand.pink,
                    labelStyle: TextStyle(color: p.area == a ? Colors.white : null),
                    onSelected: (_) => setState(() => p.area = a),
                  ))
              .toList(),
        ),
      ]);

  Widget _photoStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('Add your photos', 'Add 2 to 6 photos. Long-press a photo to remove it. The first one is your main photo.'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
          children: List.generate(6, (i) {
            final has = i < p.photos.length;
            return GestureDetector(
              onTap: has || _uploading ? null : _addPhoto,
              onLongPress: has ? () => setState(() => p.photos.removeAt(i)) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: has
                    ? Stack(fit: StackFit.expand, children: [
                        Photo(p.photos[i], name: p.name),
                        if (i == 0)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: Brand.pink,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text('Main',
                                  style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                      ])
                    : Container(
                        color: Brand.pink.withOpacity(0.08),
                        child: Icon(Icons.add_a_photo_rounded,
                            color: Brand.pink.withOpacity(0.7)),
                      ),
              ),
            );
          }),
        ),
      ]);

  Widget _aboutStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('About you'),
        TextField(
          controller: _bio,
          maxLines: 4,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'A few lines about you...'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _job,
          decoration: const InputDecoration(
              hintText: 'Job title', prefixIcon: Icon(Icons.work_rounded)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _edu,
          decoration: const InputDecoration(
              hintText: 'College / University', prefixIcon: Icon(Icons.school_rounded)),
        ),
        const SizedBox(height: 20),
        Text('Height: ${p.heightCm ?? 165} cm',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: (p.heightCm ?? 165).toDouble(),
          min: 140,
          max: 210,
          activeColor: Brand.pink,
          onChanged: (v) => setState(() => p.heightCm = v.round()),
        ),
        const SizedBox(height: 12),
        Text('Looking for', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Relationship', 'Something casual', 'Friends', 'Not sure']
              .map((l) => ChoiceChip(
                    label: Text(l),
                    selected: p.lookingFor == l,
                    selectedColor: Brand.pink,
                    labelStyle: TextStyle(color: p.lookingFor == l ? Colors.white : null),
                    onSelected: (_) => setState(() => p.lookingFor = l),
                  ))
              .toList(),
        ),
      ]);

  Widget _interestStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('Your interests', 'Pick 3 to 10. They help us find people you will click with.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allInterests.map((i) {
            final sel = p.interests.contains(i);
            return FilterChip(
              label: Text(i),
              selected: sel,
              selectedColor: Brand.pink,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: sel ? Colors.white : null),
              onSelected: (v) => setState(() {
                if (v && p.interests.length < 10) {
                  p.interests.add(i);
                } else {
                  p.interests.remove(i);
                }
              }),
            );
          }).toList(),
        ),
      ]);

  Widget _promptStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('Profile prompts', 'Answer up to 3. Great conversation starters.'),
        ...allPrompts.map((q) {
          final on = _promptCtl.containsKey(q);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Brand.pink,
                value: on,
                title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
                onChanged: (v) => setState(() {
                  if (v == true && _promptCtl.length < 3) {
                    _promptCtl[q] = TextEditingController();
                  } else if (v == false) {
                    _promptCtl.remove(q);
                  }
                }),
              ),
              if (on)
                TextField(
                  controller: _promptCtl[q],
                  maxLength: 120,
                  decoration: const InputDecoration(hintText: 'Your answer'),
                ),
            ]),
          );
        }),
      ]);

  Widget _verifyStep() {
    final status = p.verificationStatus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Get verified',
          'Take a quick selfie. Our team matches it with your photos and you get a blue tick. Verified profiles get up to 3x more matches.'),
      Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Brand.blue, width: 4),
          ),
          child: ClipOval(
            child: p.selfie.isEmpty
                ? const Icon(Icons.face_retouching_natural, size: 72, color: Brand.blue)
                : Photo(p.selfie, name: p.name),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          status == 'approved'
              ? 'You are verified ✓'
              : status == 'pending'
                  ? 'Selfie submitted · review pending'
                  : 'Optional, but recommended',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 16),
      if (status != 'approved')
        Center(
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : _takeSelfie,
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(p.selfie.isEmpty ? 'Take selfie' : 'Retake selfie'),
          ),
        ),
    ]);
  }
}
