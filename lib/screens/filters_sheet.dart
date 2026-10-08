import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

Future<bool?> showFiltersSheet(BuildContext context) => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _FiltersSheet(),
    );

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();
  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  final f = app.filters;
  late RangeValues _age = RangeValues(f.minAge.toDouble(), f.maxAge.toDouble());
  late double _km = f.maxKm;
  late bool _verified = f.verifiedOnly;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Discovery settings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Row(children: [
            const Text('Age range', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_age.start.round()} - ${_age.end.round()}'),
          ]),
          RangeSlider(
            values: _age,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: Brand.pink,
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Maximum distance', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_km.round()} km'),
          ]),
          Slider(
            value: _km,
            min: 2,
            max: 40,
            activeColor: Brand.pink,
            onChanged: (v) => setState(() => _km = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: Brand.pink,
            title: const Row(children: [
              Text('Verified profiles only'),
              SizedBox(width: 6),
              VerifiedBadge(size: 18),
            ]),
            value: _verified,
            onChanged: (v) => setState(() => _verified = v),
          ),
          const SizedBox(height: 16),
          GradientButton('Apply', onTap: () {
            f
              ..minAge = _age.start.round()
              ..maxAge = _age.end.round()
              ..maxKm = _km
              ..verifiedOnly = _verified;
            app.saveFilters();
            Navigator.pop(context, true);
          }),
        ]),
      ),
    );
  }
}
