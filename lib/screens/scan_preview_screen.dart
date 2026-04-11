import 'package:flutter/material.dart';
import '../widgets/add_transaction_content.dart';
import 'dart:io';
import '../services/ocr_service.dart';
import '../services/apiCategory.dart';

class ScanPreviewScreen extends StatefulWidget {
  final String imagePath;

  const ScanPreviewScreen(this.imagePath, {super.key});

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  bool _loading = false;
  final CategoryService _categoryService = CategoryService();

  Future<void> _processOCR() async {
    setState(() => _loading = true);

    final result = await OcrService().scanReceipt(File(widget.imagePath));

    final categories = (await _categoryService.getCategories())
        .map((c) => {
          'id': c.id,
          'label': c.name,
          'icon': c.iconCodePoint,
          'type': c.type,
        })
        .toList();

    setState(() => _loading = false);
    
      if (!mounted) return;

      final transactionSaved = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:(_) => Scaffold(
            body: SafeArea(
              child: AddTransactionContent(
                initialData: result,
                categories: categories,
              ),
            ),
          ), 
        ),
      );
      if (transactionSaved == true && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Xem hóa đơn")),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(widget.imagePath)),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _loading ? null : _processOCR,
              child: _loading
                ? const CircularProgressIndicator()
                : const Text("Scan hóa đơn")
            ),
          )
        ],
      ),
    );
  }
}