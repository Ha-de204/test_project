import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/reminder_model.dart';
import '../services/apiReminder.dart';
import '../utils/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;
  const AddReminderScreen({super.key, this.reminder});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final ReminderService _reminderService = ReminderService();

  // controller cho input text
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  DateTime _selectedDate = DateTime.now();

  String? _selectedFrequency = 'Hàng ngày';
  final List<String> _frequencyOptions = ['Hàng ngày', 'Hàng tuần', 'Hàng tháng', 'Hàng năm'];

  //State cho Date va Time
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).add(const Duration(minutes: 2));
    if (widget.reminder != null) {
      _titleController = TextEditingController(text: widget.reminder!.title);
      _messageController = TextEditingController(text: widget.reminder!.message);
      _selectedDate = widget.reminder!.dueDate;
      _selectedFrequency = widget.reminder!.frequency;
    } else {
      _titleController = TextEditingController();
      _messageController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ham hien thi lich
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime.now().subtract(const Duration(days: 365*5)),
        lastDate: DateTime.now().add(const Duration(days: 365*5)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: kPrimaryPink,
              colorScheme: const ColorScheme.light(primary: kPrimaryPink),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
    );
    if(pickedDate != null){
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  // ham hien thi chon gio
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: kPrimaryPink,
              colorScheme: const ColorScheme.light(primary: kPrimaryPink),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
    );
    if(pickedTime != null){
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
  String _cleanId(dynamic rawId) {
    if (rawId == null) return "";
    String idStr = rawId.toString();
    if (idStr.contains("ObjectId(")) {
      final match = RegExp(r"ObjectId\('([a-fA-F0-9]+)'\)").firstMatch(idStr);
      return match?.group(1) ?? idStr;
    }
    return idStr.replaceAll(RegExp(r"[^a-fA-F0-9]"), "").trim();
  }

  // luu reminder
  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if(title.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên mục nhắc nhở.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      Map<String, dynamic> result;
      if (widget.reminder != null) {
        result = await _reminderService.updateReminder(
          widget.reminder!.id,
          title: title,
          message: message,
          dueDate: _selectedDateTime.toIso8601String(),
          frequency: _selectedFrequency!,
          isEnabled: widget.reminder!.isEnabled,
        );
      } else {
        result = await _reminderService.createReminder(
          title: title,
          message: message,
          dueDate: _selectedDateTime.toIso8601String(),
          frequency: _selectedFrequency!,
        );
      }

      if (result['success'] == true) {
        // lấy id lời nhắc
        String rawId = widget.reminder?.id ?? result['reminder_id'] ?? "0";
        int notificationId = rawId.hashCode;

        // đặt lịch thông báo
        await NotificationService().scheduleNotification(
          id: notificationId,
          title: _titleController.text,
          body: _messageController.text.isEmpty ? "Đã đến giờ nhắc nhở!" : _messageController.text,
          scheduledDate: _selectedDateTime,
          frequency: _selectedFrequency!,
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Lỗi lưu dữ liệu')),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi lưu lời nhắc: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildCustomInput({
    required String title,
    String? hintText,
    bool isDropdown = false,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: kPrimaryPink, margin: const EdgeInsets.only(right: 8)),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: isDropdown ? 0 : 10,
              bottom: isDropdown ? 0 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: isDropdown
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFrequency,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFrequency = newValue;
                        });
                      },
                      items: _frequencyOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            )
                : TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none, // Xóa border
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeInput({required String title, required String value, required VoidCallback onTap, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: kPrimaryPink, margin: const EdgeInsets.only(right: 8)),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // format theo tieng Viet
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDateTime);
    final timeStr = DateFormat('HH:mm').format(_selectedDateTime);

    final bool isEditing = widget.reminder != null;
    final String appBarTitle = isEditing ? 'Sửa lời nhắc' : 'Thêm lời nhắc';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            appBarTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: kPrimaryPink, fontSize: 16)),
        ),
        actions: [
          _isSaving
          ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryPink))))
          : IconButton(
            icon: const Icon(Icons.check, color: kPrimaryPink),
            onPressed: _saveReminder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCustomInput(
              title: 'Tên mục nhắc nhở',
              hintText: 'Nhập tên lời nhắc',
              controller: _titleController,
            ),
            _buildCustomInput(
              title: 'Lời nhắc nhở',
              hintText: 'Lời nhắc nhở (tùy chọn)',
              controller: _messageController,
            ),

            _buildCustomInput(
              title: 'Tần suất nhắc nhở',
              isDropdown: true,
            ),

            _buildDateTimeInput(
              title: 'Ngày bắt đầu nhắc nhở',
              value: dateStr,
              onTap: _selectDate,
              icon: Icons.calendar_today_outlined,
            ),

            _buildDateTimeInput(
              title: 'Thời gian',
              value: timeStr,
              onTap: _selectTime,
              icon: Icons.access_time_outlined,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}