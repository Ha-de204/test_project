const Budget = require('../models/Budget');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

// 1. Logic Upsert (Cập nhật nếu có, chưa có thì thêm mới)
const upsertBudget = async (user_id, category_id, amount, period) => {
    const result = await Budget.findOneAndUpdate(
        {
           user_id: new mongoose.Types.ObjectId(user_id),
           category_id: new mongoose.Types.ObjectId(category_id),
           period
        },
        { budget_amount: amount },
        { upsert: true, new: true }
    );
    return result._id;
};

// 2. Lấy ngân sách và số tiền đã chi tiêu theo tháng
const getBudgetsAmountPeriod = async (user_id, period) => {
    const [year, month] = period.split('-').map(Number);
    const startDate = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0));
    const endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

    const budgets = await Budget.aggregate([
        {
            $match: {
                user_id: new mongoose.Types.ObjectId(user_id),
                period: period
            }
        },
        {
            $lookup: {
                from: 'Category',
                localField: 'category_id',
                foreignField: '_id',
                as: 'category_info'
            }
        },
        { $unwind: { path: '$category_info', preserveNullAndEmptyArrays: true } },
        {
            $lookup: {
                from: 'Transaction',
                let: { catId: '$category_id', uId: '$user_id' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $and: [
                                    { $eq: ['$user_id', '$$uId'] },
                                    { $eq: ['$type', 'expense'] },
                                    { $gte: ['$date', startDate] },
                                    { $lte: ['$date', endDate] },
                                    {
                                        $or: [
                                           { $eq: ['$$catId', new mongoose.Types.ObjectId("000000000000000000000000")] },
                                           { $eq: ['$category_id', '$$catId'] }
                                        ]
                                    }
                                ]
                            }
                        }
                    }
                ],
                as: 'spent_transactions'
            }
        },
        {
            $project: {
                budget_id: '$_id',
                category_id: '$category_id',
                BudgetAmount: '$budget_amount',
                period: 1,
                category_name: { $ifNull: ['$category_info.name', 'Ngân sách tổng'] },
                icon_code_point: { $ifNull: ['$category_info.icon_code_point', 0] },
                TotalSpent: { $sum: '$spent_transactions.amount' }
            }
        }
    ]);

    return budgets;
};

// 3. Lấy tổng ngân sách theo khoảng thời gian
const getBudgetAmountByDateRange = async (user_id, startDate, endDate) => {
    const period = `${startDate.getFullYear()}-${(startDate.getMonth() + 1).toString().padStart(2, '0')}`;

    const result = await Budget.aggregate([
        { $match: {
            user_id: new mongoose.Types.ObjectId(user_id),
            period: period,
            $or: [{ category_id: null }, { category_id: { $exists: false } }]
        }},
        { $group: { _id: null, total: { $sum: '$budget_amount' } } }
    ]);

    return result.length > 0 ? result[0].total : 0;
};

// 4. Xóa ngân sách
const deleteBudget = async (budget_id, user_id) => {
    const result = await Budget.deleteOne({
        _id: new mongoose.Types.ObjectId(budget_id),
        user_id: new mongoose.Types.ObjectId(user_id)
    });
    return result.deletedCount > 0;
};

module.exports = {
    upsertBudget,
    getBudgetsAmountPeriod,
    getBudgetAmountByDateRange,
    deleteBudget
};