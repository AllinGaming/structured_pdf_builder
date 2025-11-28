import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const PdfLabApp());
}

class PdfLabApp extends StatelessWidget {
  const PdfLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structured PDF Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        brightness: Brightness.light,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
          ),
        ),
      ),
      home: const PdfStudioHome(),
    );
  }
}

class PdfStudioHome extends StatefulWidget {
  const PdfStudioHome({super.key});

  @override
  State<PdfStudioHome> createState() => _PdfStudioHomeState();
}

class _PdfStudioHomeState extends State<PdfStudioHome> {
  final _titleController = TextEditingController(text: 'Launch Brief');
  final _subtitleController = TextEditingController(
    text: 'Compose and export PDFs in the browser.',
  );
  final _summaryController = TextEditingController(
    text:
        'Describe the goal in a paragraph or two. Adjust accents, tables, QR, signature, and upload fonts or logos as needed.',
  );
  final _bulletController = TextEditingController(
    text:
        'Highlights a key outcome\nCaptures a second bullet\nAdds one more idea',
  );
  final _tableController = TextEditingController(
    text:
        'Phase,Owner,Due,Status\nDiscovery,A. Rivera,2025-12-12,On track\n'
        'Design,B. Chen,2026-01-05,Blocked\nBuild,C. Patel,2026-02-01,Planned',
  );
  final _notesController = TextEditingController(
    text: 'Use this space for footnotes or constraints.',
  );
  final _authorController = TextEditingController(text: 'Brand / Owner');
  final _qrController = TextEditingController(
    text: 'https://github.com/yourname/pdf-lab',
  );
  final _accentController = TextEditingController(text: '#1565C0');
  final _signatureNameController = TextEditingController(text: 'Name / Role');
  final _signatureDateController = TextEditingController(
    text: 'yyyy-mm-dd or date here',
  );

  Color _accentColor = const Color(0xFF1565C0);
  double _marginMm = 18;
  bool _includeSignature = true;
  bool _showGrid = false;
  bool _includeQr = true;
  Uint8List? _logoBytes;
  Uint8List? _customFontBytes;
  String? _customFontName;
  int _stateTick = 0;
  late Future<_FontPack> _fonts = _loadFonts();

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _bulletController.dispose();
    _tableController.dispose();
    _notesController.dispose();
    _authorController.dispose();
    _qrController.dispose();
    _accentController.dispose();
    _signatureNameController.dispose();
    _signatureDateController.dispose();
    super.dispose();
  }

  Future<_FontPack> _loadFonts() async {
    if (_customFontBytes != null) {
      final bytes = _customFontBytes!;
      final font = pw.Font.ttf(ByteData.view(bytes.buffer));
      return _FontPack(base: font, bold: font, mono: pw.Font.courier());
    }

    return _FontPack(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      mono: pw.Font.courier(),
    );
  }

  void _refresh() => setState(() => _stateTick++);

  Future<void> _refreshFonts() async {
    setState(() {
      _fonts = _loadFonts();
      _stateTick++;
    });
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      _logoBytes = result.files.single.bytes;
      _refresh();
    }
  }

  Future<void> _pickFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      _customFontBytes = result.files.single.bytes;
      _customFontName = result.files.single.name;
      await _refreshFonts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Structured PDF Builder'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Upload logo',
            icon: const Icon(Icons.image_outlined),
            onPressed: _pickLogo,
          ),
          IconButton(
            tooltip: 'Upload font (ttf/otf)',
            icon: const Icon(Icons.font_download_outlined),
            onPressed: _pickFont,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1200;
          final side = SizedBox(
            width: isWide ? 420 : double.infinity,
            child: _buildControlPanel(),
          );

          final preview = Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: PdfPreview(
                  key: ValueKey(_stateTick),
                  allowSharing: true,
                  allowPrinting: true,
                  canDebug: kDebugMode,
                  initialPageFormat: pdf.PdfPageFormat.a4,
                  pdfFileName: 'pdf-lab.pdf',
                  build: _generatePdf,
                  onPrinted: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sent to printer')),
                  ),
                  onShared: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download ready')),
                  ),
                ),
              ),
            ),
          );

          return isWide
              ? Row(children: [side, preview])
              : Column(children: [side, SizedBox(height: 8), preview]);
        },
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel(
              title: 'Document',
              children: [
                _textField('Title', _titleController),
                _textField('Subtitle', _subtitleController),
                _textField('Summary / intro', _summaryController, lines: 3),
                _textField(
                  'Bullets (one per line)',
                  _bulletController,
                  lines: 3,
                ),
                _textField(
                  'Table (comma separated rows)',
                  _tableController,
                  lines: 4,
                  mono: true,
                ),
              ],
            ),
            _panel(
              title: 'Branding',
              children: [
                _textField('Header text (brand/owner)', _authorController),
                _accentPicker(),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _marginMm,
                        min: 10,
                        max: 30,
                        divisions: 20,
                        label: 'Margin: ${_marginMm.toStringAsFixed(0)} mm',
                        onChanged: (v) {
                          _marginMm = v;
                          _refresh();
                        },
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Signature block'),
                      selected: _includeSignature,
                      onSelected: (v) {
                        _includeSignature = v;
                        _refresh();
                      },
                    ),
                    FilterChip(
                      label: const Text('Overlay grid'),
                      selected: _showGrid,
                      onSelected: (v) {
                        _showGrid = v;
                        _refresh();
                      },
                    ),
                    FilterChip(
                      label: const Text('QR link'),
                      selected: _includeQr,
                      onSelected: (v) {
                        _includeQr = v;
                        _refresh();
                      },
                    ),
                  ],
                ),
              ],
            ),
            _panel(
              title: 'Extras',
              children: [
                _textField('Notes / constraints', _notesController, lines: 2),
                _textField('QR value (when enabled)', _qrController),
                _textField('Signature name', _signatureNameController),
                _textField('Signature date', _signatureDateController),
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _logoBytes == null
                        ? 'Upload logo (png/svg)'
                        : 'Replace logo',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFont,
                  icon: const Icon(Icons.font_download_outlined),
                  label: Text(
                    _customFontBytes == null
                        ? 'Upload font (ttf/otf)'
                        : 'Replace font (${_customFontName ?? 'custom'})',
                  ),
                ),
                if (_customFontBytes != null)
                  TextButton(
                    onPressed: () {
                      _customFontBytes = null;
                      _customFontName = null;
                      _refreshFonts();
                    },
                    child: const Text('Reset to default font'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children.expand((c) => [c, const SizedBox(height: 10)]).toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    int lines = 1,
    bool mono = false,
  }) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      style: TextStyle(fontFamily: mono ? 'monospace' : null),
      onChanged: (_) => _refresh(),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
      ),
    );
  }

  Widget _accentPicker() {
    return TextField(
      controller: _accentController,
      onChanged: (value) {
        _accentColor = _parseColor(value, _accentColor);
        _refresh();
      },
      decoration: InputDecoration(
        labelText: 'Accent color (hex)',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(width: 18, height: 18),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String input, Color fallback) {
    final cleaned = input.replaceAll('#', '').trim();
    if (cleaned.isEmpty) return fallback;
    try {
      final value = cleaned.length == 6
          ? int.parse('FF$cleaned', radix: 16)
          : int.parse(cleaned, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

  // ignore: deprecated_member_use
  int _colorToArgb(Color color) => color.value;

  pdf.PdfColor _pdfColor(Color color) =>
      pdf.PdfColor.fromInt(_colorToArgb(color));

  pdf.PdfColor _accentTint(double opacity) =>
      _pdfColor(_accentColor.withAlpha((opacity * 255).round()));

  Future<Uint8List> _generatePdf(pdf.PdfPageFormat format) async {
    try {
      final fonts = await _fonts;
      final doc = pw.Document(
        title: _titleController.text,
        author: _authorController.text,
        subject: _subtitleController.text,
      );

      final bullets = _bulletController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final paragraphs = _summaryController.text
          .split(RegExp(r'\n\n+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final tableRows = _tableController.text
          .split('\n')
          .map((row) => row.split(',').map((cell) => cell.trim()).toList())
          .where((row) => row.where((cell) => cell.isNotEmpty).isNotEmpty)
          .toList();

      final qrValue = _qrController.text.trim();
      final accent = _pdfColor(_accentColor);
      final margin = _marginMm * pdf.PdfPageFormat.mm;

      pw.Widget? logo;
      if (_logoBytes != null) {
        final image = pw.MemoryImage(_logoBytes!);
        logo = pw.Container(
          padding: const pw.EdgeInsets.all(4),
          height: 48,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: pw.EdgeInsets.all(margin),
          theme: pw.ThemeData.withFont(
            base: fonts.base,
            bold: fonts.bold,
            italic: fonts.base,
            boldItalic: fonts.bold,
          ),
          header: (context) => _header(accent, logo),
          footer: (_) => pw.SizedBox.shrink(),
          build: (context) => [
            pw.Stack(
              children: [
                if (_showGrid) _gridOverlay(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _hero(accent),
                    if (bullets.isNotEmpty) _bullets(accent, bullets),
                    if (paragraphs.isNotEmpty)
                      ...paragraphs.map((p) => _paragraph(p)),
                    if (tableRows.length > 1)
                      _table(accent, tableRows, fonts.mono),
                    if (_includeSignature) _signature(accent),
                    if (_includeQr && qrValue.isNotEmpty)
                      _qrSection(accent, qrValue),
                    if (_notesController.text.trim().isNotEmpty)
                      _notes(accent, _notesController.text.trim()),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      return doc.save();
    } catch (e, st) {
      debugPrint('PDF generation failed: $e\n$st');
      final fallback = pw.Document();
      fallback.addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Text('PDF failed to build: $e')),
        ),
      );
      return fallback.save();
    }
  }

  pw.Widget _header(pdf.PdfColor accent, pw.Widget? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _accentTint(0.35), width: 1.2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) logo,
          if (logo != null) pw.SizedBox(width: 8),
          pw.Spacer(),
          pw.Text(
            _authorController.text,
            style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _hero(pdf.PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _titleController.text,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _subtitleController.text,
            style: const pw.TextStyle(
              fontSize: 12,
              color: pdf.PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_accentTint(0.14), _accentTint(0.04)],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              _summaryController.text,
              style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 2),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
    );
  }

  pw.Widget _bullets(pdf.PdfColor accent, List<String> bullets) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('Highlights', accent),
          pw.SizedBox(height: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: bullets
                .map(
                  (b) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          margin: const pw.EdgeInsets.only(top: 4, right: 6),
                          decoration: pw.BoxDecoration(
                            color: accent,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            b,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _paragraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 2),
      ),
    );
  }

  pw.Widget _table(
    pdf.PdfColor accent,
    List<List<String>> rows,
    pw.Font monoFont,
  ) {
    final headers = rows.first;
    final data = rows.skip(1).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('Structured data', accent),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: pdf.PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: accent),
          oddRowDecoration: pw.BoxDecoration(color: _accentTint(0.04)),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: pw.TextStyle(fontSize: 10, font: monoFont),
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(
              color: _accentTint(0.35),
              width: 0.5,
            ),
            verticalInside: pw.BorderSide(color: _accentTint(0.25), width: 0.5),
            bottom: pw.BorderSide(color: _accentTint(0.5), width: 0.8),
            left: pw.BorderSide(color: _accentTint(0.5), width: 0.8),
            right: pw.BorderSide(color: _accentTint(0.5), width: 0.8),
            top: pw.BorderSide(color: _accentTint(0.5), width: 0.8),
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _signature(pdf.PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sign-off', style: pw.TextStyle(color: accent)),
                pw.Container(
                  height: 1,
                  margin: const pw.EdgeInsets.symmetric(vertical: 6),
                  color: _accentTint(0.7),
                ),
                pw.Text(
                  _signatureNameController.text,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Date', style: pw.TextStyle(color: accent)),
                pw.Container(
                  height: 1,
                  margin: const pw.EdgeInsets.symmetric(vertical: 6),
                  color: _accentTint(0.7),
                ),
                pw.Text(
                  _signatureDateController.text,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _qrSection(pdf.PdfColor accent, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _accentTint(0.4)),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: value,
              width: 70,
              height: 70,
              color: accent,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _notes(pdf.PdfColor accent, String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _accentTint(0.08),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Note', style: pw.TextStyle(color: accent)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }

  pw.Widget _gridOverlay() {
    return pw.Positioned.fill(
      child: pw.Opacity(
        opacity: 0.06,
        child: pw.LayoutBuilder(
          builder: (context, constraints) {
            final step = 40.0;
            final width = constraints?.maxWidth ?? 0;
            final height = constraints?.maxHeight ?? 0;
            final cols = width == 0 ? 0 : (width / step).ceil();
            final rows = height == 0 ? 0 : (height / step).ceil();
            return pw.Stack(
              children: [
                for (var i = 0; i < cols; i++)
                  pw.Positioned(
                    left: i * step,
                    top: 0,
                    bottom: 0,
                    child: pw.Container(
                      width: 0.5,
                      color: pdf.PdfColors.grey300,
                    ),
                  ),
                for (var j = 0; j < rows; j++)
                  pw.Positioned(
                    top: j * step,
                    left: 0,
                    right: 0,
                    child: pw.Container(
                      height: 0.5,
                      color: pdf.PdfColors.grey300,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  pw.Widget _sectionLabel(String text, pdf.PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent),
        ),
      ],
    );
  }
}

class _FontPack {
  const _FontPack({required this.base, required this.bold, required this.mono});

  final pw.Font base;
  final pw.Font bold;
  final pw.Font mono;
}
