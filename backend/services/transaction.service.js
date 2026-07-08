const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

// 1. Tạo giao dịch mới
const createTransaction = async (user_id, category_id, amount, type, date, title, note) => {
    const newTransaction = new Transaction({
        user_id: new mongoose.Types.ObjectId(user_id),
        category_id: new mongoose.Types.ObjectId(category_id),
        amount,
        type,
        date,
        title,
        note: note || null
    });

    const result = await newTransaction.save();
    return await Transaction.findById(result._id)
       .populate('category_id', 'name icon_code_point');
};

// 2. Lấy tất cả giao dịch của người dùng (Kèm thông tin danh mục)
const getTransactionsByUserId = async (user_id) => {
    return await Transaction.find({
        user_id: new mongoose.Types.ObjectId(user_id)
    })
    .populate('category_id', 'name icon_code_point')
    .sort({ date: -1 });
};

// 3. Lấy chi tiết 1 giao dịch
const getTransactionById = async (transaction_id, user_id) => {
    return await Transaction.findOne({
        _id: new mongoose.Types.ObjectId(transaction_id),
        user_id: new mongoose.Types.ObjectId(user_id)
    }).populate('category_id', 'name icon_code_point');
};

// 4. Cập nhật giao dịch
const updateTransaction = async (transaction_id, user_id, category_id, amount, type, date, title, note) => {
    const result = await Transaction.findOneAndUpdate(
        {
            _id: new mongoose.Types.ObjectId(transaction_id),
            user_id: new mongoose.Types.ObjectId(user_id)
        },
        {
            category_id: new mongoose.Types.ObjectId(category_id),
            amount,
            type,
            date,
            title,
            note: note || null
        },
        {
            new: true
        }
    ).populate('category_id', 'name icon_code_point');

    return result;
};

// 5. Xóa giao dịch
const deleteTransaction = async (transaction_id, user_id) => {
    const result = await Transaction.deleteOne({
        _id: new mongoose.Types.ObjectId(transaction_id),
        user_id: new mongoose.Types.ObjectId(user_id)
    });

    return result.deletedCount > 0;
};

module.exports = {
    createTransaction,
    getTransactionsByUserId,
    getTransactionById,
    updateTransaction,
    deleteTransaction
};