const transactionService = require('../../services/transaction.service');

const createTransaction = async (req, res) => {
    const user_id = req.user_id;
    const { category_id, amount, type, date, title, note } = req.body;


    if (!category_id || !amount || !type || !date || !title) {
        return res.status(400).json({ message: 'Thiếu dữ liệu bắt buộc (categoryId, amount, type, date, title).' , received: req.body});
    }

    try {
        const transaction = await transactionService.createTransaction(
            user_id,
            category_id,
            amount,
            type,
            date,
            title,
            note
        );

        res.status(201).json({
            message: 'Tạo giao dịch thành công.',
            transaction
        });

    } catch (error) {
        console.error('Lỗi tạo giao dịch:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi tạo giao dịch.' });
    }
};

const getTransactions = async (req, res) => {
    const user_id = req.user_id;

    try {
        const transactions = await transactionService.getTransactionsByUserId(user_id);
        res.status(200).json(transactions);
    } catch (error) {
        console.error('Lỗi lấy giao dịch:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi lấy giao dịch.' });
    }
};

// Lấy chi tiết 1 giao dịch
const getTransactionById = async (req, res) => {
    const user_id = req.user_id;
    const transaction_id = req.params.id;

    if (!transaction_id || transaction_id.length !== 24) {
        return res.status(400).json({ message: 'ID giao dịch không hợp lệ.' });
    }

    try {
        const transaction = await transactionService.getTransactionById(transaction_id, user_id);

        if (!transaction) {
            return res.status(404).json({ message: 'Không tìm thấy giao dịch hoặc bạn không có quyền truy cập.' });
        }
        res.status(200).json(transaction);
    } catch (error) {
        console.error('Lỗi lấy chi tiết giao dịch:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// Update giao dịch
const updateTransaction = async (req, res) => {
    const user_id = req.user_id;
    const transaction_id = req.params.id;
    const { category_id, amount, type, date, title, note } = req.body;

    if (!transaction_id || transaction_id.length !== 24 || !category_id || !amount || !type || !date || !title) {
        return res.status(400).json({ message: 'Dữ liệu cập nhật hoặc ID giao dịch không hợp lệ.' });
    }

    try {
        const transaction = await transactionService.updateTransaction(
            transaction_id,
            user_id,
            category_id,
            amount,
            type,
            date,
            title,
            note
        );

        if (!transaction) {
            return res.status(404).json({ message: 'Không tìm thấy giao dịch để cập nhật hoặc không có thay đổi.' });
        }

        res.status(200).json({
            success: true,
            message: 'Cập nhật giao dịch thành công.',
            transaction: transaction
        });
    } catch (error) {
        console.error('Lỗi cập nhật giao dịch:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// Delete giao dịch
const deleteTransaction = async (req, res) => {
    const user_id = req.user_id;
    const transaction_id = req.params.id;

    if (!transaction_id || transaction_id.length !== 24) {
        return res.status(400).json({ message: 'ID giao dịch không hợp lệ.' });
    }

    try {
        const success = await transactionService.deleteTransaction(transaction_id, user_id);
        if (success) {
            return res.status(200).json({ message: `Giao dịch đã được xóa thành công.` });
        } else {
            return res.status(404).json({ message: 'Không tìm thấy giao dịch hoặc bạn không có quyền xóa.' });
        }
    } catch (error) {
        console.error('Lỗi khi xóa giao dịch:', error);
        return res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi xóa giao dịch.' });
    }
};

module.exports = {
    createTransaction,
    getTransactions,
    getTransactionById,
    updateTransaction,
    deleteTransaction
};