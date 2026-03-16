import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/data_aggregator.dart';
import '../constants.dart';
import 'dart:math';

const Color _chartGreenPrimary = Color(0xFF66BB6A);
const Color _chartGreenSecondary = Color(0xFFC8E6C9);
const Color _toggleUnselectedColor = Color(0xFFF7E6EB);

class ChartsScreen extends StatefulWidget {

  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  int _selectedFilterIndex = 1;
  DateTime _currentViewingDate = DateTime.now();
  late List<DateTime> _pastPeriods;
  late ScrollController _scrollController;
  final GlobalKey _periodSelectorKey = GlobalKey();
  bool _isLoading = true;
  String selectedType = 'expense';

  final List<Color> _categoryColors = [
    _chartGreenPrimary,
    const Color(0xFF00BCD4),
    const Color(0xFF9272CA),
    const Color(0xFFFF9800),
    const Color(0xFF4CAF50),
    const Color(0xFFED578A),
    const Color(0xFF795548),
    const Color(0xFF2196F3),
    const Color(0xFFC8E6C9),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    _scrollController = ScrollController();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await DataAggregator.refreshData();
    _updatePeriods(initialScroll: true);
    setState(() => _isLoading = false);
  }

  void _updatePeriods({bool initialScroll = false}) {
    final now = DateTime.now();
    _pastPeriods = DataAggregator.getPastPeriods(_selectedFilterIndex, now);

    if(_pastPeriods.isNotEmpty) {
      if(!_pastPeriods.any((date) => _isSamePeriod(date, _currentViewingDate, _selectedFilterIndex))){
        _currentViewingDate = _pastPeriods.last;
      }
    }

    if(initialScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentIndex();
      });
    } else {
      setState(() {});
    }
  }

  bool _isSamePeriod(DateTime d1, DateTime d2, int filterIndex) {
    if(filterIndex == 0){
      return DataAggregator.getStartOfWeek(d1) == DataAggregator.getStartOfWeek(d2);
    } else if(filterIndex == 1){
      return d1.year == d2.year && d1.month == d2.month;
    } else {
      return d1.year == d2.year;
    }
  }

  // Lấy dữ liệu chi tiêu cho chu kỳ đang xem
  List<CategoryExpense> get _expenseDataForPeriod {
    return DataAggregator.aggregateCategoryExpenses(
      _currentViewingDate,
      _selectedFilterIndex,
      selectedType
    );
  }

  double get _totalExpenseForPeriod {
    return DataAggregator.getTotalAmount(
      _currentViewingDate,
      _selectedFilterIndex,
      selectedType,
    );
  }

  Color _getColorForCategoryIndex(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  // Format ngày/chu kỳ hiển thị trên thanh cuộn
  String _formatPeriodTitle(DateTime date) {
    final now = DateTime.now();
    if (_selectedFilterIndex == 0) {
      final start = DataAggregator.getStartOfWeek(date);
      final currentWeekStart = DataAggregator.getStartOfWeek(now);

      if (start.isAtSameMomentAs(currentWeekStart)) {
        return 'Tuần này';
      }
      final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      if (start.isAtSameMomentAs(lastWeekStart)) {
        return 'Tuần trước';
      }

      // format số tuần
      final yearStart = DateTime(date.year, 1, 1);
      final firstWeekStart = DataAggregator.getStartOfWeek(yearStart);
      final daysSinceYearStart = start
          .difference(firstWeekStart)
          .inDays;
      final weekNumber = (daysSinceYearStart / 7).floor() + 1;
      return 'Tuần $weekNumber';
    } else if (_selectedFilterIndex == 1) {
      final currentMonth = DateTime(now.year, now.month, 1);
      final periodMonth = DateTime(date.year, date.month, 1);
      if (periodMonth.isAtSameMomentAs(currentMonth)) {
        return 'Tháng này';
      }
      final lastMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
      if (periodMonth.isAtSameMomentAs(lastMonth)) {
        return 'Tháng trước';
      }
      return 'Thg ${DateFormat('M yyyy').format(date)}';
    } else {
      final currentYear = now.year;
      if (date.year == currentYear) {
        return 'Năm nay';
      }
      if (date.year == currentYear - 1) {
        return 'Năm ngoái';
      }
      return DateFormat('yyyy').format(date);
    }
  }

  String _formatWeekSubtitle(DateTime date) {
    final start = DataAggregator.getStartOfWeek(date);
    final end = DataAggregator.getEndOfWeek(date);
    final startDay = DateFormat('dd').format(start);
    final endDay = DateFormat('dd').format(end);
    String endMonthYear;
    if (start.year != end.year) {
      endMonthYear = 'thg ${end.month} ${end.year}';
    } else {
      endMonthYear = 'thg ${end.month}';
    }
    if (start.month == end.month && start.year == end.year) {
      return '$startDay – $endDay $endMonthYear';
    }
    String startMonthYear;
    if (start.year != end.year) {
      startMonthYear = 'thg ${start.month} ${start.year}';
      endMonthYear = 'thg ${end.month} ${end.year}';
    } else {
      startMonthYear = 'thg ${start.month}';
    }
    return '$startDay $startMonthYear – $endDay $endMonthYear';
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  int _getCurrentPeriodIndex() {
    return _pastPeriods.indexWhere((date) => _isSamePeriod(date, _currentViewingDate, _selectedFilterIndex));
  }

  void _scrollToCurrentIndex() {
    final currentIndex = _getCurrentPeriodIndex();
    if (_scrollController.hasClients && currentIndex != -1) {

      const double itemWidth = 100.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = currentIndex * itemWidth - (screenWidth / 2) + (itemWidth / 2);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /* Dropdown tiêu đề */
  Widget _buildTypeDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedType,
        dropdownColor: Colors.white,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          DropdownMenuItem(
            value: 'expense',
            child: Text('Chi tiêu'),
          ),
          DropdownMenuItem(
            value: 'income',
            child: Text('Thu nhập'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedType = value!;
          });
        },
      ),
    );
  }


  Widget _buildFilterToggle() {
    final List<String> filters = ['Tuần', 'Tháng', 'Năm'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _toggleUnselectedColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(filters.length, (index) {
          final isSelected = index == _selectedFilterIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                  _updatePeriods(initialScroll: true);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryPink.withOpacity(0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : kPrimaryPink.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    if (_pastPeriods.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentIndex();
    });

    final currentIndex = _getCurrentPeriodIndex();
    return SizedBox(
      key: _periodSelectorKey,
      height: 60,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _pastPeriods.length,
        itemBuilder: (context, index) {
          final periodDate = _pastPeriods[index];
          final isSelected = index == currentIndex;
          final titleText = _formatPeriodTitle(periodDate);

          String? subTitleText;
          if (_selectedFilterIndex == 0) {
            subTitleText = _formatWeekSubtitle(periodDate);
          }
          return _buildPeriodItem(
            titleText,
            isSelected,
                () { setState(() => _currentViewingDate = periodDate); },
            subTitle: subTitleText,
          );
        },
      ),
    );
  }

  Widget _buildPeriodItem(String title, bool isSelected, VoidCallback onTap, {String? subTitle}) {
    return Container(
      width: 100.0,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? kPrimaryPink : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (subTitle != null)
              Text(
                subTitle,
                style: TextStyle(
                  color: isSelected ? kPrimaryPink.withOpacity(0.8) : Colors.grey.shade600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  color: kPrimaryPink,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularChartSection(List<CategoryExpense> data, double total) {
    if (data.isEmpty || total == 0.0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _chartGreenSecondary,
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      Text('VNĐ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedType == 'expense'
                            ? 'Không có chi tiêu trong chu kỳ này.'
                            : 'Không có thu nhập trong chu kỳ này.',
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    final displayData = data.take(4).toList();

    double currentCumulatedValue = 0.0;

    List<Widget> indicatorStack = [];

    indicatorStack.add(
      SizedBox(
        width: 150,
        height: 150,
        child: CircularProgressIndicator(
          value: 1.0,
          strokeWidth: 15.0,
          backgroundColor: _chartGreenSecondary,
          valueColor: const AlwaysStoppedAnimation<Color>(_chartGreenSecondary),
        ),
      ),
    );

    for (int i = 0; i < displayData.length; i++) {
      final item = displayData[i];
      final color = _getColorForCategoryIndex(i);
      final startValue = currentCumulatedValue;
      final sweepAngle = item.percentage;

      indicatorStack.add(
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _CircularSegmentPainter(
              startAngle: startValue * 2 * pi,
              sweepAngle: sweepAngle * 2 * pi,
              color: color,
              strokeWidth: 15.0,
            ),
          ),
        ),
      );

      currentCumulatedValue += sweepAngle;
    }

    indicatorStack.add(
      Container(
        width: 120,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_chartGreenSecondary.withOpacity(0.5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatAmount(total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'VNĐ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: indicatorStack,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayData.length, (index) {
                final item = displayData[index];
                final color = _getColorForCategoryIndex(index);
                final percentage = item.percentage;
                return _buildLegendItem(item.categoryName, percentage, color);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, double percentage, Color color) {
    String percentText = (percentage * 100).toStringAsFixed(1);
    if (percentText.endsWith('.0')) {
      percentText = (percentage * 100).toStringAsFixed(0);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$percentText%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<CategoryExpense> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.map((item) {
        final index = data.indexOf(item);
        final color = _getColorForCategoryIndex(index);

        String percentText = (item.percentage * 100).toStringAsFixed(1);
        if (percentText.endsWith('.0')) {
          percentText = (item.percentage * 100).toStringAsFixed(0);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 35,
                    alignment: Alignment.center,
                    child: Icon(item.icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.categoryName,
                              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentText%',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          _formatAmount(item.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 45),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: item.percentage.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 25, thickness: 1, color: Color(0xFFEFEFEF)),
            ],
          ),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryPink)),
      );
    }

    final expenseData = _expenseDataForPeriod;
    final totalExpense = _totalExpenseForPeriod;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: _buildTypeDropdown(),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            _buildFilterToggle(),

            const SizedBox(height: 20),
            _buildPeriodSelector(),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
              child: _buildCircularChartSection(expenseData, totalExpense),
            ),
            const SizedBox(height: 40),
            _buildExpenseList(expenseData),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _CircularSegmentPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final double strokeWidth;

  _CircularSegmentPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.shortestSide / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle - pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularSegmentPainter oldDelegate) {
    return oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
