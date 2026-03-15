import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/add_reminder_screen.dart';
import '../constants.dart';
import '../models/reminder_model.dart';
import '../services/apiReminder.dart';
import '../utils/notification_service.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  final ReminderService _reminderService = ReminderService();
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
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

  // Lấy dữ liệu từ API
  Future<void> _fetchReminders() async {
    setState(() {
      _isLoading = true;
      _reminders = [];
    });

    try {
      final List<dynamic> data = await _reminderService.getReminders();
      if (mounted) {
        setState(() {
          _reminders = data.map((json) => ReminderModel.fromJson(json)).toList();
          _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Xóa lời nhắc
  void _deleteReminder(String id) async {
    final cleanId = _cleanId(id);
    debugPrint("Đang xóa ID: $cleanId");

    final result = await _reminderService.deleteReminder(cleanId);
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lời nhắc')),
        );
      }
      await NotificationService().cancelNotification(id.hashCode);
      _fetchReminders();
    } else {
      _fetchReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi khi xóa')),
        );
      }
    }
  }

  // Bật/Tắt lời nhắc nhanh
  void _toggleReminder(ReminderModel reminder) async {
    final cleanId = _cleanId(reminder.id);
    final newStatus = !reminder.isEnabled;

    setState(() {
      reminder.isEnabled = newStatus;
    });

    final result = await _reminderService.updateReminder(
      cleanId,
      title: reminder.title,
      dueDate: reminder.dueDate.toIso8601String(),
      frequency: reminder.frequency,
      message: reminder.message,
      isEnabled: newStatus,
    );

    if (!result['success']) {
      setState(() {
        reminder.isEnabled = !newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái')),
        );
      }
    }
  }
  void _editReminder(ReminderModel reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(reminder: reminder),
      ),
    );

    if (result == true) {
      _fetchReminders();
    }
  }

  void _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );

    if (result == true) {
      _fetchReminders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm lời nhắc thành công!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    final DateTime dateTime = reminder.dueDate;
    final bool isEnabled = reminder.isEnabled;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                'Xác nhận xóa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text('Bạn có chắc chắn muốn xóa lời nhắc này không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => _deleteReminder(reminder.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200)
        ),
        child: ListTile(
          onTap: () => _editReminder(reminder),
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            reminder.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEnabled ? kPrimaryPink : Colors.grey,
              decoration: isEnabled ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: isEnabled ? Colors.black54 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(dateTime),
                    style: TextStyle(color: isEnabled ? Colors.black87 : Colors.grey),
                  ),
                ],
              ),
              if (reminder.message != null && reminder.message!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(reminder.message!, style: const TextStyle(color: Colors.grey)),
                ),
            ],
          ),
          trailing: Switch(
            value: isEnabled,
            activeColor: kPrimaryPink,
            onChanged: (value) => _toggleReminder(reminder),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
            'Lời nhắc nhở',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryPink))
          : _reminders.isEmpty
          ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có lời nhắc nào.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const Text(
                  'Hãy thêm một lời nhắc mới!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(_reminders[index]);
              },
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        backgroundColor: kPrimaryPink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm lời nhắc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}