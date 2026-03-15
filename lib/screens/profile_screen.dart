import 'package:flutter/material.dart';
import 'reminder_list_screen.dart';
import 'term_of_use_screen.dart';
import 'privacy_policy_screen.dart';
import '../constants.dart';
import 'package:flutter/services.dart';
import 'auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _APP_LINK = 'https://applink.mockapp/SoCaiThuChi';

class ProfileScreen extends StatefulWidget {
  final String? userName;
  const ProfileScreen({super.key, this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _userName = 'Khách';
  String _statusMessage = 'Đăng nhập để lưu dữ liệu';

  @override
  void initState() {
    super.initState();
    if (widget.userName != null) {
      setState(() {
        _isLoggedIn = true;
        _userName = widget.userName!;
        _statusMessage = 'Đang hoạt động';
      });
    } else {
      _loadUserData();
    }
  }

  // load data user
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final String? userName = prefs.getString('userName');
    final String? token = prefs.getString('token');

    if (token != null && userName != null) {
      setState(() {
        _isLoggedIn = true;
        _userName = userName;
        _statusMessage = 'Đang hoạt động';
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _userName = 'Khách';
        _statusMessage = 'Đăng nhập để trải nghiệm thú vị hơn!';
      });
    }
  }

  // đăng nhập / đăng xuất
  Future<void> _handleLoginLogout() async {
    if(_isLoggedIn) {
      bool? confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
          ],
        ),
      );
      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        _loadUserData();
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      ).then((_) => _loadUserData());
    }
  }

  // chia sẻ ứng dụng
  void _shareApp(){
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Chia sẻ ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sao chép đường dẫn sau để chia sẻ ứng dụng: ', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      _APP_LINK,
                      style: TextStyle(color: kPrimaryPink, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(const ClipboardData(text: _APP_LINK));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép liên kết!', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kLightPinkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kPrimaryPink),
                      ),
                      child: const Icon(Icons.copy, size: 20, color: kPrimaryPink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: kPrimaryPink)),
            ),
          ],
        ),
      );
  }
  // xóa tất cả dl
  void _confirmDataDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Xóa tất cả dữ liệu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: const Text(
          'Thao tác này sẽ xóa toàn bộ dữ liệu giao dịch và ngân sách của bạn. Bạn có muốn xóa không?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('DATA DELETED!');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // link đến giao diện lời nhắc nhở
  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderListScreen()),
    );
  }

  // link đến gd điều khoản sd
  void _navigateToTermsOrPolicy(String type) {
    if(type == 'terms'){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
      );
    } else if(type == 'policy'){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
      );
    }
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      title: GestureDetector(
        onTap: _handleLoginLogout,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kLightPinkBackground,
                border: Border.all(color: kPrimaryPink.withOpacity(0.5), width: 1.0),
              ),
              child: Icon(
                _isLoggedIn ? Icons.person : Icons.login,
                size: 40,
                color: kPrimaryPink,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLoggedIn ? _userName : 'Đăng nhập',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: _isLoggedIn ? Colors.green : Colors.grey,
                    fontWeight: _isLoggedIn ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildSettingsList() {
    final List<Map<String, dynamic>> items = [
      {'title': 'Chia sẻ', 'icon': Icons.share, 'action': _shareApp},
      {'title': 'Lời nhắc nhở', 'icon': Icons.timer, 'action': _navigateToReminders},
      {'title': 'Xóa tất cả dữ liệu', 'icon': Icons.delete_forever, 'action': _confirmDataDeletion},
      {'title': 'Điều khoản sử dụng', 'icon': Icons.description, 'action': () => _navigateToTermsOrPolicy('terms')},
      {'title': 'Chính sách bảo mật', 'icon': Icons.security, 'action': () => _navigateToTermsOrPolicy('policy')},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: kPrimaryPink.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final listItem = _buildListItem(
            title: item['title'] as String,
            icon: item['icon'] as IconData,
            onTap: item['action'] as VoidCallback,
          );

          if (index < items.length - 1) {
            return Column(
              children: [
                listItem,
                const Divider(
                  indent: 60,
                  endIndent: 16,
                  height: 1,
                  color: Color(0xFFEFEFEF),
                ),
              ],
            );
          }
          return listItem;
        }),
      ),
    );
  }

  Widget _buildListItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(
                icon,
                color: kPrimaryPink.withOpacity(0.8),
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildSettingsList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}