import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<Row> _buildValueRows() {
    return widget.wrapper.values
        .map((key, value) {
          return MapEntry(
              key,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      onFieldSubmitted: (value) => widget.wrapper.values[key] = value,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.timelapse),
                        labelText: key,
                        hintText: 'Current value: $value',
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Switch(
                    value: widget.wrapper.enabled,
                    onChanged: (value) => setState(() {
                      widget.wrapper.enabled = value;
                    }),
                  )
                ],
              ));
        })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wrapper.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(widget.wrapper.name, style: Theme.of(context).textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(widget.wrapper.description, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const Padding(padding: EdgeInsets.all(10)),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(children: _buildValueRows()),
          ),
        ],
      ),
    );
  }
}
