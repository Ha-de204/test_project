const reportService = require('../../services/report.service');
const budgetService = require('../../services/budget.service');

const normalizeDateParams = (req) => {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(new Date().getFullYear(), 0, 1);
    const end = endDate ? new Date(endDate) : new Date(new Date().getFullYear(), 11, 31);

    return { startDate: start, endDate: end };
};

const getSummary = async (req, res) => {

    const user_id = req.user_id;
    const { startDate, endDate } = normalizeDateParams(req);

    try {

        const summary = await reportService.getSummaryByDateRange(
            user_id,
            startDate,
            endDate
        );

        res.status(200).json(summary);

    } catch (error) {

        console.error(error);

        res.status(500).json({
            message: 'Lỗi server'
        });
    }
};

const getCategoryBreakdown = async (req, res) => {
    const user_id = req.user_id;
    const { startDate, endDate } = normalizeDateParams(req);

    try {
        const breakdown = await reportService.getCategoryBreakdown(user_id, startDate, endDate);
        res.status(200).json(breakdown);
    } catch (error) {
        console.error('Lỗi lấy phân tích danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

const getMonthlyFlow = async (req, res) => {
    const user_id = req.user_id;
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