import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/health_conditions.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.onRegistered,
    required this.onBackToLogin,
  });

  final AuthService auth;
  final VoidCallback onRegistered;
  final VoidCallback onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final Set<String> _selected = {};
  List<HealthCondition> _conditions = [];
  String? _loadError;
  String? _error;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  Future<void> _loadConditions() async {
    try {
      final raw = await rootBundle.loadString('assets/health_conditions.json');
      final data = HealthConditionsData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      setState(() => _conditions = data.conditions);
    } catch (e) {
      setState(() => _loadError = 'Could not load health conditions.');
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  String _diseasesCsv() {
    final byId = {for (final c in _conditions) c.id: c.label};
    return _selected.map((id) => byId[id]).whereType<String>().join(', ');
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _pending = true;
    });
    try {
      await widget.auth.register(
        username: _userCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        passwordConfirm: _pass2Ctrl.text,
        dateOfBirth: _dob == null
            ? null
            : '${_dob!.year.toString().padLeft(4, '0')}-'
                '${_dob!.month.toString().padLeft(2, '0')}-'
                '${_dob!.day.toString().padLeft(2, '0')}',
        gender: (_gender?.isEmpty ?? true) ? null : _gender,
        diseases: _diseasesCsv(),
      );
      widget.onRegistered();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of birth'),
              subtitle: Text(_dob == null ? '—' : _dob!.toString().split(' ').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 25),
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (d != null) setState(() => _dob = d);
              },
            ),
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
            const SizedBox(height: 16),
            Text('Health notes (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Select any that apply — you can choose more than one.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_loadError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
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
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password (min 8 characters)'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass2Ctrl,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _pending ? null : _submit,
              child: Text(_pending ? 'Creating account…' : 'Register'),
            ),
            TextButton(
              onPressed: _pending ? null : widget.onBackToLogin,
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
