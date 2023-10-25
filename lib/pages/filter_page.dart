import 'package:flutter/material.dart';
import 'package:selectable_autolink_text/selectable_autolink_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_editor/utils/model/filter_wrapper.dart';

class FilterPage extends StatefulWidget {
  final FilterWrapper wrapper;

  const FilterPage({super.key, required this.wrapper});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  @override
  void dispose() {
    super.dispose();
  }

  List<TextFormField> _buildValueRows() {
    return widget.wrapper.values
        .map((key, value) {
          return MapEntry(
            key,
            TextFormField(
              onFieldSubmitted: (value) => widget.wrapper.values[key] = value,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                icon: const Icon(Icons.timelapse),
                labelText: key,
                hintText: 'Current value: $value',
                border: InputBorder.none,
              ),
            ),
          );
        })
        .values
        .toList();
  }

  Widget _buildEnableButton(final BuildContext context) {
    return Center(
      child: Card(
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Enable', style: Theme.of(context).textTheme.headlineSmall),
              const Padding(padding: EdgeInsets.all(5)),
              Switch(
                value: widget.wrapper.enabled,
                onChanged: (value) => setState(() {
                  widget.wrapper.enabled = value;
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wrapper.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.wrapper.displayName, style: textTheme.headlineSmall),
            const Padding(padding: EdgeInsets.all(15)),
            Text('Description', style: textTheme.bodyLarge),
            Text(widget.wrapper.description, style: textTheme.bodyMedium),
            const Padding(padding: EdgeInsets.all(15)),
            Text('Help', style: textTheme.bodyLarge),
            SelectableAutoLinkText(
              widget.wrapper.help,
              style: textTheme.bodyMedium,
              linkStyle: const TextStyle(color: Colors.blueAccent),
              onTap: _launchUrl,
            ),
            const Padding(padding: EdgeInsets.all(15)),
            Text('Values', style: textTheme.headlineMedium),
            Column(children: _buildValueRows()),
            _buildEnableButton(context)
          ],
        ),
      ),
    );
  }
}
