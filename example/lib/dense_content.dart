import 'package:flutter/cupertino.dart';
import 'document_inspector.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

/// A bounded document workflow using only implemented public package APIs.
class DocumentBrowser extends StatefulWidget {
  const DocumentBrowser({super.key});

  @override
  State<DocumentBrowser> createState() => _DocumentBrowserState();
}

class _DocumentBrowserState extends State<DocumentBrowser> {
  final _tabs = MacosTabController(length: 2);
  final _details = List.filled(2, '');
  String? _inspectorTitle;
  bool _inspectorReadOnly = false;
  final _selection = List.filled(
    2,
    'Select a document to inspect its details.',
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _tabs.removeListener(_changed);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Project documents',
        style: MacosTheme.of(context).typography.title2,
      ),
      const SizedBox(height: MacosChromeData.gap),
      const Text(
        'Compare columns and click to select. Use Up/Down, Home/End to '
        'select, Enter to inspect, and column headings to sort. Tabs retain state.',
      ),
      const SizedBox(height: MacosChromeData.gap),
      SizedBox(
        height: (MediaQuery.sizeOf(context).height - 360).clamp(
          320 + MediaQuery.textScalerOf(context).scale(40),
          640,
        ),
        child: MacosTabView(
          controller: _tabs,
          tabs: const [
            MacosTab(label: 'Working files'),
            MacosTab(label: 'Archive'),
          ],
          children: [
            _DocumentList(
              key: const ValueKey('working-documents'),
              count: 120,
              archived: false,
              onSelected: (value) => setState(() => _selection[0] = value),
              onInspected: (value) => setState(() => _details[0] = value),
            ),
            _DocumentList(
              key: const ValueKey('archived-documents'),
              count: 24,
              archived: true,
              onSelected: (value) => setState(() => _selection[1] = value),
              onInspected: (value) => setState(() => _details[1] = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: MacosChromeData.gap),
      Semantics(liveRegion: true, child: Text(_selection[_tabs.index])),
      Text(_details[_tabs.index]),
      const SizedBox(height: MacosChromeData.gap),
      Wrap(
        spacing: MacosChromeData.gap,
        runSpacing: MacosChromeData.gap,
        children: [
          PushButton(
            controlSize: ControlSize.regular,
            onPressed: _selection[_tabs.index].startsWith('Select a document')
                ? null
                : () => setState(() {
                    _inspectorTitle = _selection[_tabs.index]
                        .split(' — ')
                        .first;
                    _inspectorReadOnly = _tabs.index == 1;
                  }),
            child: const Text('Inspect selected document'),
          ),
          if (_inspectorTitle != null)
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: () => setState(() => _inspectorTitle = null),
              child: const Text('Close inspector'),
            ),
        ],
      ),
      if (_inspectorTitle != null) ...[
        const SizedBox(height: MacosChromeData.contentInset),
        DocumentInspector(
          key: ValueKey('$_inspectorTitle-$_inspectorReadOnly'),
          title: _inspectorTitle!,
          readOnly: _inspectorReadOnly,
        ),
      ],
    ],
  );
}

class _DocumentList extends StatefulWidget {
  const _DocumentList({
    super.key,
    required this.count,
    required this.archived,
    required this.onSelected,
    required this.onInspected,
  });
  final int count;
  final bool archived;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onInspected;

  @override
  State<_DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends State<_DocumentList> {
  int? _selected;
  int? _sortColumn;
  bool _ascending = true;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _names = [
    'Design brief',
    'Site survey',
    'Materials schedule',
    'Meeting notes',
    'Drawing register',
    'Progress report',
    'Handover checklist',
    'Project summary',
  ];
  String _name(int i) => '${_names[i % _names.length]} ${i + 1}';
  List<MacosTableRow> get _rows {
    final rows = List.generate(
      widget.count,
      (i) => MacosTableRow(
        id: i,
        cells: [
          _name(i),
          i.isEven ? 'Alex Morgan' : 'Sam Lee',
          '2026-11-${(i % 7 + 1).toString().padLeft(2, '0')}',
          '${120 + i * 17} KB',
        ],
      ),
    );
    rows.removeWhere(
      (row) =>
          !row.cells.join(' ').toLowerCase().contains(_query.toLowerCase()),
    );
    if (_sortColumn != null) {
      rows.sort((a, b) {
        final comparison = a.cells[_sortColumn!].compareTo(
          b.cells[_sortColumn!],
        );
        final stable = comparison == 0
            ? (a.id as int).compareTo(b.id as int)
            : comparison;
        return _ascending ? stable : -stable;
      });
    }
    return rows;
  }

  void _inspect(int index) => widget.onInspected(
    _rows.firstWhere((r) => r.id == index).cells.skip(1).join(' · '),
  );

  void _choose(int index) {
    _inspect(index);
    setState(() => _selected = index);
    widget.onSelected(
      '${_name(index)} — ${widget.archived ? 'Archived · read only' : 'Working copy · ready for review'}',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      MacosTextField(
        controller: _search,
        placeholder: 'Filter documents by title or author',
        onChanged: (value) => setState(() {
          _query = value;
        }),
      ),
      const SizedBox(height: MacosChromeData.gap),
      Text('${_rows.length} documents · Clear the filter to show all files.'),
      Expanded(
        child: MacosDataTable(
          columns: const [
            MacosTableColumn(label: 'Title', width: 240, sortable: true),
            MacosTableColumn(label: 'Author', width: 150),
            MacosTableColumn(label: 'Modified', width: 150, sortable: true),
            MacosTableColumn(label: 'Size', width: 100),
          ],
          rows: _rows,
          selectedId: _rows.any((r) => r.id == _selected) ? _selected : null,
          onSelectionChanged: (id) => _choose(id as int),
          onActivate: (id) => _choose(id as int),
          sortColumnIndex: _sortColumn,
          sortAscending: _ascending,
          onSort: (column, ascending) => setState(() {
            _sortColumn = column;
            _ascending = ascending;
          }),
          onSecondaryTap: (id, details) => widget.onInspected(
            '${_name(id as int)} — ${_rows.firstWhere((r) => r.id == id).cells.skip(1).join(' · ')}',
          ),
        ),
      ),
    ],
  );
}
