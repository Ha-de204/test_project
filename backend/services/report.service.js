const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const mongoose = require('mongoose');

// =======================
// 1. SUMMARY
// =======================
const getSummaryByDateRange = async (user_id, startDate, endDate) => {
    const result = await Transaction.aggregate([
        {
            $match: {
                user_id: new mongoose.Types.ObjectId(user_id),
                date: {
                    $gte: new Date(startDate),
                    $lte: new Date(endDate)
                }
            }
        },
        {
            $group: {
                _id: '$type',
                total: { $sum: '$amount' }
            }
        }
    ]);

    let totalExpense = 0;
    let totalIncome = 0;

    result.forEach(item => {
        if (item._id === 'expense') {
            totalExpense = item.total;
        }

        if (item._id === 'income') {
            totalIncome = item.total;
        }
    });

    return {
        TotalExpense: totalExpense,
        TotalIncome: totalIncome,
        NetBalance: totalIncome - totalExpense
    };
};

// =======================
// 2. MONTHLY FLOW
// =======================
const getMonthlyFlow = async (user_id, year) => {

    const startOfYear = new Date(`${year}-01-01`);
    const endOfYear = new Date(`${year}-12-31T23:59:59`);

    const result = await Transaction.aggregate([
        {
            $match: {
                user_id: new mongoose.Types.ObjectId(user_id),
                date: {
                    $gte: startOfYear,
                    $lte: endOfYear
                }
            }
        },
        {
            $group: {
                _id: {
                    month: { $month: '$date' },
                    type: '$type'
                },
                total: { $sum: '$amount' }
            }
        }
    ]);

    const budgets = await Budget.find({
        user_id: new mongoose.Types.ObjectId(user_id),
        category_id: new mongoose.Types.ObjectId("000000000000000000000000"),
        period: {
            $gte: `${year}-01`,
            $lte: `${year}-12`
        }
    }).lean();

    console.log(budgets);

    const finalData = [];

    const budgetMap = {};
    budgets.forEach(item => {
       budgetMap[item.period] = item.budget_amount;
    });

    for (let month = 1; month <= 12; month++) {

        const expenseData = result.find(
            r => r._id.month === month && r._id.type === 'expense'
        );

        const incomeData = result.find(
            r => r._id.month === month && r._id.type === 'income'
        );

        const expense = expenseData ? expenseData.total : 0;
        const income = incomeData ? incomeData.total : 0;

        const period = `${year}-${month.toString().padStart(2, '0')}`;

        finalData.push({
            month,
            expense,
            income,
            balance: income - expense,
            budget: budgetMap[period] ?? 0
        });
    }

    return finalData;
};

module.exports = {
    getSummaryByDateRange,
    getMonthlyFlow
};