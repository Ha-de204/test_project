const reportService = require('../../services/report.service');
const budgetService = require('../../services/budget.service');

const normalizeDateParams = (req) => {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), 0, 1);
    const end = endDate ? new Date(endDate) : new Date(new Date().getFullYear(), 11, 31);

    return { startDate: start, endDate: end };
};

const getSummary = async (req, res) => {
    //const user_id = req.user_id;
    const user_id = "658123456789012345678901";
    const { startDate, endDate } = normalizeDateParams(req);

    const getPeriodString = (dateObj) =>
        `${dateObj.getFullYear()}-${(dateObj.getMonth() + 1).toString().padStart(2, '0')}`;

    const period = getPeriodString(startDate);

    try {
        const budgetAmount = await budgetService.getBudgetsAmountPeriod(user_id, period);
        const transactionSummary = await reportService.getSummaryByDateRange(user_id, startDate, endDate);
        const totalExpense = transactionSummary.TotalExpense || 0;
        const netBalance = (budgetAmount || 0) - totalExpense;

        res.status(200).json({
           TotalExpense: totalExpense,
           BudgetAmount: budgetAmount || 0,
           NetBalance: netBalance
        });
    } catch (error) {
        console.error('Lỗi lấy báo cáo tổng quan:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

const getCategoryBreakdown = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const { startDate, endDate } = normalizeDateParams(req);

    try {
        const breakdown = await reportService.getCategoryBreakdown(user_id, startDate, endDate);
        // MongoDB Service trả về mảng kết quả từ Aggregate, gửi trực tiếp về client
        res.status(200).json(breakdown);
    } catch (error) {
        console.error('Lỗi lấy phân tích danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

const getMonthlyFlow = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const year = parseInt(req.query.year) || new Date().getFullYear();

    try {
        const monthlyData = await reportService.getMonthlyFlow(user_id, year);
        res.status(200).json(monthlyData);
    } catch (error) {
        console.error('Lỗi lấy dòng tiền theo tháng:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

module.exports = { getSummary, getCategoryBreakdown, getMonthlyFlow };