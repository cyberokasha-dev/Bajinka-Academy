import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'learner_store.dart';

Future<bool> downloadText(String name, String text) async => await FilePicker.platform.saveFile(fileName: name, bytes: Uint8List.fromList(utf8.encode(text)), dialogTitle: 'Save $name') != null;
Future<String?> pickText(List<String> extensions) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions, withData: true);
  if (result == null) return null;
  final bytes = result.files.single.bytes;
  if (bytes == null || bytes.length > 5000000) throw const FormatException('Choose a text file below 5 MB.');
  return utf8.decode(bytes);
}
Future<Uint8List> studyRecordPdf(LearnerStore store, {bool opening = false}) async {
  final doc = pw.Document();
  final teal = PdfColor.fromHex('#0eaaa7');
  final navy = PdfColor.fromHex('#1e2e52');
  doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4.landscape, build: (_) => pw.Container(padding: const pw.EdgeInsets.all(26), decoration: pw.BoxDecoration(border: pw.Border.all(color: teal, width: 2)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
    pw.Text('BAJINKA ACADEMY', style: pw.TextStyle(fontSize: 20, color: navy, letterSpacing: 3)), pw.SizedBox(height: 25),
    pw.Text(opening ? 'INDEPENDENT STUDY RECORD' : 'LEARNING PROGRESS RECORD', style: pw.TextStyle(fontSize: 27, color: navy)), pw.SizedBox(height: 24),
    pw.Text(store.name.trim().isEmpty ? 'Learner' : store.name.trim(), style: pw.TextStyle(fontSize: 28, color: teal)), pw.SizedBox(height: 16),
    pw.Text('Python Foundations - opening chapter starter activities', style: const pw.TextStyle(fontSize: 17)), pw.SizedBox(height: 20),
    pw.Text('${store.completedCount} of ${store.requiredCount} required starter activities passed local checks.'), pw.SizedBox(height: 8), pw.Text('Opening assessment best score: ${store.assessmentBest.toStringAsFixed(0)}%'), pw.SizedBox(height: 8),
    pw.Text('Project design and explanation: ${store.reviews['opening-project'] == true ? 'self-reviewed' : 'review pending'}'), pw.SizedBox(height: 22),
    pw.Text('Study started: ${store.startedAt.split('T').first}    Recorded: ${DateTime.now().toIso8601String().split('T').first}', style: const pw.TextStyle(fontSize: 12)), pw.Spacer(),
    pw.Text('Independent study evidence from this device. Output is checked locally; explanations and design are self-reviewed. This is not a verified examination, full-course qualification, or university-endorsed certificate.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
  ]))));
  return doc.save();
}
Future<void> previewRecord(LearnerStore store, {bool opening = false}) async { await Printing.layoutPdf(onLayout: (_) => studyRecordPdf(store, opening: opening), name: 'Bajinka-study-record.pdf'); }
Future<bool> downloadRecord(LearnerStore store, {bool opening = false}) async => await FilePicker.platform.saveFile(fileName: 'Bajinka-study-record.pdf', bytes: await studyRecordPdf(store, opening: opening), dialogTitle: 'Save study record') != null;
