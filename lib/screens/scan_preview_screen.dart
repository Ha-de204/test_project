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

    try {
      final result = await OcrService().scanReceipt(File(widget.imagePath));

      final categories = (await _categoryService.getCategories())
          .map((c) => {
        'id': c.id,
        'label': c.name,
        'icon': c.iconCodePoint,
        'type': c.type,
      }).toList();

      setState(() => _loading = false);

      if (!mounted) return;

      final transaction = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: AddTransactionContent(
                initialData: result,
                categories: categories,
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, transaction);

    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi quét hóa đơn: $e")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Xem hóa đơn")),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(widget.imagePath)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _processOCR,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Scan hóa đơn", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
