import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:video_editor/utils/config_util.dart' as config;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editing Options')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Flags'),
            tiles: config.editingOptions
                .map((key, value) => MapEntry(
                    key,
                    SettingsTile.switchTile(
                      onToggle: (value) {
                        setState(() {
                          config.editingOptions[key] = value;
                        });
                      },
                      initialValue: value,
                      leading: const Icon(Icons.settings),
                      title: Text(key),
                    )))
                .values
                .toList(),
          ),
        ],
      ),
    );
  }
}
