import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../models/health_conditions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Profile tab with editable email, DOB, gender, health notes (same chips as registration).
class EditableProfileTab extends StatefulWidget {
  const EditableProfileTab({
    super.key,
    required this.user,
    required this.auth,
    required this.onProfileSaved,
    required this.onLogout,
  });

  final UserModel user;
  final AuthService auth;
  final Future<void> Function() onProfileSaved;
  final VoidCallback onLogout;

  @override
  State<EditableProfileTab> createState() => _EditableProfileTabState();
}

class _EditableProfileTabState extends State<EditableProfileTab> {
  late TextEditingController _emailCtrl;
  DateTime? _dob;
  String? _gender;
  final Set<String> _selected = {};
  List<HealthCondition> _conditions = [];
  String? _loadError;
  String? _saveError;
  bool _saving = false;
  bool _loadingConditions = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user.email);
    _dob = _parseDob(widget.user.dateOfBirth);
    _gender = widget.user.gender;
    _loadConditions();
  }

  @override
  void didUpdateWidget(EditableProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.email != widget.user.email ||
        oldWidget.user.dateOfBirth != widget.user.dateOfBirth ||
        oldWidget.user.gender != widget.user.gender ||
        oldWidget.user.diseases != widget.user.diseases) {
      setState(() {
        _emailCtrl.text = widget.user.email;
        _dob = _parseDob(widget.user.dateOfBirth);
        _gender = widget.user.gender;
        _syncSelectionFromDiseases();
      });
    }
  }

  DateTime? _parseDob(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _loadConditions() async {
    try {
      final raw = await rootBundle.loadString('assets/health_conditions.json');
      final data = HealthConditionsData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _conditions = data.conditions;
          _loadingConditions = false;
          _syncSelectionFromDiseases();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load health conditions.';
          _loadingConditions = false;
        });
      }
    }
  }

  void _syncSelectionFromDiseases() {
    final csv = widget.user.diseases;
    if (csv == null || csv.isEmpty || _conditions.isEmpty) {
      _selected.clear();
      return;
    }
    final labels = csv.split(',').map((s) => s.trim().toLowerCase()).toSet();
    _selected
      ..clear()
      ..addAll(
        _conditions.where((c) => labels.contains(c.label.toLowerCase())).map((c) => c.id),
      );
  }

  String _diseasesCsv() {
    final byId = {for (final c in _conditions) c.id: c.label};
    return _selected.map((id) => byId[id]).whereType<String>().join(', ');
  }

  String? _dobApi() {
    if (_dob == null) return null;
    final y = _dob!.year.toString().padLeft(4, '0');
    final m = _dob!.month.toString().padLeft(2, '0');
    final d = _dob!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _save() async {
    setState(() {
      _saveError = null;
      _saving = true;
    });
    try {
      await widget.auth.updateProfile(
        email: _emailCtrl.text.trim(),
        dateOfBirth: _dobApi(),
        gender: (_gender?.isEmpty ?? true) ? null : _gender,
        diseases: _diseasesCsv(),
      );
      await widget.onProfileSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          u.username,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of birth'),
                  subtitle: Text(
                    _dob == null ? 'Not set' : DateFormat.yMMMMd().format(_dob!),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _dob ?? DateTime(now.year - 25),
                      firstDate: DateTime(1900),
                      lastDate: now,
                    );
                    if (d != null) setState(() => _dob = d);
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _dob = null),
                    child: const Text('Clear date of birth'),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _gender,
                        isExpanded: true,
                        hint: const Text('—'),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ),
                ),
                Text('Health notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Tap to select — multiple allowed.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_loadError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                if (!_loadingConditions && _conditions.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _conditions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final c = _conditions[i];
                        final sel = _selected.contains(c.id);
                        return FilterChip(
                          label: Text(c.label),
                          selected: sel,
                          onSelected: (_) {
                            setState(() {
                              if (sel) {
                                _selected.remove(c.id);
                              } else {
                                _selected.add(c.id);
                              }
                            });
                          },
                          showCheckmark: true,
                          checkmarkColor: Colors.green.shade900,
                          selectedColor: Colors.green.shade200,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          side: BorderSide(
                            color: sel ? Colors.green.shade600 : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          labelStyle: TextStyle(
                            color: sel ? Colors.green.shade900 : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: widget.onLogout,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Colors.red.shade800,
          ),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
